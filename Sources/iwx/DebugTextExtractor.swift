import Foundation
import ModelIO
import WorkKit

// MARK: - Debug Text Extractor

/// Extracts plain text with spatial and structural debugging information.
///
/// This visitor includes detailed metadata about document structure,
/// positioning, and formatting for debugging purposes.
public final class DebugTextExtractor<O: OCRProvider>: IWorkDocumentVisitor, @unchecked Sendable {
  private var buffer: String = ""
  private var indentLevel: Int = 0
  private var document: IWorkDocument
  private var ocrProvider: O?

  /// Context for where an inline element is being logged
  private enum LogContext {
    case paragraph
    case footnote
    case cell
  }

  /// The extracted text with debug annotations.
  public var text: String {
    buffer
  }

  public init(using document: IWorkDocument, with ocrProvider: O? = nil) {
    self.document = document
    self.ocrProvider = ocrProvider
  }

  public func accept() async throws {
    if let ocrProvider {
      try await document.accept(visitor: self, ocrProvider: ocrProvider)
    } else {
      try await document.accept(visitor: self)
    }
  }

  // MARK: - Basic Logging Utilities

  private func indent() -> String {
    String(repeating: "  ", count: indentLevel)
  }

  private func log(_ message: String) {
    buffer.append("\(indent())\(message)\n")
  }

  private func logSeparator(_ char: Character = "=", length: Int = 80) {
    log(String(repeating: char, count: length))
  }

  private func logBoxTop(_ title: String) {
    let padding = 76 - title.count
    let leftPad = padding / 2
    let rightPad = padding - leftPad
    log("+\(String(repeating: "-", count: 78))+")
    log(
      "|\(String(repeating: " ", count: leftPad))\(title)\(String(repeating: " ", count: rightPad))|"
    )
    log("+\(String(repeating: "-", count: 78))+")
  }

  private func logBoxBottom() {
    log("+\(String(repeating: "-", count: 78))+")
  }

  // MARK: - Document Structure

  public func willVisitDocument(
    type: IWorkDocument.DocumentType,
    layout: DocumentLayout?,
    pageSettings: PageSettings?
  ) {
    logSeparator("=", length: 80)
    log("DOCUMENT START")
    logSeparator("=", length: 80)
    log("Type: \(type)")

    if let layout = layout {
      log("")
      log("Layout Configuration:")
      log("  Page Dimensions:")
      log("    Width:  \(layout.pageWidth) pt")
      log("    Height: \(layout.pageHeight) pt")
      log("    Orientation: \(layout.orientation == 0 ? "portrait" : "landscape")")
      log("")
      log("  Margins:")
      log("    Top:    \(layout.topMargin) pt")
      log("    Bottom: \(layout.bottomMargin) pt")
      log("    Left:   \(layout.leftMargin) pt")
      log("    Right:  \(layout.rightMargin) pt")
      log("    Header: \(layout.headerMargin) pt")
      log("    Footer: \(layout.footerMargin) pt")
      log("")
      log("  Content Area:")
      log("    Origin: (\(layout.contentRect.origin.x), \(layout.contentRect.origin.y))")
      log("    Size:   \(layout.contentRect.size.width) x \(layout.contentRect.size.height) pt")
      log("    Bounds: \(formatRect(layout.contentRect))")
    }

    log("")
    indentLevel += 1
  }

  public func didVisitDocument(type: IWorkDocument.DocumentType) {
    indentLevel -= 1
    log("")
    logSeparator("=", length: 80)
    log("DOCUMENT END")
    logSeparator("=", length: 80)
  }

  // MARK: - Pages

  public func willVisitPagesBody(contentRect: CGRect) {
    logSeparator("-", length: 80)
    log("PAGES BODY BEGIN")
    logSeparator("-", length: 80)
    log("Content Rectangle:")
    log("  Origin: (\(contentRect.origin.x), \(contentRect.origin.y))")
    log("  Size:   \(contentRect.size.width) x \(contentRect.size.height) pt")
    log("  Full:   \(formatRect(contentRect))")
    log("")
    indentLevel += 1
  }

  public func didVisitPagesBody() {
    indentLevel -= 1
    log("")
    logSeparator("-", length: 80)
    log("PAGES BODY END")
    logSeparator("-", length: 80)
  }

  // MARK: - Numbers

  public func willVisitSheet(name: String, layout: SheetLayout?) {
    logSeparator("-", length: 80)
    log("SHEET: \(name)")
    logSeparator("-", length: 80)

    if let layout = layout {
      log("Sheet Layout:")

      if let pageWidth = layout.pageWidth, let pageHeight = layout.pageHeight {
        log("  Page Size: \(pageWidth) x \(pageHeight) pt")
      }

      if let isPortrait = layout.isPortrait {
        log("  Orientation: \(isPortrait ? "portrait" : "landscape")")
      }

      if let topMargin = layout.topMargin,
        let leftMargin = layout.leftMargin,
        let bottomMargin = layout.bottomMargin,
        let rightMargin = layout.rightMargin
      {
        log("  Margins:")
        log("    Top:    \(topMargin) pt")
        log("    Bottom: \(bottomMargin) pt")
        log("    Left:   \(leftMargin) pt")
        log("    Right:  \(rightMargin) pt")
      }

      if let contentScale = layout.contentScale {
        log("  Content Scale: \(contentScale)")
      }

      if let headerInset = layout.headerInset {
        log("  Header Inset: \(headerInset) pt")
      }

      if let footerInset = layout.footerInset {
        log("  Footer Inset: \(footerInset) pt")
      }

      if let bounds = layout.pageBounds {
        log("  Page Bounds: \(formatRect(bounds))")
      }

      if let content = layout.contentRect {
        log("  Content Area: \(formatRect(content))")
      }
    }

    log("")
    indentLevel += 1
  }

  public func didVisitSheet(name: String) {
    indentLevel -= 1
    log("")
    logSeparator("-", length: 80)
    log("SHEET END: \(name)")
    logSeparator("-", length: 80)
  }

  // MARK: - Keynote

  public func willVisitSlide(index: Int, bounds: CGRect?) {
    logSeparator("-", length: 80)
    log("SLIDE #\(index)")
    logSeparator("-", length: 80)

    if let bounds = bounds {
      log("Slide Canvas:")
      log("  Origin: (\(bounds.origin.x), \(bounds.origin.y))")
      log("  Size:   \(bounds.size.width) x \(bounds.size.height) pt")
      log("  Bounds: \(formatRect(bounds))")
    }

    log("")
    indentLevel += 1
  }

  public func didVisitSlide(index: Int) {
    indentLevel -= 1
    log("")
    logSeparator("-", length: 80)
    log("SLIDE END #\(index)")
    logSeparator("-", length: 80)
  }

  // MARK: - Lists

  public func willVisitList(style: ListStyle) {
    log("[LIST BEGIN]")
    indentLevel += 1

    switch style {
    case .none:
      log("Type: NONE (should not happen)")

    case .bullet(let char):
      log("Type: BULLETED LIST")
      log("Bullet Character: '\(char)'")

    case .numbered(let numberStyle):
      log("Type: NUMBERED LIST")
      log("Numbering Format: \(formatListNumberStyle(numberStyle))")
    }

    log("")
    log("List Items:")
    indentLevel += 1
  }

  public func didVisitList() {
    indentLevel -= 1
    indentLevel -= 1
    log("[LIST END]")
    log("")
  }

  public func willVisitListItem(
    number: Int?,
    level: Int,
    style: ParagraphStyle,
    spatialInfo: SpatialInfo?
  ) {
    let marker: String
    switch style.listStyle {
    case .none:
      marker = ""
    case .bullet(let char):
      marker = char
    case .numbered(let numberStyle):
      if let num = number {
        marker = formatRenderedListNumber(num, style: numberStyle)
      } else {
        marker = "?"
      }
    }

    log("[LIST ITEM: \(marker)]")
    indentLevel += 1

    log("Item Details:")
    indentLevel += 1
    log("Level: \(level) \(level == 0 ? "(root)" : "(nested level \(level))")")

    if let itemNum = number {
      log("Number at Level: \(itemNum)")
    }

    log("Rendered Marker: '\(marker)'")
    indentLevel -= 1

    log("")
    logParagraphFormatting(style, spatialInfo: spatialInfo)

    log("")
    log("Item Content:")
    indentLevel += 1
  }

