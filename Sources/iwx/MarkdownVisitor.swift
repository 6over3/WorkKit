import Foundation
import ModelIO
import RegexBuilder
import WorkKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public final class MarkdownVisitor<O: OCRProvider>: IWorkDocumentVisitor, @unchecked Sendable {

  public struct Configuration {
    public var outputDirectory: String?
    public var includeSlideSheetTitles: Bool

    public init(
      outputDirectory: String? = nil,
      includeSlideSheetTitles: Bool = true
    ) {
      self.outputDirectory = outputDirectory
      self.includeSlideSheetTitles = includeSlideSheetTitles
    }
  }

  private var buffer: String = ""
  private var document: IWorkDocument
  private var ocrProvider: O?
  private let configuration: Configuration

  private var inList = false
  private var paragraphBuffer: String = ""

  private var pendingParagraphStyle: ParagraphStyle?
  private var pendingCharacterStyle: CharacterStyle?
  private var isFirstTextInMergedGroup = true

  private var lastHeaderLevel = 0
  private var lastHeaderFontSize: Double?
  private var hasContentSinceLastHeader = false
  private var consecutiveEmptyParagraphs = 0

  private var footnotes: [(number: Int, content: [InlineElement])] = []
  private var currentTable: TableBuilder?

  public var markdown: String {
    flushPendingParagraph()

    var result = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

    if !footnotes.isEmpty {
      result += "\n\n---\n\n"
      for footnote in footnotes.sorted(by: { $0.number < $1.number }) {
        result += "[^\(footnote.number)]: "
        result += renderFootnoteContent(footnote.content)
        result += "\n"
      }
    }

    return result + "\n"
  }

  public init(
    using document: IWorkDocument,
    with ocrProvider: O? = nil
  ) {
    self.document = document
    self.ocrProvider = ocrProvider
    self.configuration = Configuration()
  }

  public init(
    using document: IWorkDocument,
    configuration: Configuration = Configuration(),
    with ocrProvider: O? = nil
  ) {
    self.document = document
    self.ocrProvider = ocrProvider
    self.configuration = configuration
  }

  public func accept() async throws {
    if let ocrProvider {
      try await document.accept(visitor: self, ocrProvider: ocrProvider)
    } else {
      try await document.accept(visitor: self)
    }
  }

  public func willVisitDocument(
    type: IWorkDocument.DocumentType,
    layout: DocumentLayout?,
    pageSettings: PageSettings?
  ) async {
    buffer = ""
    footnotes.removeAll()
    pendingParagraphStyle = nil
    pendingCharacterStyle = nil
    paragraphBuffer = ""
    isFirstTextInMergedGroup = true
    consecutiveEmptyParagraphs = 0
    lastHeaderLevel = 0
    lastHeaderFontSize = nil
    hasContentSinceLastHeader = false
  }

  public func willVisitSheet(name: String, layout: SheetLayout?) async {
    flushPendingParagraph()

    if configuration.includeSlideSheetTitles {
      ensureBlankLine()
      buffer += "# \(cleanText(name))\n\n"
    }

    resetContext()
  }

  public func willVisitSlide(index: Int, bounds: CGRect?) async {
    flushPendingParagraph()

    if configuration.includeSlideSheetTitles {
      ensureBlankLine()
      buffer += "# Slide \(index + 1)\n\n"
    }

    resetContext()
  }

  public func didVisitSlide(index: Int) async {
    flushPendingParagraph()
    ensureBlankLine()
    resetContext()
  }

  public func willVisitList(style: ListStyle) async {
    flushPendingParagraph()
    ensureBlankLine()
    inList = true
    resetContext()
  }

  public func didVisitList() async {
    inList = false
    ensureBlankLine()
    resetContext()
  }

  public func willVisitListItem(
    number: Int?,
    level: Int,
    style: ParagraphStyle,
    spatialInfo: SpatialInfo?
  ) async {
    let indent = String(repeating: "  ", count: level)

    let marker: String
    switch style.listStyle {
    case .none:
      marker = ""
    case .bullet:
      marker = "-"
    case .numbered:
      marker = "\(number ?? 1)."
    }

    buffer += "\(indent)\(marker) "
    paragraphBuffer = ""
    isFirstTextInMergedGroup = true
  }

  public func didVisitListItem() async {
    let content = paragraphBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
    if !content.isEmpty {
      buffer += content
    }
    buffer += "\n"
    paragraphBuffer = ""
  }

  public func willVisitParagraph(style: ParagraphStyle, spatialInfo: SpatialInfo?) async {
    if !inList {
      pendingParagraphStyle = style
    }
  }

  public func didVisitParagraph() async {
    if !inList && !paragraphBuffer.isEmpty {
      if let style = pendingCharacterStyle, (style.fontSize ?? 0) < 14 {
        flushPendingParagraph()
      }
    }
  }

  public func visitInlineElement(_ element: InlineElement) async {
    switch element {
    case .text(let text, let style, let hyperlink):
      handleTextElement(text, style: style, hyperlink: hyperlink)

    case .footnoteMarker(let footnote):
      consecutiveEmptyParagraphs = 0
      hasContentSinceLastHeader = true
      paragraphBuffer += "[^\(footnote.number)]"
      footnotes.append((number: footnote.number, content: footnote.content))

    case .image(let info, _, let ocrResult, let hyperlink):
      consecutiveEmptyParagraphs = 0
      hasContentSinceLastHeader = true
      renderImage(info: info, ocrResult: ocrResult, hyperlink: hyperlink)

    case .equation(let equation):
      consecutiveEmptyParagraphs = 0
      hasContentSinceLastHeader = true
      renderEquation(equation)

    case .media(let info, _):
      consecutiveEmptyParagraphs = 0
      hasContentSinceLastHeader = true
      renderMedia(info: info)

    case .object3D(let info, _, let hyperlink):
      consecutiveEmptyParagraphs = 0
      hasContentSinceLastHeader = true
      render3DObject(info: info, hyperlink: hyperlink)

    case .chart(let info, _):
      consecutiveEmptyParagraphs = 0
      hasContentSinceLastHeader = true
      renderInlineChart(info: info)
    }
  }

  public func willVisitTable(
    name: String?,
    rowCount: UInt32,
    columnCount: UInt32,
    spatialInfo: SpatialInfo
  ) async {
    flushPendingParagraph()
    ensureBlankLine()

    if let name = name {
      let cleaned = cleanText(name)
      if !cleaned.isEmpty {
        buffer += "**\(escapeMd(cleaned))**\n\n"
      }
    }

    currentTable = TableBuilder(rows: Int(rowCount), columns: Int(columnCount))
    resetContext()
  }

  public func visitTableCell(row: Int, column: Int, content: TableCellContent) async {
    guard let table = currentTable else { return }

    let cellText: String
    switch content {
    case .empty:
      cellText = ""
    case .number(let value, _):
      cellText = formatNumber(value)
    case .date(let date, _):
      cellText = formatDate(date)
    case .boolean(let value, _):
      cellText = value ? "true" : "false"
    case .text(let text, _):
      cellText = escapeMd(cleanText(text))
    case .richText(let elements, _):
      cellText = renderRichTextElements(elements)
    case .duration(let seconds, _):
      cellText = formatDuration(seconds)
    case .currency(let amount, let format, _):
      cellText = formatCurrency(amount, format: format)
    case .formulaError:
      cellText = "#ERROR!"
    }

    table.setCell(row: row, column: column, content: cellText)
  }

  public func didVisitTable() async {
    if let table = currentTable {
      buffer += table.renderMarkdown()
      ensureBlankLine()
    }
    currentTable = nil
  }

  public func visitImage(
    info: ImageInfo,
    spatialInfo: SpatialInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?
  ) async {
    flushPendingParagraph()
    ensureBlankLine()
    renderImage(info: info, ocrResult: ocrResult, hyperlink: hyperlink, isFloating: true)
    resetContext()
  }

  public func visitMedia(info: MediaInfo, spatialInfo: SpatialInfo) async {
    flushPendingParagraph()
    ensureBlankLine()
    renderMedia(info: info, isFloating: true)
    resetContext()
  }

  public func visitChart(info: ChartInfo, spatialInfo: SpatialInfo) async {
    flushPendingParagraph()
    ensureBlankLine()
    renderChart(info: info)
    resetContext()
  }

  public func visitObject3D(info: Object3DInfo, spatialInfo: SpatialInfo) async {
    flushPendingParagraph()
    ensureBlankLine()
    render3DObject(info: info, hyperlink: info.hyperlink, isFloating: true)
    resetContext()
  }

  private func handleTextElement(_ text: String, style: CharacterStyle, hyperlink: Hyperlink?) {
    let cleaned = cleanText(text)
    if cleaned.isEmpty {
      consecutiveEmptyParagraphs += 1
      return
    }

    if consecutiveEmptyParagraphs > 0 && !paragraphBuffer.isEmpty {
      flushPendingParagraph()
    }
    consecutiveEmptyParagraphs = 0

    let isHeaderSize = (style.fontSize ?? 0) >= 14

    if !inList {
      handleStyleTransitions(currentStyle: style)
    }

    renderText(cleaned, style: style, hyperlink: hyperlink)

    if !isHeaderSize {
      hasContentSinceLastHeader = true
    }
  }

  private func handleStyleTransitions(currentStyle: CharacterStyle) {
    let isHeaderSize = (currentStyle.fontSize ?? 0) >= 14
    let prevWasHeaderSize = (pendingCharacterStyle?.fontSize ?? 0) >= 14

    if prevWasHeaderSize && !isHeaderSize && !paragraphBuffer.isEmpty {
      flushPendingParagraph()
      isFirstTextInMergedGroup = true
    } else if isHeaderSize {
      let shouldMerge = shouldMergeWithPrevious(currentStyle: currentStyle)

      if !shouldMerge && !paragraphBuffer.isEmpty {
        flushPendingParagraph()
        isFirstTextInMergedGroup = true
      }
    }

    pendingCharacterStyle = currentStyle
  }

  private func shouldMergeWithPrevious(currentStyle: CharacterStyle) -> Bool {
    guard let fontSize = currentStyle.fontSize, fontSize >= 14 else {
      return false
    }

    guard let prevStyle = pendingCharacterStyle,
      let prevFontSize = prevStyle.fontSize,
      prevFontSize >= 14
    else {
      return false
    }

    guard let prevParagraphStyle = pendingParagraphStyle,
      let currentParagraphStyle = pendingParagraphStyle,
      prevParagraphStyle == currentParagraphStyle
    else {
      return false
    }

    guard
      prevStyle.isBold == currentStyle.isBold && prevStyle.isItalic == currentStyle.isItalic
        && prevFontSize == fontSize
    else {
      return false
    }

    if currentStyle.isBold || currentStyle.isItalic || currentStyle.isStrikethrough {
      let hasFormatting =
        paragraphBuffer.contains("**") || paragraphBuffer.contains("***")
        || paragraphBuffer.contains("~~")
        || (paragraphBuffer.contains("*") && !paragraphBuffer.contains("**"))
      if hasFormatting {
        return false
      }
    }

    return true
  }

  private func flushPendingParagraph() {
    let content = paragraphBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
    if !content.isEmpty && !inList {
      ensureBlankLine()
      buffer += content + "\n\n"

      if content.hasPrefix("#") {
        let headerMatch = content.prefix(while: { $0 == "#" })
        lastHeaderLevel = headerMatch.count
        hasContentSinceLastHeader = false
      } else {
        lastHeaderLevel = 0
        lastHeaderFontSize = nil
        hasContentSinceLastHeader = true
      }
    }

    paragraphBuffer = ""
    pendingParagraphStyle = nil
    pendingCharacterStyle = nil
    isFirstTextInMergedGroup = true
  }

  private func renderText(_ text: String, style: CharacterStyle, hyperlink: Hyperlink?) {
    if !paragraphBuffer.isEmpty && !isFirstTextInMergedGroup {
      paragraphBuffer += " "
    }

    var headerLevel = 0
    if isFirstTextInMergedGroup && !inList, let fontSize = style.fontSize {
      headerLevel = determineHeaderLevel(fontSize: fontSize)

      if headerLevel > 0 {
        if !hasContentSinceLastHeader,
          let lastFontSize = lastHeaderFontSize,
          abs(fontSize - lastFontSize) < 0.1
        {
          headerLevel = min(lastHeaderLevel + 1, 6)
        } else if lastHeaderLevel > 0 && headerLevel <= lastHeaderLevel {
          headerLevel = min(lastHeaderLevel + 1, 6)
        }

        lastHeaderFontSize = fontSize
        paragraphBuffer += String(repeating: "#", count: headerLevel) + " "
      } else {
        lastHeaderFontSize = nil
      }
    }

    let formatted = formatTextWithStyle(text, style: style, hyperlink: hyperlink)

    if needsSpaceBeforeText(formatted) {
      paragraphBuffer += " "
    }

    paragraphBuffer += formatted
    isFirstTextInMergedGroup = false
  }

  private func determineHeaderLevel(fontSize: Double) -> Int {
    if fontSize >= 18 {
      return 1
    } else if fontSize >= 16 {
      return 2
    } else if fontSize >= 14 {
      return 3
    }
    return 0
  }

  private func formatTextWithStyle(
    _ text: String,
    style: CharacterStyle,
    hyperlink: Hyperlink?
  ) -> String {
    var formatted = escapeMd(text)

    if hyperlink == nil && isValidEmail(text) {
      return "[\(formatted)](mailto:\(text))"
    }

    if style.isBold && style.isItalic {
      formatted = "***\(formatted)***"
    } else if style.isBold {
      formatted = "**\(formatted)**"
    } else if style.isItalic {
      formatted = "*\(formatted)*"
    }

    if style.isStrikethrough {
      formatted = "~~\(formatted)~~"
    }

    if let link = hyperlink {
      formatted = "[\(formatted)](\(link.url))"
    }

    return formatted
  }

  private func needsSpaceBeforeText(_ formatted: String) -> Bool {
    guard !paragraphBuffer.isEmpty && !formatted.isEmpty && !isFirstTextInMergedGroup else {
      return false
    }

    let textStart = formatted.first!
    if textStart.isWhitespace || textStart.isPunctuation {
      return false
    }

    let end = String(paragraphBuffer.suffix(3))
    return end.hasSuffix("***") || end.hasSuffix("**") || end.hasSuffix("~~") || end.hasSuffix("*)")
      || (end.hasSuffix("*") && !end.hasSuffix("**") && !end.hasSuffix("***"))
  }

  private func needsConversion(_ filepath: String) -> Bool {
    let lowercased = filepath.lowercased()
    return lowercased.hasSuffix(".dng") || lowercased.hasSuffix(".pdf")
  }

  private func convertToJPEG(data: Data, sourceFilepath: String) -> Data? {
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
      return nil
    }

    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      mutableData as CFMutableData,
      UTType.jpeg.identifier as CFString,
      1,
      nil
    ) else {
      return nil
    }

    let options: [CFString: Any] = [
      kCGImageDestinationLossyCompressionQuality: 0.9
    ]

    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    
    guard CGImageDestinationFinalize(destination) else {
      return nil
    }

    return mutableData as Data
  }

  private func saveAsset(from filepath: String) -> String? {
    guard let outputDir = configuration.outputDirectory else {
      return nil
    }

    guard let data = try? document.storage.readData(from: filepath) else {
      return nil
    }

    let fileManager = FileManager.default
    let outputURL = URL(fileURLWithPath: outputDir)

    do {
      try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

      var filename = (filepath as NSString).lastPathComponent
      var finalData = data

      if needsConversion(filepath) {
        if let jpegData = convertToJPEG(data: data, sourceFilepath: filepath) {
          let nameWithoutExtension = (filename as NSString).deletingPathExtension
          filename = "\(nameWithoutExtension).jpg"
          finalData = jpegData
        }
      }

      let destinationURL = outputURL.appendingPathComponent(filename)
      try finalData.write(to: destinationURL)

      return filename
    } catch {
      return nil
    }
  }

  private func renderImage(
    info: ImageInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?,
    isFloating: Bool = false
  ) {
    if let attributes = info.attributes {
      let externalURL = attributes["externalURL"] ?? ""
      let title = attributes["title"]
      let description = attributes["description"]
      
      let altText: String
      if let desc = description, !cleanText(desc).isEmpty {
        altText = cleanText(desc).replacingOccurrences(of: "\n", with: " ")
      } else if let ocr = ocrResult, !cleanText(ocr.text).isEmpty {
        altText = cleanText(ocr.text).replacingOccurrences(of: "\n", with: " ")
      } else if let t = title, !cleanText(t).isEmpty {
        altText = cleanText(t).replacingOccurrences(of: "\n", with: " ")
      } else {
        altText = "Video"
      }
      
      let imagePath: String
      if let savedFilename = saveAsset(from: info.filepath) {
        imagePath = savedFilename
      } else {
        imagePath = info.filepath
      }
      
      let encodedPath = imagePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? imagePath
      
      let imageMarkdown: String
      if let t = title, !cleanText(t).isEmpty {
        let cleanTitle = cleanText(t).replacingOccurrences(of: "\n", with: " ")
        imageMarkdown = "![\(escapeMd(altText))](\(encodedPath) \"\(escapeMd(cleanTitle))\")"
      } else {
        imageMarkdown = "![\(escapeMd(altText))](\(encodedPath))"
      }
      
      if !externalURL.isEmpty {
        paragraphBuffer += "[\(imageMarkdown)](\(externalURL))"
      } else {
        paragraphBuffer += imageMarkdown
      }
      
      if isFloating {
        flushToBuffer()
      }
      return
    }

    let rawAltText: String
    let usedOCRForAlt: Bool
    if let description = info.description, !cleanText(description).isEmpty {
      rawAltText = cleanText(description)
      usedOCRForAlt = false
    } else if let ocr = ocrResult, !cleanText(ocr.text).isEmpty {
      rawAltText = cleanText(ocr.text)
      usedOCRForAlt = true
    } else if let filename = info.filename, !cleanText(filename).isEmpty {
      rawAltText = cleanText(filename)
      usedOCRForAlt = false
    } else {
      rawAltText = "image"
      usedOCRForAlt = false
    }
    
    let altText = rawAltText.replacingOccurrences(of: "\n", with: " ")
    guard !altText.isEmpty else { return }

    let imagePath: String
    if let savedFilename = saveAsset(from: info.filepath) {
      imagePath = savedFilename
    } else {
      imagePath = info.filepath
    }
    
    let encodedPath = imagePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? imagePath

    let imageTitle: String?
    if let titleData = info.title, !cleanText(titleData.text).isEmpty {
      let cleaned = cleanText(titleData.text).replacingOccurrences(of: "\n", with: " ")
      imageTitle = cleaned
    } else {
      imageTitle = nil
    }

    let imageMarkdown: String
    if let title = imageTitle {
      imageMarkdown = "![\(escapeMd(altText))](\(encodedPath) \"\(escapeMd(title))\")"
    } else {
      imageMarkdown = "![\(escapeMd(altText))](\(encodedPath))"
    }

    let finalMarkdown: String
    if let link = hyperlink {
      finalMarkdown = "[\(imageMarkdown)](\(link.url))"
    } else {
      finalMarkdown = imageMarkdown
    }

    if isFloating {
      paragraphBuffer += finalMarkdown
      flushToBuffer()
      
      appendMetadata(title: info.title, caption: info.caption)

      if !usedOCRForAlt, let ocr = ocrResult {
        let ocrText = cleanText(ocr.text)
        if !ocrText.isEmpty {
          let lines = ocrText.components(separatedBy: "\n")
          for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty {
              buffer += ">\n"
            } else {
              buffer += "> \(escapeMd(trimmedLine))\n"
            }
          }
          buffer += "\n"
        }
      }
    } else {
      if !paragraphBuffer.isEmpty && !inList {
        flushPendingParagraph()
      }
      paragraphBuffer += finalMarkdown
    }
  }

  private func renderMedia(info: MediaInfo, isFloating: Bool = false) {
    let typeStr = mediaTypeString(info.type)
    let filename = cleanText(info.filename ?? typeStr.lowercased())

    guard !filename.isEmpty else { return }

    if let filepath = info.filepath {
      let mediaPath: String
      if let savedFilename = saveAsset(from: filepath) {
        mediaPath = savedFilename
      } else {
        mediaPath = filepath
      }
      paragraphBuffer += "[\(escapeMd(typeStr)): \(escapeMd(filename))](\(mediaPath))"
    } else {
      paragraphBuffer += "[\(escapeMd(typeStr)): \(escapeMd(filename))]"
    }

    if isFloating {
      flushToBuffer()
      appendMetadata(title: info.title, caption: info.caption)
    } else {
      paragraphBuffer += " "
    }
  }

  private func render3DObject(info: Object3DInfo, hyperlink: Hyperlink?, isFloating: Bool = false) {
    let filename = cleanText(info.filename ?? "3D object")
    guard !filename.isEmpty else { return }

    let objectPath: String
    if let savedFilename = saveAsset(from: info.filepath) {
      objectPath = savedFilename
    } else {
      objectPath = info.filepath
    }

    if let link = hyperlink {
      paragraphBuffer += "[[3D Model: \(escapeMd(filename))](\(objectPath))](\(link.url))"
    } else {
      paragraphBuffer += "[3D Model: \(escapeMd(filename))](\(objectPath))"
    }

    if isFloating {
      flushToBuffer()
      appendMetadata(title: info.title, caption: info.caption)
    } else {
      paragraphBuffer += " "
    }
  }

  private func renderEquation(_ equation: IWorkEquation) {
    switch equation {
    case .latex(let latex):
      paragraphBuffer += "`$\(latex)$`"
    case .mathml:
      paragraphBuffer += "`[equation]`"
    }
  }

  private func renderInlineChart(info: ChartInfo) {
    if let title = info.title {
      let cleaned = cleanText(title.text)
      if !cleaned.isEmpty {
        paragraphBuffer += "[\(escapeMd(cleaned))]"
        return
      }
    }

    paragraphBuffer += "[Chart]"
  }

  private func renderChart(info: ChartInfo) {
    if let title = info.title {
      let cleaned = cleanText(title.text)
      if !cleaned.isEmpty {
        buffer += "**\(escapeMd(cleaned))**\n\n"
      }
    }

    let data = info.gridData
    guard !data.rows.isEmpty && data.columnCount > 0 else { return }

    let mermaid = generateMermaidChart(info)
    if !mermaid.isEmpty {
      buffer += "```mermaid\n"
      buffer += mermaid
      buffer += "```\n\n"
    }
  }

  private func renderFootnoteContent(_ elements: [InlineElement]) -> String {
    var content = ""
    for element in elements {
      switch element {
      case .text(let text, let style, let hyperlink):
        let cleaned = cleanText(text)
        guard !cleaned.isEmpty else { continue }
        content += formatTextWithStyle(cleaned, style: style, hyperlink: hyperlink)

      case .image(let info, _, _, _):
        let altText = cleanText(info.description ?? info.filename ?? "image")
        if !altText.isEmpty {
          let imagePath: String
          if let savedFilename = saveAsset(from: info.filepath) {
            imagePath = savedFilename
          } else {
            imagePath = info.filepath
          }
          content += "![\(escapeMd(altText))](\(imagePath))"
        }

      case .footnoteMarker(let nested):
        content += "[^\(nested.number)]"

      default:
        break
      }
    }
    return content
  }

  private func renderRichTextElements(_ elements: [InlineElement]) -> String {
    var result = ""
    for element in elements {
      switch element {
      case .text(let text, let style, let hyperlink):
        let cleaned = cleanText(text)
        guard !cleaned.isEmpty else { continue }
        result += formatTextWithStyle(cleaned, style: style, hyperlink: hyperlink)

      case .image(let info, _, _, _):
        let altText = cleanText(info.description ?? info.filename ?? "image")
        if !altText.isEmpty {
          let imagePath: String
          if let savedFilename = saveAsset(from: info.filepath) {
            imagePath = savedFilename
          } else {
            imagePath = info.filepath
          }
          result += "![\(escapeMd(altText))](\(imagePath))"
        }

      default:
        break
      }
    }
    return result
  }

  private func generateMermaidChart(_ info: ChartInfo) -> String {
    let data = info.gridData

    switch info.chartType {
    case .pie2D, .pie3D, .donut2D:
      return generatePieChart(info: info, data: data)
    case .bar2D, .bar3D:
      return generateXYChart(info: info, data: data, chartType: "bar", orientation: "horizontal")
    case .column2D, .column3D:
      return generateXYChart(info: info, data: data, chartType: "bar", orientation: "vertical")
    case .line2D, .line3D, .area2D, .area3D, .scatter2D:
      return generateXYChart(info: info, data: data, chartType: "line", orientation: "vertical")
    case .mixed2D:
      return generateMixedChart(info: info, data: data)
    default:
      return generateFallbackChart(info: info, data: data)
    }
  }

  private func generatePieChart(info: ChartInfo, data: ChartGridData) -> String {
    var mermaid = ""

    if let title = info.title {
      let cleaned = cleanText(title.text)
      mermaid += cleaned.isEmpty ? "pie\n" : "pie title \(cleaned)\n"
    } else {
      mermaid += "pie\n"
    }

    if data.direction == .byColumn {
      if let firstRow = data.rows.first {
        for (idx, value) in firstRow.values.enumerated() {
          let label =
            idx < data.columnNames.count ? cleanText(data.columnNames[idx]) : "Item \(idx + 1)"
          if !label.isEmpty, let numValue = value.numericValue {
            mermaid += "    \"\(label)\" : \(formatNumber(numValue))\n"
          }
        }
      }
    } else {
      for (idx, row) in data.rows.enumerated() {
        let label = idx < data.rowNames.count ? cleanText(data.rowNames[idx]) : "Item \(idx + 1)"
        if !label.isEmpty, let value = row.values.first?.numericValue {
          mermaid += "    \"\(label)\" : \(formatNumber(value))\n"
        }
      }
    }

    return mermaid
  }

  private func generateXYChart(
    info: ChartInfo,
    data: ChartGridData,
    chartType: String,
    orientation: String
  ) -> String {
    var mermaid = orientation == "horizontal" ? "xychart-beta horizontal\n" : "xychart-beta\n"

    if let title = info.title {
      let cleaned = cleanText(title.text)
      if !cleaned.isEmpty {
        mermaid += cleaned.contains(" ") ? "    title \"\(cleaned)\"\n" : "    title \(cleaned)\n"
      }
    }

    let (categories, seriesData, seriesNames) = extractChartData(data)

    if !categories.isEmpty {
      let formattedCategories = categories.map { cat in
        cat.contains(" ") || cat.isEmpty ? "\"\(cat.isEmpty ? "blank" : cat)\"" : cat
      }.joined(separator: ", ")
      mermaid += "    x-axis [\(formattedCategories)]\n"
    }

    if let yAxisTitle = info.valueAxis.title {
      let cleaned = cleanText(yAxisTitle)
      if !cleaned.isEmpty {
        mermaid += cleaned.contains(" ") ? "    y-axis \"\(cleaned)\"\n" : "    y-axis \(cleaned)\n"
      }
    }

    for (idx, series) in seriesData.enumerated() where !series.isEmpty {
      let values = series.map { formatNumber($0) }.joined(separator: ", ")
      let seriesLabel = idx < seriesNames.count ? seriesNames[idx] : "Series \(idx + 1)"
      if !seriesLabel.isEmpty {
        mermaid += "    %% \(seriesLabel)\n"
      }
      mermaid += "    \(chartType) [\(values)]\n"
    }

    return mermaid
  }

  private func generateMixedChart(info: ChartInfo, data: ChartGridData) -> String {
    var mermaid = "xychart-beta\n"

    if let title = info.title {
      let cleaned = cleanText(title.text)
      if !cleaned.isEmpty {
        mermaid += cleaned.contains(" ") ? "    title \"\(cleaned)\"\n" : "    title \(cleaned)\n"
      }
    }

    let (categories, seriesData, _) = extractChartData(data)

    if !categories.isEmpty {
      let formattedCategories = categories.map { cat in
        cat.contains(" ") || cat.isEmpty ? "\"\(cat.isEmpty ? "blank" : cat)\"" : cat
      }.joined(separator: ", ")
      mermaid += "    x-axis [\(formattedCategories)]\n"
    }

    if let yAxisTitle = info.valueAxis.title {
      let cleaned = cleanText(yAxisTitle)
      if !cleaned.isEmpty {
        mermaid += cleaned.contains(" ") ? "    y-axis \"\(cleaned)\"\n" : "    y-axis \(cleaned)\n"
      }
    }

    for (idx, series) in seriesData.enumerated() where !series.isEmpty {
      let values = series.map { formatNumber($0) }.joined(separator: ", ")
      let chartType: String
      if idx < info.series.count {
        chartType = chartTypeForSeries(info.series[idx].seriesType)
      } else {
        chartType = idx % 2 == 0 ? "bar" : "line"
      }
      mermaid += "    \(chartType) [\(values)]\n"
    }

    return mermaid
  }

  private func generateFallbackChart(info: ChartInfo, data: ChartGridData) -> String {
    var mermaid = "graph TD\n"
    let title = info.title.map { cleanText($0.text) } ?? "Data"
    mermaid += title.isEmpty ? "    A[\"Chart Data\"]\n" : "    A[\"\(title)\"]\n"

    for (idx, rowName) in data.rowNames.prefix(5).enumerated() {
      let cleaned = cleanText(rowName)
      if !cleaned.isEmpty {
        mermaid += "    B\(idx)[\"\(cleaned)\"]\n"
        mermaid += "    A --> B\(idx)\n"
      }
    }

    return mermaid
  }

  private func extractChartData(_ data: ChartGridData) -> ([String], [[Double]], [String]) {
    let categories: [String]
    let seriesData: [[Double]]
    let seriesNames: [String]

    if data.direction == .byRow {
      categories = data.columnNames.map { cleanText($0) }
      seriesNames = data.rowNames.map { cleanText($0) }
      seriesData = data.rows.map { row in
        row.values.compactMap { $0.numericValue }
      }
    } else {
      categories = data.rowNames.map { cleanText($0) }
      seriesNames = data.columnNames.map { cleanText($0) }
      seriesData = (0..<data.columnCount).map { colIdx in
        data.rows.compactMap { row in
          colIdx < row.values.count ? row.values[colIdx].numericValue : nil
        }
      }
    }

    return (categories, seriesData, seriesNames)
  }

  private func chartTypeForSeries(_ seriesType: ChartType) -> String {
    switch seriesType {
    case .bar2D, .bar3D, .column2D, .column3D:
      return "bar"
    case .line2D, .line3D, .area2D, .area3D:
      return "line"
    default:
      return "line"
    }
  }

  private func resetContext() {
    consecutiveEmptyParagraphs = 0
    lastHeaderLevel = 0
    lastHeaderFontSize = nil
    hasContentSinceLastHeader = false
  }

  private func flushToBuffer() {
    buffer += paragraphBuffer + "\n\n"
    paragraphBuffer = ""
  }

  private func appendMetadata(title: CaptionData?, caption: CaptionData?) {
    if let title = title {
      let cleaned = cleanText(title.text)
      if !cleaned.isEmpty {
        buffer += "*\(escapeMd(cleaned))*\n\n"
      }
    }

    if let caption = caption {
      let cleaned = cleanText(caption.text)
      if !cleaned.isEmpty {
        buffer += "*\(escapeMd(cleaned))*\n\n"
      }
    }
  }

  private func isValidEmail(_ email: String) -> Bool {
    let emailPattern = Regex {
      OneOrMore {
        CharacterClass(.anyOf("._%+-"), ("a"..."z"), ("A"..."Z"), ("0"..."9"))
      }
      "@"
      OneOrMore {
        CharacterClass(.anyOf(".-"), ("a"..."z"), ("A"..."Z"), ("0"..."9"))
      }
      "."
      Repeat(2...) {
        CharacterClass(("a"..."z"), ("A"..."Z"))
      }
    }
    return email.wholeMatch(of: emailPattern) != nil
  }

  private func cleanText(_ text: String) -> String {
    var cleaned = text
    cleaned = cleaned.replacingOccurrences(of: "\u{FFFC}", with: "")
    cleaned = cleaned.replacingOccurrences(of: "\u{2029}", with: "\n\n")
    cleaned = cleaned.replacingOccurrences(of: "\u{2028}", with: "\n")
    cleaned = cleaned.replacingOccurrences(of: "\u{0003}", with: "---")

    cleaned = cleaned.filter { char in
      let scalar = char.unicodeScalars.first!
      return !scalar.properties.isNoncharacterCodePoint
        && (scalar.value >= 0x20 || char == "\n" || char == "\t")
    }

    return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func ensureBlankLine() {
    if !buffer.isEmpty && !buffer.hasSuffix("\n\n") {
      buffer += buffer.hasSuffix("\n") ? "\n" : "\n\n"
    }
  }

  private func escapeMd(_ text: String) -> String {
    var escaped = text.replacingOccurrences(of: "\\", with: "\\\\")

    let specials = ["`", "*", "_", "{", "}", "[", "]", "(", ")", "#", "+", "-", ".", "!", "|"]
    for char in specials {
      escaped = escaped.replacingOccurrences(of: char, with: "\\\(char)")
    }
    return escaped
  }

  private func formatNumber(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
      return String(Int(value))
    } else {
      return String(format: "%.2f", value)
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.string(from: date)
  }

  private func formatDuration(_ seconds: Double) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    let secs = Int(seconds) % 60

    if hours > 0 {
      return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", secs))"
    } else {
      return "\(minutes):\(String(format: "%02d", secs))"
    }
  }

  private func formatCurrency(_ amount: Double, format: CurrencyFormat) -> String {
    let symbol = format.showSymbol ? format.displaySymbol : ""
    let decimals = format.usesAutomaticDecimalPlaces ? 2 : Int(format.decimalPlaces)
    let formatted = String(format: "%.\(decimals)f", abs(amount))

    if format.useAccountingStyle && amount < 0 {
      return "\(symbol)(\(formatted))"
    } else {
      let sign = amount < 0 ? "-" : ""
      return "\(sign)\(symbol)\(formatted)"
    }
  }

  private func mediaTypeString(_ type: MediaType) -> String {
    switch type {
    case .audio: return "Audio"
    case .video: return "Video"
    case .gif: return "GIF"
    }
  }
}