  public func didVisitListItem() {
    indentLevel -= 1
    indentLevel -= 1
    log("[LIST ITEM END]")
    log("")
  }

  // MARK: - Paragraphs

  public func willVisitParagraph(style: ParagraphStyle, spatialInfo: SpatialInfo?) {
    log("[PARAGRAPH BEGIN]")
    indentLevel += 1

    logParagraphFormatting(style, spatialInfo: spatialInfo)

    log("")
    log("Text Content:")
    indentLevel += 1
  }

  public func didVisitParagraph() {
    indentLevel -= 1
    indentLevel -= 1
    log("[PARAGRAPH END]")
    log("")
  }

  // MARK: - Unified Inline Element Handler

  public func visitInlineElement(_ element: InlineElement) async {
    logInlineElement(element, context: .paragraph)
  }

  private func logInlineElement(_ element: InlineElement, context: LogContext) {
    switch element {
    case .text(let text, let style, let hyperlink):
      logTextElement(text, style: style, hyperlink: hyperlink, context: context)

    case .footnoteMarker(let footnote):
      logFootnoteMarkerElement(footnote, context: context)

    case .image(let info, let spatialInfo, let ocrResult, let hyperlink):
      logImageElement(
        info: info,
        spatialInfo: spatialInfo,
        ocrResult: ocrResult,
        hyperlink: hyperlink,
        context: context
      )

    case .equation(let equation):
      logEquationElement(equation)

    case .media(let info, let spatialInfo):
      logMediaElement(info: info, spatialInfo: spatialInfo, context: context)

    case .object3D(let info, let spatialInfo, let hyperlink):
      log3DObjectElement(
        info: info,
        spatialInfo: spatialInfo,
        hyperlink: hyperlink,
        context: context
      )

    case .chart(let info, let spatialInfo):
      logChartElement(info: info, spatialInfo: spatialInfo, context: context)
    }
  }

  // MARK: - Individual Element Type Handlers

  private func logTextElement(
    _ text: String,
    style: CharacterStyle,
    hyperlink: Hyperlink?,
    context: LogContext
  ) {
    let escaped =
      text
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\t", with: "\\t")
      .replacingOccurrences(of: "\"", with: "\\\"")

    switch context {
    case .paragraph:
      if let link = hyperlink {
        log("TEXT RUN [HYPERLINKED]")
        indentLevel += 1
        log("Content: \"\(escaped)\"")
        log("Link:")
        log("  URL:   \(link.url)")
        log("  Display Text: \"\(link.text)\"")
        log("  Range: \(link.range.lowerBound) ..< \(link.range.upperBound)")
      } else {
        log("TEXT RUN")
        indentLevel += 1
        log("Content: \"\(escaped)\"")
      }
      logCharacterStyleDetails(style)
      indentLevel -= 1
      log("")

    case .footnote, .cell:
      if let link = hyperlink {
        log("TEXT [HYPERLINKED]: \"\(escaped)\"")
        indentLevel += 1
        log("URL: \(link.url)")
        indentLevel -= 1
      } else {
        log("TEXT: \"\(escaped)\"")
      }

      if style.isBold || style.isItalic || style.isUnderline || style.fontSize != nil {
        indentLevel += 1
        logCharacterStyleBrief(style)
        indentLevel -= 1
      }
      log("")
    }
  }

  private func logFootnoteMarkerElement(_ footnote: Footnote, context: LogContext) {
    switch context {
    case .paragraph:
      log("FOOTNOTE MARKER #\(footnote.number)")
      indentLevel += 1
      log("Rendered As: [\(footnote.number)]")
      log("")
      log("Footnote Content:")
      indentLevel += 1

      for element in footnote.content {
        logInlineElement(element, context: .footnote)
      }

      indentLevel -= 1
      indentLevel -= 1
      log("")

    case .footnote:
      log("(nested footnote marker #\(footnote.number) - unusual)")
      log("")

    case .cell:
      log("FOOTNOTE MARKER #\(footnote.number)")
      indentLevel += 1
      log("Rendered As: [\(footnote.number)]")
      log("(footnote content not displayed in cell context)")
      indentLevel -= 1
      log("")
    }
  }

  private func logEquationElement(_ equation: IWorkEquation) {
    switch equation {
    case .mathml(let mathml):
      log("EQUATION [MathML]:")
      indentLevel += 1
      let escaped =
        mathml
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\t", with: "\\t")
        .replacingOccurrences(of: "\"", with: "\\\"")
      log("\"\(escaped)\"")
      indentLevel -= 1
      log("")

    case .latex(let latex):
      log("EQUATION [LaTeX]:")
      indentLevel += 1
      let escaped =
        latex
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\t", with: "\\t")
        .replacingOccurrences(of: "\"", with: "\\\"")
      log("\"\(escaped)\"")
      indentLevel -= 1
      log("")
    }
  }

  // MARK: - Image Logging (Shared)

  private func logImageElement(
    info: ImageInfo,
    spatialInfo: SpatialInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?,
    context: LogContext
  ) {
    let size = (try? document.storage.size(at: info.filepath)) ?? 0

    switch context {
    case .paragraph:
      logBoxTop("INLINE IMAGE")
      indentLevel += 1
      logImageCore(
        info: info,
        spatialInfo: spatialInfo,
        ocrResult: ocrResult,
        hyperlink: hyperlink,
        size: size
      )
      indentLevel -= 1
      logBoxBottom()
      log("")

    case .footnote, .cell:
      log("INLINE IMAGE: \(info.filepath) (\(size) bytes)")
      if let link = hyperlink {
        indentLevel += 1
        log("Hyperlink: \(link.url)")
        indentLevel -= 1
      }
      indentLevel += 1
      log("Dimensions: \(info.width) x \(info.height) pixels")
      log("Position: \(formatRect(spatialInfo.frame))")
      indentLevel -= 1
      log("")
    }
  }

  public func visitImage(
    info: ImageInfo,
    spatialInfo: SpatialInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?
  ) async {
    let size = (try? document.storage.size(at: info.filepath)) ?? 0

    logBoxTop("IMAGE")
    indentLevel += 1
    logImageCore(
      info: info,
      spatialInfo: spatialInfo,
      ocrResult: ocrResult,
      hyperlink: hyperlink,
      size: size
    )
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  private func logImageCore(
    info: ImageInfo,
    spatialInfo: SpatialInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?,
    size: UInt64
  ) {
    log("Image Properties:")
    log("  Dimensions: \(info.width) x \(info.height) pixels")
    log(
      "  Data Size:  \(size) bytes (\(String(format: "%.2f", Double(size) / 1024.0)) KB)"
    )

    if let filename = info.filename {
      log("  Filename:   \(filename)")
    }

    log("  Path:       \(info.filepath)")

    if let description = info.description {
      log("  Alt Text:   \(description)")
    }

    if let hyperlink = hyperlink {
      log("")
      log("Hyperlink:")
      log("  URL: \(hyperlink.url)")
    }

    if let title = info.title {
      log("")
      log("Title Caption:")
      indentLevel += 1
      log("Text: \(title.text)")
      if let style = title.style {
        logCharacterStyleBrief(style)
      }
      logSpatialInfo(title.spatialInfo, label: "Title Position")
      indentLevel -= 1
    }

    if let caption = info.caption {
      log("")
      log("Caption:")
      indentLevel += 1
      log("Text: \(caption.text)")
      if let style = caption.style {
        logCharacterStyleBrief(style)
      }
      logSpatialInfo(caption.spatialInfo, label: "Caption Position")
      indentLevel -= 1
    }

    log("")
    logSpatialInfo(spatialInfo, label: "Image Position")

    if let ocr = ocrResult {
      log("")
      logOCRResults(ocr)
    }
  }

  private func logOCRResults(_ ocr: OCRResult) {
    log("OCR Results:")
    indentLevel += 1
    log("Extracted Text: \"\(ocr.text)\"")
    log("Observations:   \(ocr.observations.count)")

    if !ocr.observations.isEmpty {
      log("")
      log("Text Observations:")
      indentLevel += 1
      for (idx, obs) in ocr.observations.enumerated() {
        log("")
        log("Observation[\(idx)]:")
        indentLevel += 1
        log("Text:       \"\(obs.text)\"")
        log("Confidence: \(String(format: "%.2f%%", obs.confidence * 100))")
        log("Bounding Box (normalized):")
        indentLevel += 1
        log(
          "Top-Left:     (\(String(format: "%.4f", obs.boundingQuad.topLeft.x)), \(String(format: "%.4f", obs.boundingQuad.topLeft.y)))"
        )
        log(
          "Top-Right:    (\(String(format: "%.4f", obs.boundingQuad.topRight.x)), \(String(format: "%.4f", obs.boundingQuad.topRight.y)))"
        )
        log(
          "Bottom-Right: (\(String(format: "%.4f", obs.boundingQuad.bottomRight.x)), \(String(format: "%.4f", obs.boundingQuad.bottomRight.y)))"
        )
        log(
          "Bottom-Left:  (\(String(format: "%.4f", obs.boundingQuad.bottomLeft.x)), \(String(format: "%.4f", obs.boundingQuad.bottomLeft.y)))"
        )
        indentLevel -= 1
        indentLevel -= 1
      }
      indentLevel -= 1
    }

    indentLevel -= 1
  }

  // MARK: - Media Logging (Shared)

  private func logMediaElement(
    info: MediaInfo,
    spatialInfo: SpatialInfo,
    context: LogContext
  ) {
    let typeLabel = mediaTypeLabel(info.type)

    switch context {
    case .paragraph:
      logBoxTop("INLINE \(typeLabel)")
      indentLevel += 1
      logMediaCore(info: info, spatialInfo: spatialInfo, typeLabel: typeLabel)
      indentLevel -= 1
      logBoxBottom()
      log("")

    case .footnote, .cell:
      if let filepath = info.filepath {
        let size = (try? document.storage.size(at: filepath)) ?? 0
        log("INLINE \(typeLabel): \(info.filename ?? "unknown") (\(size) bytes)")
      } else {
        log("INLINE \(typeLabel): \(info.filename ?? "unknown")")
      }

      indentLevel += 1
      log("Duration: \(info.duration) seconds")
      if let width = info.width, let height = info.height {
        log("Dimensions: \(width) x \(height) pixels")
      }
      log("Position: \(formatRect(spatialInfo.frame))")
      indentLevel -= 1
      log("")
    }
  }

  public func visitMedia(info: MediaInfo, spatialInfo: SpatialInfo) async {
    let typeLabel = mediaTypeLabel(info.type)

    logBoxTop(typeLabel)
    indentLevel += 1
    logMediaCore(info: info, spatialInfo: spatialInfo, typeLabel: typeLabel)
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  private func logMediaCore(
    info: MediaInfo,
    spatialInfo: SpatialInfo,
    typeLabel: String
  ) {
    log("Media Properties:")
    log("  Type:       \(typeLabel)")

    if let filepath = info.filepath {
      let dataSize = (try? document.storage.size(at: filepath)) ?? 0
      log(
        "  Data Size:  \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / (1024.0 * 1024.0))) MB)"
      )
    }

    if let filename = info.filename {
      log("  Filename:   \(filename)")
    }

    if let filepath = info.filepath {
      log("  Path:       \(filepath)")
    }

    if let width = info.width, let height = info.height {
      log("  Dimensions: \(width) x \(height) pixels")
    }

    let duration = info.duration
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    let ms = Int((duration.truncatingRemainder(dividingBy: 1)) * 1000)
    log("  Duration:   \(minutes)m \(seconds)s \(ms)ms (\(duration) seconds)")

    log("  Volume:     \(String(format: "%.0f%%", info.volume * 100))")

    let loopText: String
    switch info.loopOption {
    case .none:
      loopText = "play once"
    case .repeat:
      loopText = "repeat continuously"
    case .backAndForth:
      loopText = "play forward and backward"
    }
    log("  Looping:    \(loopText)")

    if let poster = info.posterImage {
      log("")
      log("Poster Image:")
      indentLevel += 1
      log("Dimensions: \(poster.width) x \(poster.height) pixels")
      log("Path:       \(poster.filepath)")
      let posterSize = (try? document.storage.size(at: poster.filepath)) ?? 0
      log("Data Size:  \(posterSize) bytes")
      if let filename = poster.filename {
        log("Filename:   \(filename)")
      }
      indentLevel -= 1
    }

    logTitleAndCaption(title: info.title, caption: info.caption)

    log("")
    logSpatialInfo(spatialInfo, label: "Media Position")
  }

  private func mediaTypeLabel(_ type: MediaType) -> String {
    switch type {
    case .audio:
      return "AUDIO"
    case .video:
      return "VIDEO"
    case .gif:
      return "ANIMATED GIF"
    }
  }

  // MARK: - 3D Object Logging (Shared)

  private func log3DObjectElement(
    info: Object3DInfo,
    spatialInfo: SpatialInfo,
    hyperlink: Hyperlink?,
    context: LogContext
  ) {
    let size = (try? document.storage.size(at: info.filepath)) ?? 0

    switch context {
    case .paragraph:
      logBoxTop("INLINE 3D OBJECT")
      indentLevel += 1
      log3DObjectCore(
        info: info,
        spatialInfo: spatialInfo,
        hyperlink: hyperlink,
        size: size
      )
      indentLevel -= 1
      logBoxBottom()
      log("")

    case .footnote, .cell:
      log("INLINE 3D OBJECT: \(info.filepath) (\(size) bytes)")
      if let link = hyperlink {
        indentLevel += 1
        log("Hyperlink: \(link.url)")
        indentLevel -= 1
      }
      indentLevel += 1
      log3DObjectDetails(info)
      log("Position: \(formatRect(spatialInfo.frame))")
      indentLevel -= 1
      log("")
    }
  }

  public func visitObject3D(info: Object3DInfo, spatialInfo: SpatialInfo) async {
    let size = (try? document.storage.size(at: info.filepath)) ?? 0

    logBoxTop("3D OBJECT")
    indentLevel += 1
    log3DObjectCore(
      info: info,
      spatialInfo: spatialInfo,
      hyperlink: info.hyperlink,
      size: size
    )
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  private func log3DObjectCore(
    info: Object3DInfo,
    spatialInfo: SpatialInfo,
    hyperlink: Hyperlink?,
    size: UInt64
  ) {
    log("3D Model Properties:")
    log(
      "  Data Size:  \(size) bytes (\(String(format: "%.2f", Double(size) / (1024.0 * 1024.0))) MB)"
    )

    if let filename = info.filename {
      log("  Filename:   \(filename)")
    }

    log("  Path:       \(info.filepath)")


    if let hyperlink = hyperlink {
      log("")
      log("Hyperlink:")
      log("  URL: \(hyperlink.url)")
    }

    log("")
    log3DObjectDetails(info)

    if let thumbnail = info.thumbnailImage {
      log("")
      log("Thumbnail Preview:")
      indentLevel += 1
      log("Path: \(thumbnail.filepath)")
      let thumbSize = (try? document.storage.size(at: thumbnail.filepath)) ?? 0
      log("Size: \(thumbSize) bytes")
      if let filename = thumbnail.filename {
        log("Filename: \(filename)")
      }
      indentLevel -= 1
    }

    logTitleAndCaption(title: info.title, caption: info.caption)

    log("")
    logSpatialInfo(spatialInfo, label: "3D Object Position")
  }

  private func log3DObjectDetails(_ info: Object3DInfo) {
    log("3D Orientation (Pose):")
    indentLevel += 1
    let yawDeg = info.pose.yaw * 180 / .pi
    let pitchDeg = info.pose.pitch * 180 / .pi
    let rollDeg = info.pose.roll * 180 / .pi
    log(
      "Yaw (Y-axis):   \(String(format: "%.6f", info.pose.yaw)) rad (\(String(format: "%.2f", yawDeg))°)"
    )
    log(
      "Pitch (X-axis): \(String(format: "%.6f", info.pose.pitch)) rad (\(String(format: "%.2f", pitchDeg))°)"
    )
    log(
      "Roll (Z-axis):  \(String(format: "%.6f", info.pose.roll)) rad (\(String(format: "%.2f", rollDeg))°)"
    )
    indentLevel -= 1

    log("Bounding Rectangle (normalized coordinates):")
    indentLevel += 1
    log(
      "Origin: (\(String(format: "%.4f", info.boundingRect.origin.x)), \(String(format: "%.4f", info.boundingRect.origin.y)))"
    )
    log(
      "Size:   \(String(format: "%.4f", info.boundingRect.size.width)) x \(String(format: "%.4f", info.boundingRect.size.height))"
    )
    indentLevel -= 1

    log("Animation Properties:")
    indentLevel += 1
    log("Has Embedded Animations: \(info.hasEmbeddedAnimations ? "yes" : "no")")
    log("Auto-Play Animations:    \(info.playsAnimations ? "yes" : "no")")
    indentLevel -= 1

    if let tracedPath = info.tracedPath {
      log("Text Wrapping Path:")
      indentLevel += 1
      log("Path Elements: \(tracedPath.elements.count)")
      log("Natural Size:  \(formatSize(tracedPath.naturalSize))")

      if tracedPath.elements.count <= 10 {
        log("")
        log("Path Data:")
        indentLevel += 1
        for (idx, element) in tracedPath.elements.enumerated() {
          log("[\(idx)] \(formatPathElement(element))")
        }
        indentLevel -= 1
      } else {
        log("(Path has \(tracedPath.elements.count) elements - showing first 10)")
        log("")
        log("Path Data:")
        indentLevel += 1
        for (idx, element) in tracedPath.elements.prefix(10).enumerated() {
          log("[\(idx)] \(formatPathElement(element))")
        }
        log("... (\(tracedPath.elements.count - 10) more elements)")
        indentLevel -= 1
      }
      indentLevel -= 1
    }
  }

  // MARK: - Chart Logging (Shared)

  private func logChartElement(
    info: ChartInfo,
    spatialInfo: SpatialInfo,
    context: LogContext
  ) {
    switch context {
    case .paragraph:
      logBoxTop("INLINE CHART")
      indentLevel += 1
      logChartDetails(info, spatialInfo: spatialInfo)
      indentLevel -= 1
      logBoxBottom()
      log("")

    case .footnote, .cell:
      log("INLINE CHART: \(formatChartType(info.chartType))")
      indentLevel += 1
      log("Data: \(info.gridData.rowCount) rows × \(info.gridData.columnCount) columns")
      if let title = info.title?.text, !title.isEmpty {
        log("Title: \"\(title)\"")
      }
      log("Position: \(formatRect(spatialInfo.frame))")
      indentLevel -= 1
      log("")
    }
  }

  public func visitChart(info: ChartInfo, spatialInfo: SpatialInfo) async {
    logBoxTop("CHART")
    indentLevel += 1
    logChartDetails(info, spatialInfo: spatialInfo)
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  private func logChartDetails(_ info: ChartInfo, spatialInfo: SpatialInfo) {
    if let name = info.title?.text, !name.isEmpty {
      log("Name: \(name)")
    }
    log("")
    logSpatialInfo(spatialInfo, label: "Chart Position")
    log("")

    log("Chart Properties:")
    indentLevel += 1
    log("Type: \(formatChartType(info.chartType))")
    if let title = info.title {
      log("Title: \"\(title.text)\"")
      log("Show Title: \(info.showTitle ? "yes" : "no")")
    } else {
      log("Title: none")
    }
    log("")

    log("Data Grid:")
    indentLevel += 1
    log("Direction: \(formatChartDataDirection(info.gridData.direction))")
    log("Dimensions: \(info.gridData.rowCount) rows × \(info.gridData.columnCount) columns")

    if !info.gridData.rowNames.isEmpty {
      log("")
      log("Row Labels:")
      indentLevel += 1
      for (idx, name) in info.gridData.rowNames.enumerated() {
        log("[\(idx)] \(name)")
      }
      indentLevel -= 1
    }

    if !info.gridData.columnNames.isEmpty {
      log("")
      log("Column Labels:")
      indentLevel += 1
      for (idx, name) in info.gridData.columnNames.enumerated() {
        log("[\(idx)] \(name)")
      }
      indentLevel -= 1
    }

    log("")
    log("Data Values:")
    indentLevel += 1
    for (rowIdx, row) in info.gridData.rows.enumerated() {
      let valuesStr = row.values.map { value in
        if let num = value.numericValue {
          return String(format: "%.2f", num)
        } else {
          return "empty"
        }
      }.joined(separator: ", ")
      log("Row[\(rowIdx)]: [\(valuesStr)]")
    }
    indentLevel -= 1
    indentLevel -= 1
    log("")

    log("Value (Y) Axis:")
    indentLevel += 1
    logChartAxis(info.valueAxis)
    indentLevel -= 1
    log("")

    log("Category (X) Axis:")
    indentLevel += 1
    logChartAxis(info.categoryAxis)
    indentLevel -= 1

    if !info.series.isEmpty {
      log("")
      log("Data Series: (\(info.series.count) series)")
      indentLevel += 1
      for (idx, series) in info.series.enumerated() {
        log("")
        log("Series[\(idx)]:")
        indentLevel += 1
        logChartSeries(series)
        indentLevel -= 1
      }
      indentLevel -= 1
    }

    log("")
    log("Legend:")
    indentLevel += 1
    logChartLegend(info.legend)
    indentLevel -= 1
    log("")

    log("Styling:")
    indentLevel += 1
    log("Background Fill: \(formatShapeFill(info.backgroundFill))")
    log("Plot Area Fill: \(formatShapeFill(info.plotAreaFill))")
    indentLevel -= 1
  }

  // MARK: - Chart Helper Methods

  private func logChartAxis(_ axis: ChartAxisInfo) {
    if let title = axis.title {
      log("Title: \"\(title)\"")
    } else {
      log("Title: none")
    }

    log("Visible: \(axis.isVisible ? "yes" : "no")")
    log("Show Labels: \(axis.showLabels ? "yes" : "no")")
    log("Show Major Gridlines: \(axis.showMajorGridlines ? "yes" : "no")")
    log("Show Minor Gridlines: \(axis.showMinorGridlines ? "yes" : "no")")
    log("Scale: \(formatChartAxisScale(axis.scale))")

    if let min = axis.minimumValue {
      log("Minimum Value: \(min)")
    }

    if let max = axis.maximumValue {
      log("Maximum Value: \(max)")
    }

    if let format = axis.numberFormat {
      log("")
      log("Number Format:")
      indentLevel += 1
      logChartNumberFormat(format)
      indentLevel -= 1
    }
  }

  private func logChartNumberFormat(_ format: ChartNumberFormat) {
    log("Type: \(formatChartNumberFormatType(format.type))")
    log("Decimal Places: \(format.decimalPlaces)")
    log("Show Thousands Separator: \(format.showThousandsSeparator ? "yes" : "no")")

    if let currency = format.currencyCode {
      log("Currency Code: \(currency)")
    }

    if let custom = format.formatString {
      log("Format String: \"\(custom)\"")
    }
  }

  private func logChartSeries(_ series: ChartSeriesInfo) {
    log("Series Type: \(formatChartType(series.seriesType))")
    log("Fill: \(formatShapeFill(series.fill))")

    if let stroke = series.stroke {
      log("Stroke:")
      indentLevel += 1
      log("Width: \(stroke.width) pt")
      log(
        "Color: rgba(\(stroke.color.red), \(stroke.color.green), \(stroke.color.blue), \(stroke.color.alpha))"
      )
      log("Style: \(formatBorderStyle(stroke.style))")
      indentLevel -= 1
    } else {
      log("Stroke: none")
    }

    log("Show Value Labels: \(series.showValueLabels ? "yes" : "no")")

    if series.showValueLabels {
      log("Value Label Position: \(formatChartValueLabelPosition(series.valueLabelPosition))")
    }

    if let format = series.numberFormat {
      log("")
      log("Number Format:")
      indentLevel += 1
      logChartNumberFormat(format)
      indentLevel -= 1
    }
  }

  private func logChartLegend(_ legend: ChartLegendInfo) {
    log("Visible: \(legend.isVisible ? "yes" : "no")")

    if legend.isVisible {
      log("Background Fill: \(formatShapeFill(legend.fill))")

      if let stroke = legend.stroke {
        log("Border:")
        indentLevel += 1
        log("Width: \(stroke.width) pt")
        log(
          "Color: rgba(\(stroke.color.red), \(stroke.color.green), \(stroke.color.blue), \(stroke.color.alpha))"
        )
        log("Style: \(formatBorderStyle(stroke.style))")
        indentLevel -= 1
      } else {
        log("Border: none")
      }

      if let spatial = legend.spatialInfo {
        log("")
        logSpatialInfo(spatial, label: "Legend Position")
      }
    }
  }

  private func formatChartType(_ type: ChartType) -> String {
    switch type {
    case .bar2D: return "2D Bar Chart"
    case .bar3D: return "3D Bar Chart"
    case .column2D: return "2D Column Chart"
    case .column3D: return "3D Column Chart"
    case .line2D: return "2D Line Chart"
    case .line3D: return "3D Line Chart"
    case .area2D: return "2D Area Chart"
    case .area3D: return "3D Area Chart"
    case .pie2D: return "2D Pie Chart"
    case .pie3D: return "3D Pie Chart"
    case .scatter2D: return "2D Scatter Plot"
    case .bubble2D: return "2D Bubble Chart"
    case .mixed2D: return "Mixed 2D Chart"
    case .donut2D: return "2D Donut Chart"
    case .unknown(let code): return "Unknown Chart Type (\(code))"
    }
  }

  private func formatChartDataDirection(_ direction: ChartDataDirection) -> String {
    switch direction {
    case .byRow: return "by row (series in rows, categories in columns)"
    case .byColumn: return "by column (series in columns, categories in rows)"
    }
  }

  private func formatChartAxisScale(_ scale: ChartAxisScale) -> String {
    switch scale {
    case .linear: return "linear"
    case .logarithmic: return "logarithmic"
    case .unknown(let code): return "unknown (\(code))"
    }
  }

  private func formatChartValueLabelPosition(_ position: ChartValueLabelPosition) -> String {
    switch position {
    case .automatic: return "automatic"
    case .center: return "center"
    case .insideEnd: return "inside end"
    case .insideBase: return "inside base"
    case .outside: return "outside"
    case .outsideEnd: return "outside end"
    case .unknown(let code): return "unknown (\(code))"
    }
  }

  private func formatChartNumberFormatType(_ type: ChartNumberFormatType) -> String {
    switch type {
    case .decimal: return "decimal"
    case .currency: return "currency"
    case .percentage: return "percentage"
    case .scientific: return "scientific"
    case .fraction: return "fraction"
    case .base: return "base"
    case .dateTime: return "dateTime"
    case .duration: return "duration"
    case .custom: return "custom"
    case .unknown(let code): return "unknown (\(code))"
    }
  }

  // MARK: - Floating Tables

  public func willVisitTable(
    name: String?,
    rowCount: UInt32,
    columnCount: UInt32,
    spatialInfo: SpatialInfo
  ) {
    logBoxTop("TABLE")
    indentLevel += 1

    if let name = name, !name.isEmpty {
      log("Name: \(name)")
    }

    log("Structure:")
    log("  Rows:    \(rowCount)")
    log("  Columns: \(columnCount)")
    log("  Cells:   \(rowCount * columnCount) total")
    log("")

    logSpatialInfo(spatialInfo, label: "Table Position")
    log("")

    log("Cell Data:")
    indentLevel += 1
  }

  public func didVisitTable() {
    indentLevel -= 1
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  public func willVisitTableRow(index: Int) {
    log("Row[\(index)]:")
    indentLevel += 1
  }

  public func didVisitTableRow(index: Int) {
    indentLevel -= 1
  }

  public func visitTableCell(row: Int, column: Int, content: TableCellContent) {
    log("Cell[\(row),\(column)]")
    indentLevel += 1

    let contentDesc: String
    switch content {
    case .empty:
      contentDesc = "EMPTY"

    case .number(let value, _):
      contentDesc = "NUMBER: \(value)"

    case .date(let date, _):
      let formatter = ISO8601DateFormatter()
      contentDesc = "DATE: \(formatter.string(from: date))"

    case .boolean(let value, _):
      contentDesc = "BOOLEAN: \(value ? "true" : "false")"

    case .text(let text, _):
      let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
      contentDesc = "TEXT: \"\(escaped)\""

    case .richText(let elements, _):
      contentDesc = "RICH_TEXT (\(elements.count) inline elements)"

    case .currency(let amount, let format, _):
      let symbol = format.showSymbol ? format.displaySymbol : ""
      let decimals = format.usesAutomaticDecimalPlaces ? 2 : Int(format.decimalPlaces)
      let formattedNumber = String(format: "%.\(decimals)f", amount)
      let value =
        format.useAccountingStyle && amount < 0
        ? "(\(abs(amount)))"
        : formattedNumber
      contentDesc = "CURRENCY: \(symbol)\(value) (\(format.code))"

    case .duration(let seconds, _):
      let hours = Int(seconds) / 3600
      let minutes = (Int(seconds) % 3600) / 60
      let secs = Int(seconds) % 60
      let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
      contentDesc = "DURATION: \(hours)h \(minutes)m \(secs)s \(ms)ms (raw: \(seconds) seconds)"

    case .formulaError:
      contentDesc = "FORMULA_ERROR: Calculation resulted in error"
    }

    log("Type: \(contentDesc)")

    if case .richText(let elements, _) = content {
      log("")
      log("Rich Text Content:")
      indentLevel += 1
      for element in elements {
        logInlineElement(element, context: .cell)
      }
      indentLevel -= 1
    }

    if let metadata = content.metadata {
      log("")
      logCellMetadata(metadata)
    }

    indentLevel -= 1
    log("")
  }

  // MARK: - Cell Metadata Logging

  private func logCellMetadata(_ metadata: CellStorageMetadata) {
    log("Storage Metadata:")
    indentLevel += 1

    log("Format Version: \(metadata.version)")
    log("Cell Type Code: \(formatCellType(metadata.cellType))")
    log("Flags Bitfield: 0x\(String(format: "%08X", metadata.flags))")
    log("Extras Field:   0x\(String(format: "%04X", metadata.extras))")

    var hasDataSection = false
    if let d128 = metadata.decimal128 {
      if !hasDataSection {
        log("")
        log("Numeric Data:")
        indentLevel += 1
        hasDataSection = true
      }
      log("Decimal128: \(d128)")
    }
    if let double = metadata.double {
      if !hasDataSection {
        log("")
        log("Numeric Data:")
        indentLevel += 1
        hasDataSection = true
      }
      log("Double:     \(double)")
    }
    if let seconds = metadata.seconds {
      if !hasDataSection {
        log("")
        log("Numeric Data:")
        indentLevel += 1
        hasDataSection = true
      }
      log("Seconds:    \(seconds)")
    }
    if hasDataSection {
      indentLevel -= 1
    }

    if metadata.stringId != nil || metadata.richTextId != nil {
      log("")
      log("Content References:")
      indentLevel += 1
      if let stringId = metadata.stringId {
        log("String ID:    \(stringId)")
      }
      if let richTextId = metadata.richTextId {
        log("Rich Text ID: \(richTextId)")
      }
      indentLevel -= 1
    }

    if metadata.cellStyleId != nil || metadata.textStyleId != nil {
      log("")
      log("Style References:")
      indentLevel += 1
      if let cellStyleId = metadata.cellStyleId {
        log("Cell Style ID: \(cellStyleId)")
      }
      if let textStyleId = metadata.textStyleId {
        log("Text Style ID: \(textStyleId)")
      }
      indentLevel -= 1
    }

    if let formulaId = metadata.formulaId {
      log("")
      log("Formula:")
      indentLevel += 1
      log("Formula ID: \(formulaId)")
      log("Note: Cell value is computed from formula")
      indentLevel -= 1
    }

    if let controlId = metadata.controlId {
      log("")
      log("Interactive Control:")
      indentLevel += 1
      log("Control ID: \(controlId)")
      log("Note: Cell contains interactive UI element")
      indentLevel -= 1
    }

    if let suggestId = metadata.suggestId {
      log("")
      log("Suggestion ID: \(suggestId)")
    }

    let formatIds = [
      ("Number Format", metadata.numFormatId),
      ("Currency Format", metadata.currencyFormatId),
      ("Date Format", metadata.dateFormatId),
      ("Duration Format", metadata.durationFormatId),
      ("Text Format", metadata.textFormatId),
      ("Boolean Format", metadata.boolFormatId),
    ].compactMap { name, id in
      id.map { (name, $0) }
    }

    if !formatIds.isEmpty {
      log("")
      log("Format References:")
      indentLevel += 1
      for (name, id) in formatIds {
        log("\(name): \(id)")
      }
      indentLevel -= 1
    }

    if let currencyFormat = metadata.currencyFormat {
      log("")
      log("Currency Format:")
      indentLevel += 1
      log("Code: \(currencyFormat.code)")
      log("Symbol: \(currencyFormat.displaySymbol)")
      log(
        "Decimal Places: \(currencyFormat.usesAutomaticDecimalPlaces ? "automatic" : String(currencyFormat.decimalPlaces))"
      )
      log("Show Symbol: \(currencyFormat.showSymbol ? "yes" : "no")")
      log("Accounting Style: \(currencyFormat.useAccountingStyle ? "yes" : "no")")
      indentLevel -= 1
    }

    if let border = metadata.border {
      log("")
      logCellBorder(border)
    }

    if let cellStyle = metadata.cellStyle {
      log("")
      logCellStyleInfo(cellStyle)
    }

    if let textStyle = metadata.textStyle {
      log("")
      logTextStyleInfo(textStyle)
    }

    var features: [String] = []
    if metadata.hasFormula {
      features.append("COMPUTED")
    }
    if metadata.hasCustomFormatting {
      features.append("CUSTOM_FORMAT")
    }
    if metadata.hasControl {
      features.append("INTERACTIVE")
    }
    if metadata.hasBorders {
      features.append("BORDERED")
    }

    if !features.isEmpty {
      log("")
      log("Feature Flags: [\(features.joined(separator: ", "))]")
    }

    indentLevel -= 1
  }

  private func logCellBorder(_ border: CellBorder) {
    guard border.hasBorders else { return }

    log("Cell Borders:")
    indentLevel += 1

    if let top = border.top {
      log("Top:    \(formatBorder(top))")
    }
    if let right = border.right {
      log("Right:  \(formatBorder(right))")
    }
    if let bottom = border.bottom {
      log("Bottom: \(formatBorder(bottom))")
    }
    if let left = border.left {
      log("Left:   \(formatBorder(left))")
    }

    indentLevel -= 1
  }

  private func logCellStyleInfo(_ cellStyle: CellStyle) {
    log("Cell Styling:")
    indentLevel += 1

    if let bgColor = cellStyle.backgroundColor {
      log(
        "Background Color: rgba(\(bgColor.red), \(bgColor.green), \(bgColor.blue), \(bgColor.alpha))"
      )
    }

    if let gradient = cellStyle.backgroundGradient {
      log("Background Gradient: \(gradient.count) color stops")
      indentLevel += 1
      for (i, color) in gradient.enumerated() {
        log("Stop[\(i)]: rgba(\(color.red), \(color.green), \(color.blue), \(color.alpha))")
      }
      indentLevel -= 1
    }

    log("Vertical Alignment: \(formatVerticalAlignment(cellStyle.verticalAlignment))")
    log("Text Wrapping: \(cellStyle.textWrap ? "enabled" : "disabled")")
    log("Padding:")
    indentLevel += 1
    log("Top:    \(cellStyle.padding.top) pt")
    log("Right:  \(cellStyle.padding.right) pt")
    log("Bottom: \(cellStyle.padding.bottom) pt")
    log("Left:   \(cellStyle.padding.left) pt")
    indentLevel -= 1

    indentLevel -= 1
  }

  private func logTextStyleInfo(_ textStyle: CharacterStyle) {
    log("Text Styling:")
    indentLevel += 1
    logCharacterStyleDetails(textStyle)
    indentLevel -= 1
  }

  // MARK: - Floating Shapes

  public func willVisitShape(info: ShapeInfo, spatialInfo: SpatialInfo) {
    logBoxTop("SHAPE")
    indentLevel += 1

    log("Shape Properties:")

    if let name = info.userDefinedName {
      log("  User Name: \(name)")
    }

    if let key = info.localizationKey {
      log("  System Shape: \(key)")
    }

    if let hyperlink = info.hyperlink {
      log("  Hyperlink: \(hyperlink.url)")
    }

    log("")
    log("Path Geometry:")
    indentLevel += 1
    logPathSource(info.path)
    indentLevel -= 1

    log("")
    log("Style:")
    indentLevel += 1
    logShapeStyle(info.style)
    indentLevel -= 1

    var transforms: [String] = []
    if info.isHorizontallyFlipped {
      transforms.append("horizontal-flip")
    }
    if info.isVerticallyFlipped {
      transforms.append("vertical-flip")
    }

    if !transforms.isEmpty {
      log("")
      log("Transforms: \(transforms.joined(separator: ", "))")
    }

    logTitleAndCaption(title: info.title, caption: info.caption)

    log("")
    logSpatialInfo(spatialInfo, label: "Shape Position")
    log("")
  }

  public func didVisitShape() {
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  // MARK: - Groups

  public func willVisitGroup(spatialInfo: SpatialInfo) {
    logBoxTop("GROUP")
    indentLevel += 1

    logSpatialInfo(spatialInfo, label: "Group Bounds")
    log("")
    log("Group Members:")
    indentLevel += 1
  }

  public func didVisitGroup() {
    indentLevel -= 1
    indentLevel -= 1
    logBoxBottom()
    log("")
  }

  // MARK: - Shared Helper Methods

  private func logTitleAndCaption(title: CaptionData?, caption: CaptionData?) {
    if let title = title {
      log("")
      log("Title Caption:")
      indentLevel += 1
      log("Text: \(title.text)")
      if let style = title.style {
        logCharacterStyleBrief(style)
      }
      logSpatialInfo(title.spatialInfo, label: "Title Position")
      indentLevel -= 1
    }

    if let caption = caption {
      log("")
      log("Caption:")
      indentLevel += 1
      log("Text: \(caption.text)")
      if let style = caption.style {
        logCharacterStyleBrief(style)
      }
      logSpatialInfo(caption.spatialInfo, label: "Caption Position")
      indentLevel -= 1
    }
  }

  // MARK: - Paragraph Formatting Helper

  private func logParagraphFormatting(_ style: ParagraphStyle, spatialInfo: SpatialInfo?) {
    log("Paragraph Formatting:")
    indentLevel += 1
    log("Alignment: \(formatAlignment(style.alignment))")

    log("Indentation:")
    indentLevel += 1
    log("Left:       \(style.leftIndent) pt")
    log("Right:      \(style.rightIndent) pt")
    log("First Line: \(style.firstLineIndent) pt")
    indentLevel -= 1

    log("Spacing:")
    indentLevel += 1
    log("Before: \(style.spaceBefore) pt")
    log("After:  \(style.spaceAfter) pt")
    indentLevel -= 1

    if let lineSpacing = style.lineSpacing {
      log("Line Spacing: \(formatLineSpacing(lineSpacing))")
    }

    if let tabs = style.tabs, !tabs.isEmpty {
      log("Tab Stops: (\(tabs.count) defined)")
      indentLevel += 1
      for (i, tab) in tabs.enumerated() {
        let leaderStr = tab.leader.map { ", leader: '\($0)'" } ?? ""
        log(
          "[\(i)] position=\(tab.position) pt, alignment=\(formatTabAlignment(tab.alignment))\(leaderStr)"
        )
      }
      indentLevel -= 1
    }

    if let defaultTab = style.defaultTabInterval {
      log("Default Tab Interval: \(defaultTab) pt")
    }

    if let border = style.border {
      log("Border:")
      indentLevel += 1
      log("Style:  \(formatBorderStyle(border.stroke.style))")
      log("Width:  \(border.stroke.width) pt")
      log(
        "Color:  rgba(\(border.stroke.color.red), \(border.stroke.color.green), \(border.stroke.color.blue), \(border.stroke.color.alpha))"
      )
      log("Edges:  \(formatBorderEdges(border.edges))")
      log("Rounded: \(border.hasRoundedCorners ? "yes" : "no")")
      indentLevel -= 1
    }

    if let level = style.outlineLevel {
      log("Outline Level: \(level)")
    }

    var flowControls: [String] = []
    if style.keepLinesTogether {
      flowControls.append("keep-lines-together")
    }
    if style.keepWithNext {
      flowControls.append("keep-with-next")
    }
    if style.pageBreakBefore {
      flowControls.append("page-break-before")
    }
    if !style.widowControl {
      flowControls.append("widow-control-disabled")
    }
    if !flowControls.isEmpty {
      log("Flow Control: \(flowControls.joined(separator: ", "))")
    }

    if let direction = style.writingDirection {
      log("Writing Direction: \(formatWritingDirection(direction))")
    }

    indentLevel -= 1

    if let spatial = spatialInfo {
      log("")
      logSpatialInfo(spatial, label: "Position")
    }
  }

  // MARK: - Path Source Helpers

  private func logPathSource(_ pathSource: PathSource) {
    switch pathSource {
    case .point(let pointPath):
      log("Type: POINT-BASED SHAPE")
      log("Shape Type: \(formatPointType(pointPath.type))")
      log("Natural Size: \(formatSize(pointPath.naturalSize))")
      log("Point: (\(pointPath.point.x), \(pointPath.point.y))")

    case .scalar(let scalarPath):
      log("Type: SCALAR-BASED SHAPE")
      log("Shape Type: \(formatScalarType(scalarPath.type))")
      log("Natural Size: \(formatSize(scalarPath.naturalSize))")
      log("Scalar Value: \(scalarPath.scalar)")
      log("Curve Continuous: \(scalarPath.isCurveContinuous ? "yes" : "no")")

    case .bezier(let bezierPath):
      log("Type: BÉZIER PATH")
      log("Natural Size: \(formatSize(bezierPath.naturalSize))")
      log("Path Elements: \(bezierPath.elements.count)")

      if bezierPath.elements.count <= 20 {
        log("")
        log("Path Data:")
        indentLevel += 1
        for (idx, element) in bezierPath.elements.enumerated() {
          log("[\(idx)] \(formatPathElement(element))")
        }
        indentLevel -= 1
      } else {
        log("(Path has \(bezierPath.elements.count) elements - too many to display)")
      }

    case .callout(let calloutPath):
      log("Type: CALLOUT/SPEECH BUBBLE")
      log("Natural Size: \(formatSize(calloutPath.naturalSize))")
      log("Tail Position: (\(calloutPath.tailPosition.x), \(calloutPath.tailPosition.y))")
      log("Tail Size: \(calloutPath.tailSize) pt")
      log("Corner Radius: \(calloutPath.cornerRadius) pt")
      log("Center Tail: \(calloutPath.centerTail ? "yes" : "no")")

    case .connectionLine(let connectionPath):
      log("Type: CONNECTION LINE")
      log("Connection Type: \(formatConnectionType(connectionPath.type))")
      log("Natural Size: \(formatSize(connectionPath.path.naturalSize))")
      log("Outset From: \(connectionPath.outsetFrom) pt")
      log("Outset To: \(connectionPath.outsetTo) pt")
      log("Path Elements: \(connectionPath.path.elements.count)")

    case .editableBezier(let editablePath):
      log("Type: EDITABLE BÉZIER PATH")
      log("Natural Size: \(formatSize(editablePath.naturalSize))")
      log("Subpaths: \(editablePath.subpaths.count)")

      for (subpathIdx, subpath) in editablePath.subpaths.enumerated() {
        log("")
        log("Subpath[\(subpathIdx)]:")
        indentLevel += 1
        log("Nodes: \(subpath.nodes.count)")
        log("Closed: \(subpath.closed ? "yes" : "no")")

        if subpath.nodes.count <= 10 {
          log("")
          log("Node Data:")
          indentLevel += 1
          for (nodeIdx, node) in subpath.nodes.enumerated() {
            log("[\(nodeIdx)] \(formatNodeType(node.type))")
            indentLevel += 1
            log("Node Point: (\(node.nodePoint.x), \(node.nodePoint.y))")
            log("In Control: (\(node.inControlPoint.x), \(node.inControlPoint.y))")
            log("Out Control: (\(node.outControlPoint.x), \(node.outControlPoint.y))")
            indentLevel -= 1
          }
          indentLevel -= 1
        } else {
          log("(Subpath has \(subpath.nodes.count) nodes - too many to display)")
        }

        indentLevel -= 1
      }
    }
  }

  private func formatPointType(_ type: PointPathSource.PointType) -> String {
    switch type {
    case .leftSingleArrow: return "left single arrow"
    case .rightSingleArrow: return "right single arrow"
    case .doubleArrow: return "double arrow"
    case .star: return "star"
    case .plus: return "plus/cross"
    }
  }

  private func formatScalarType(_ type: ScalarPathSource.ScalarType) -> String {
    switch type {
    case .roundedRectangle: return "rounded rectangle"
    case .regularPolygon: return "regular polygon"
    case .chevron: return "chevron/arrow"
    }
  }

  private func formatConnectionType(_ type: ConnectionLinePathSource.ConnectionType) -> String {
    switch type {
    case .quadratic: return "curved (quadratic)"
    case .orthogonal: return "right-angled (orthogonal)"
    }
  }

  private func formatNodeType(_ type: EditableBezierPathSource.Node.NodeType) -> String {
    switch type {
    case .sharp: return "sharp corner"
    case .bezier: return "bézier (independent handles)"
    case .smooth: return "smooth (symmetric handles)"
    }
  }

  // MARK: - Shape Helpers

  private func logShapeStyle(_ style: ShapeStyle) {
    log("Fill: \(formatShapeFill(style.fill))")

    if let stroke = style.stroke {
      log("Stroke:")
      indentLevel += 1
      log("Width: \(stroke.width) pt")
      log(
        "Color: rgba(\(stroke.color.red), \(stroke.color.green), \(stroke.color.blue), \(stroke.color.alpha))"
      )
      log("Style: \(formatBorderStyle(stroke.style))")
      indentLevel -= 1
    } else {
      log("Stroke: none")
    }

    if style.opacity != 1.0 {
      log("Opacity: \(String(format: "%.2f%%", style.opacity * 100))")
    }

    if let shadow = style.shadow {
      log("Shadow:")
      indentLevel += 1
      log("Offset:      (\(shadow.offsetX), \(shadow.offsetY)) pt")
      log("Blur Radius: \(shadow.blurRadius) pt")
      log(
        "Color:       rgba(\(shadow.color.red), \(shadow.color.green), \(shadow.color.blue), \(shadow.color.alpha))"
      )
      log("Opacity:     \(shadow.opacity)")
      indentLevel -= 1
    }
  }

  private func formatShapeFill(_ fill: ShapeFill) -> String {
    switch fill {
    case .none:
      return "none"
    case .color(let color):
      return "solid color rgba(\(color.red), \(color.green), \(color.blue), \(color.alpha))"
    case .gradient(let colors):
      return "gradient (\(colors.count) stops)"
    case .image(let info):
      return "image (\(info.filename ?? "unknown"))"
    }
  }

  private func formatPathElement(_ element: PathElement) -> String {
    let typeStr: String
    switch element.type {
    case .moveTo:
      typeStr = "moveTo"
    case .lineTo:
      typeStr = "lineTo"
    case .quadCurveTo:
      typeStr = "quadCurveTo"
    case .curveTo:
      typeStr = "curveTo"
    case .closeSubpath:
      typeStr = "closeSubpath"
    }

    if element.points.isEmpty {
      return typeStr
    }

    let pointsStr = element.points.map { "(\($0.x), \($0.y))" }.joined(separator: ", ")
    return "\(typeStr): \(pointsStr)"
  }

  // MARK: - Spatial Info Helper

  private func logSpatialInfo(_ spatial: SpatialInfo, label: String) {
    log("\(label):")
    indentLevel += 1

    log("Coordinate Space: \(formatCoordinateSpace(spatial.coordinateSpace))")
    log("Frame:  \(formatRect(spatial.frame))")
    log("Origin: \(formatPoint(spatial.origin))")
    log("Size:   \(formatSize(spatial.size))")
    log("Center: \(formatPoint(spatial.center))")

    if spatial.rotation != 0 {
      let degrees = spatial.rotation * 180 / .pi
      log(
        "Rotation: \(String(format: "%.6f", spatial.rotation)) rad (\(String(format: "%.2f", degrees)) degrees)"
      )
    } else {
      log("Rotation: none (0 rad)")
    }

    if let z = spatial.zIndex {
      log("Z-Index: \(z) (layer order)")
    }

    if spatial.isAnchoredToText {
      log("Text Flow: anchored (inline with text)")
    }

    if spatial.isFloatingAboveText {
      log("Text Flow: floating (above text)")
    }

    if !spatial.isAnchoredToText && !spatial.isFloatingAboveText {
      log("Text Flow: independent")
    }

    indentLevel -= 1
  }

  private func logCharacterStyleDetails(_ style: CharacterStyle) {
    var styleAttrs: [String] = []
    if style.isBold { styleAttrs.append("bold") }
    if style.isItalic { styleAttrs.append("italic") }
    if style.isUnderline { styleAttrs.append("underline") }
    if style.isStrikethrough { styleAttrs.append("strikethrough") }

    if !styleAttrs.isEmpty {
      log("Attributes: \(styleAttrs.joined(separator: ", "))")
    }

    if let size = style.fontSize {
      log("Font Size: \(size) pt")
    }

    if let font = style.fontName {
      log("Font Name: \(font)")
    }

    if let color = style.color {
      log("Text Color: rgba(\(color.red), \(color.green), \(color.blue), \(color.alpha))")
    }

    if let bgColor = style.backgroundColor {
      log("Background: rgba(\(bgColor.red), \(bgColor.green), \(bgColor.blue), \(bgColor.alpha))")
    }

    if let baselineShift = style.baselineShift {
      let type = baselineShift > 0 ? "superscript" : (baselineShift < 0 ? "subscript" : "baseline")
      log("Baseline Shift: \(baselineShift) pt (\(type))")
    }

    if let shadow = style.shadow {
      log("Text Shadow:")
      indentLevel += 1
      log("Offset:      (\(shadow.offsetX), \(shadow.offsetY)) pt")
      log("Blur Radius: \(shadow.blurRadius) pt")
      log(
        "Color:       rgba(\(shadow.color.red), \(shadow.color.green), \(shadow.color.blue), \(shadow.color.alpha))"
      )
      log("Opacity:     \(shadow.opacity)")
      indentLevel -= 1
    }

    if let tracking = style.tracking {
      log("Letter Tracking: \(tracking) pt")
    }

    if let direction = style.writingDirection {
      log("Writing Direction: \(formatWritingDirection(direction))")
    }
  }

  private func logCharacterStyleBrief(_ style: CharacterStyle) {
    var attrs: [String] = []
    if style.isBold { attrs.append("bold") }
    if style.isItalic { attrs.append("italic") }
    if style.isUnderline { attrs.append("underline") }
    if style.isStrikethrough { attrs.append("strikethrough") }

    if !attrs.isEmpty {
      log("Style: \(attrs.joined(separator: ", "))")
    }

    if let size = style.fontSize {
      log("Font Size: \(size) pt")
    }

    if let font = style.fontName {
      log("Font: \(font)")
    }
  }

  // MARK: - Format Helpers

  private func formatRect(_ rect: CGRect) -> String {
    "(x: \(rect.origin.x), y: \(rect.origin.y), width: \(rect.size.width), height: \(rect.size.height))"
  }

  private func formatPoint(_ point: CGPoint) -> String {
    "(x: \(point.x), y: \(point.y))"
  }

  private func formatSize(_ size: CGSize) -> String {
    "(width: \(size.width), height: \(size.height))"
  }

  private func formatAlignment(_ alignment: TextAlignment) -> String {
    switch alignment {
    case .left: return "left"
    case .center: return "center"
    case .right: return "right"
    case .justified: return "justified"
    case .natural: return "natural (locale-based)"
    }
  }

  private func formatCoordinateSpace(_ space: CoordinateSpace) -> String {
    switch space {
    case .pageBody: return "page body"
    case .slide: return "slide canvas"
    case .sheet: return "sheet canvas"
    case .floating: return "floating layer"
    }
  }

  private func formatBorder(_ border: Border) -> String {
    "\(formatBorderStyle(border.style)), width=\(border.width) pt, color=rgba(\(border.color.red), \(border.color.green), \(border.color.blue), \(border.color.alpha))"
  }

  private func formatBorderStyle(_ style: BorderStyle) -> String {
    switch style {
    case .solid: return "solid"
    case .dashes: return "dashes"
    case .dots: return "dots"
    case .none: return "none"
    }
  }

  private func formatBorderEdges(_ edges: ParagraphBorder.BorderEdges) -> String {
    var parts: [String] = []
    if edges.contains(.top) { parts.append("top") }
    if edges.contains(.right) { parts.append("right") }
    if edges.contains(.bottom) { parts.append("bottom") }
    if edges.contains(.left) { parts.append("left") }
    return parts.isEmpty ? "none" : parts.joined(separator: ", ")
  }

  private func formatVerticalAlignment(_ alignment: CellStyle.VerticalAlignment) -> String {
    switch alignment {
    case .top: return "top"
    case .middle: return "middle"
    case .bottom: return "bottom"
    }
  }

  private func formatCellType(_ type: UInt8) -> String {
    switch type {
    case 1: return "Empty (1)"
    case 2: return "Number (2)"
    case 3: return "Text (3)"
    case 4: return "Date (4)"
    case 5: return "Boolean (5)"
    case 6: return "Duration (6)"
    case 7: return "Error (7)"
    case 8: return "RichText (8)"
    case 9: return "Automatic (9)"
    case 10: return "Currency (10)"
    default: return "Unknown (\(type))"
    }
  }

  private func formatLineSpacing(_ lineSpacing: LineSpacingMode) -> String {
    switch lineSpacing {
    case .relative(let value):
      return "relative (\(value)x line height)"
    case .minimum(let value):
      return "minimum (\(value) pt)"
    case .exact(let value):
      return "exact (\(value) pt)"
    case .maximum(let value):
      return "maximum (\(value) pt)"
    case .between(let value):
      return "between lines (\(value) pt)"
    }
  }

  private func formatTabAlignment(_ alignment: TabStop.TabAlignment) -> String {
    switch alignment {
    case .left: return "left"
    case .center: return "center"
    case .right: return "right"
    case .decimal: return "decimal"
    }
  }

  private func formatWritingDirection(_ direction: WritingDirection) -> String {
    switch direction {
    case .natural: return "natural (locale-based)"
    case .leftToRight: return "left-to-right"
    case .rightToLeft: return "right-to-left"
    }
  }

  private func formatListNumberStyle(_ style: ListStyle.ListNumberStyle) -> String {
    switch style {
    case .numeric: return "numeric: 1. 2. 3."
    case .numericParen: return "numeric-paren: 1) 2) 3)"
    case .numericDoubleParen: return "numeric-double-paren: (1) (2) (3)"
    case .romanUpper: return "roman-upper: I. II. III."
    case .romanUpperParen: return "roman-upper-paren: I) II) III)"
    case .romanUpperDoubleParen: return "roman-upper-double-paren: (I) (II) (III)"
    case .romanLower: return "roman-lower: i. ii. iii."
    case .romanLowerParen: return "roman-lower-paren: i) ii) iii)"
    case .romanLowerDoubleParen: return "roman-lower-double-paren: (i) (ii) (iii)"
    case .alphaUpper: return "alpha-upper: A. B. C."
    case .alphaUpperParen: return "alpha-upper-paren: A) B) C)"
    case .alphaUpperDoubleParen: return "alpha-upper-double-paren: (A) (B) (C)"
    case .alphaLower: return "alpha-lower: a. b. c."
    case .alphaLowerParen: return "alpha-lower-paren: a) b) c)"
    case .alphaLowerDoubleParen: return "alpha-lower-double-paren: (a) (b) (c)"
    }
  }

  private func formatRenderedListNumber(_ number: Int, style: ListStyle.ListNumberStyle) -> String {
    switch style {
    case .numeric:
      return "\(number)."
    case .numericParen:
      return "\(number))"
    case .numericDoubleParen:
      return "(\(number))"
    case .romanUpper:
      return "\(intToRoman(number).uppercased())."
    case .romanUpperParen:
      return "\(intToRoman(number).uppercased()))"
    case .romanUpperDoubleParen:
      return "(\(intToRoman(number).uppercased()))"
    case .romanLower:
      return "\(intToRoman(number).lowercased())."
    case .romanLowerParen:
      return "\(intToRoman(number).lowercased()))"
    case .romanLowerDoubleParen:
      return "(\(intToRoman(number).lowercased()))"
    case .alphaUpper:
      return "\(intToAlpha(number).uppercased())."
    case .alphaUpperParen:
      return "\(intToAlpha(number).uppercased()))"
    case .alphaUpperDoubleParen:
      return "(\(intToAlpha(number).uppercased()))"
    case .alphaLower:
      return "\(intToAlpha(number).lowercased())."
    case .alphaLowerParen:
      return "\(intToAlpha(number).lowercased()))"
    case .alphaLowerDoubleParen:
      return "(\(intToAlpha(number).lowercased()))"
    }
  }

  private func intToRoman(_ num: Int) -> String {
    let values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
    let numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
    var result = ""
    var number = num

    for (i, value) in values.enumerated() {
      while number >= value {
        result += numerals[i]
        number -= value
      }
    }

    return result
  }

  private func intToAlpha(_ num: Int) -> String {
    guard num > 0 && num <= 26 else { return "?" }
    let char = UnicodeScalar(64 + num)!
    return String(Character(char))
  }
}