private final class TableBuilder {
  private var cells: [[String]]
  private let rows: Int
  private let columns: Int
  private var columnWidths: [Int] = []

  init(rows: Int, columns: Int) {
    self.rows = rows
    self.columns = columns
    self.cells = Array(repeating: Array(repeating: "", count: columns), count: rows)
    self.columnWidths = Array(repeating: 3, count: columns)
  }

  func setCell(row: Int, column: Int, content: String) {
    guard row < rows && column < columns else { return }
    let cleaned =
      content
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "|", with: "\\|")
      .trimmingCharacters(in: .whitespaces)
    cells[row][column] = cleaned
    columnWidths[column] = max(columnWidths[column], cleaned.count)
  }

  func renderMarkdown() -> String {
    guard rows > 0 && columns > 0 else { return "" }

    var markdown = ""

    markdown += "|"
    for col in 0..<columns {
      let content = cells[0][col].padding(toLength: columnWidths[col], withPad: " ", startingAt: 0)
      markdown += " \(content) |"
    }
    markdown += "\n"

    markdown += "|"
    for col in 0..<columns {
      let separator = String(repeating: "-", count: columnWidths[col])
      markdown += " \(separator) |"
    }
    markdown += "\n"

    for row in 1..<rows {
      markdown += "|"
      for col in 0..<columns {
        let content = cells[row][col].padding(
          toLength: columnWidths[col], withPad: " ", startingAt: 0)
        markdown += " \(content) |"
      }
      markdown += "\n"
    }

    markdown += "\n"
    return markdown
  }
}