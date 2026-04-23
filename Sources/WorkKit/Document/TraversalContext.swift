import Collections
import CoreFoundation
import Foundation
import RegexBuilder
import SwiftProtobuf
import ZIPFoundation

// MARK: - Traversal Context

/// Walks through an iWork document structure and invokes visitor callbacks for each element.
///
/// Maintains state during traversal including z-order indices for layering, hyperlink ranges
/// for the current text storage, and list numbering across paragraphs.
package final class TraversalContext<V: IWorkDocumentVisitor, O: OCRProvider> {
  let document: IWorkDocument
  let visitor: V
  let ocrProvider: O?

  private var currentZOrderMap: OrderedDictionary<UInt64, Int> = [:]
  private var currentHyperlinks: [(range: Range<Int>, url: String)] = []
  private var listCounters: OrderedDictionary<String, OrderedDictionary<Int, Int>> = [:]
  private var currentListStyleKey: String?

  init(
    document: IWorkDocument,
    visitor: V,
    ocrProvider: O?
  ) {
    self.document = document
    self.visitor = visitor
    self.ocrProvider = ocrProvider
  }

  // MARK: - Main Traversal Entry Point

  /// Traverses the entire document, calling visitor methods for each discovered element.
  ///
  /// - Throws: Errors from visitor callbacks or document structure issues.
  func traverse() async throws {
    let layout = parseDocumentLayout()
    let pageSettings: PageSettings?
    if document.type == .pages {
      pageSettings = parsePageSettings()
    } else {
      pageSettings = nil
    }

    await visitor.willVisitDocument(type: document.type, layout: layout, pageSettings: pageSettings)

    switch document.type {
    case .pages:
      try await traversePages(layout: layout)
    case .numbers:
      try await traverseNumbers()
    case .keynote:
      try await traverseKeynote()
    }

    await visitor.didVisitDocument(type: document.type)
  }

  // MARK: - Settings Parsing

  /// Parses page settings from the document archive.
  ///
  /// - Returns: Page settings, or `nil` if unavailable.
  private func parsePageSettings() -> PageSettings? {
    guard let docArchive: TP_DocumentArchive = document.record(id: 1) else {
      return nil
    }

    guard docArchive.hasSettings else {
      return nil
    }

    guard let settingsArchive: TP_SettingsArchive = document.dereference(docArchive.settings) else {
      return nil
    }

    let footnoteKind: PageSettings.FootnoteKind
    switch settingsArchive.footnoteKind {
    case .kFootnoteKindFootnotes:
      footnoteKind = .footnotes
    case .kFootnoteKindDocumentEndnotes:
      footnoteKind = .documentEndnotes
    case .kFootnoteKindSectionEndnotes:
      footnoteKind = .sectionEndnotes
    }

    let footnoteFormat: PageSettings.FootnoteFormat
    switch settingsArchive.footnoteFormat {
    case .kFootnoteFormatNumeric:
      footnoteFormat = .numeric
    case .kFootnoteFormatRoman:
      footnoteFormat = .roman
    case .kFootnoteFormatSymbolic:
      footnoteFormat = .symbolic
    case .kFootnoteFormatJapaneseNumeric:
      footnoteFormat = .japaneseNumeric
    case .kFootnoteFormatJapaneseIdeographic:
      footnoteFormat = .japaneseIdeographic
    case .kFootnoteFormatArabicNumeric:
      footnoteFormat = .arabicNumeric
    }

    let footnoteNumbering: PageSettings.FootnoteNumbering
    switch settingsArchive.footnoteNumbering {
    case .kFootnoteNumberingContinuous:
      footnoteNumbering = .continuous
    case .kFootnoteNumberingRestartEachPage:
      footnoteNumbering = .restartEachPage
    case .kFootnoteNumberingRestartEachSection:
      footnoteNumbering = .restartEachSection
    }

    return PageSettings(
      hyphenation: settingsArchive.hyphenation,
      useLigatures: settingsArchive.useLigatures,
      decimalTab: settingsArchive.decimalTab,
      language: settingsArchive.language,
      creationLocale: settingsArchive.creationLocale,
      templateName: settingsArchive.origTemplate,
      creationDate: settingsArchive.hasCreationDate ? settingsArchive.creationDate : nil,
      footnoteKind: footnoteKind,
      footnoteFormat: footnoteFormat,
      footnoteNumbering: footnoteNumbering,
      footnoteGap: Double(settingsArchive.footnoteGap),
      facingPages: settingsArchive.facingPages
    )
  }

  /// Parses page dimensions and margins from the document archive.
  ///
  /// - Returns: Layout information, or `nil` if the document archive is unavailable.
  private func parseDocumentLayout() -> DocumentLayout? {
    guard let docArchive: TP_DocumentArchive = document.record(id: 1) else {
      return nil
    }

    return DocumentLayout(
      pageWidth: Double(docArchive.pageWidth),
      pageHeight: Double(docArchive.pageHeight),
      leftMargin: Double(docArchive.leftMargin),
      rightMargin: Double(docArchive.rightMargin),
      topMargin: Double(docArchive.topMargin),
      bottomMargin: Double(docArchive.bottomMargin),
      headerMargin: Double(docArchive.headerMargin),
      footerMargin: Double(docArchive.footerMargin),
      orientation: docArchive.orientation
    )
  }

  // MARK: - Pages Document Traversal

  /// Traverses a Pages document, visiting sections, body text, and floating drawables.
  ///
  /// - Parameter layout: Page dimensions and margins.
  /// - Throws: Errors from processing document elements.
  private func traversePages(layout: DocumentLayout?) async throws {
    guard
      let docArchive: TP_DocumentArchive = document.firstRecord(ofType: TP_DocumentArchive.self)?
        .record
    else {
      return
    }

    guard let bodyStorage: TSWP_StorageArchive = document.dereference(docArchive.bodyStorage) else {
      return
    }

    let contentRect = layout?.contentRect ?? CGRect(x: 0, y: 0, width: 612, height: 792)

    if docArchive.hasDrawablesZorder {
      buildZOrderMap(from: docArchive.drawablesZorder)
    }

    if docArchive.hasSection {
      guard let sectionRef = docArchive.section as TSP_Reference? else {
        return
      }

      guard let section: TP_SectionArchive = document.dereference(sectionRef) else {
        return
      }

      try await processSection(section, contentRect: contentRect)
    }

    await visitor.willVisitPagesBody(contentRect: contentRect)
    try await traverseStorage(
      bodyStorage,
      coordinateSpace: .pageBody,
      containerInfo: nil,
      tableContext: nil
    )
    await visitor.didVisitPagesBody()

    if docArchive.hasFloatingDrawables {
      guard let floatingRef = docArchive.floatingDrawables as TSP_Reference? else {
        return
      }

      guard let floating: TP_FloatingDrawablesArchive = document.dereference(floatingRef) else {
        return
      }

      let sortedDrawables = parseFloatingDrawables(from: floating)
      let drawableRefs = sortedDrawables.map { $0.0 }
      let positionSorted = sortDrawablesByPosition(drawableRefs)
      for drawableRef in positionSorted {
        try await traverseDrawable(drawableRef, coordinateSpace: .floating, containerInfo: nil)
      }
    }
  }

  /// Processes headers, footers, and page templates within a document section.
  ///
  /// - Parameters:
  ///   - section: The section containing template pages and legacy header/footer storage.
  ///   - contentRect: The content area bounds for layout calculations.
  /// - Throws: Errors from processing section elements.
  private func processSection(
    _ section: TP_SectionArchive,
    contentRect: CGRect
  ) async throws {
    for headerRef in section.obsoleteHeaders {
      guard let headerStorage: TSWP_StorageArchive = document.dereference(headerRef) else {
        continue
      }

      try await traverseStorage(
        headerStorage,
        coordinateSpace: .pageBody,
        containerInfo: nil,
        tableContext: nil
      )
    }

    for footerRef in section.obsoleteFooters {
      guard let footerStorage: TSWP_StorageArchive = document.dereference(footerRef) else {
        continue
      }

      try await traverseStorage(
        footerStorage,
        coordinateSpace: .pageBody,
        containerInfo: nil,
        tableContext: nil
      )
    }

    if section.hasFirstSectionTemplatePage {
      guard let templateRef = section.firstSectionTemplatePage as TSP_Reference? else {
        return
      }

      guard let templatePage: TP_PageTemplateArchive = document.dereference(templateRef) else {
        return
      }

      try await processPageTemplate(templatePage)
    }

    if section.hasOddSectionTemplatePage {
      guard let templateRef = section.oddSectionTemplatePage as TSP_Reference? else {
        return
      }

      guard let templatePage: TP_PageTemplateArchive = document.dereference(templateRef) else {
        return
      }

      try await processPageTemplate(templatePage)
    }

    if section.hasEvenSectionTemplatePage {
      guard let templateRef = section.evenSectionTemplatePage as TSP_Reference? else {
        return
      }

      guard let templatePage: TP_PageTemplateArchive = document.dereference(templateRef) else {
        return
      }

      try await processPageTemplate(templatePage)
    }
  }

  /// Processes background elements and placeholders from a page template.
  ///
  /// - Parameter template: The page template containing decorative and placeholder drawables.
  /// - Throws: Errors from processing template drawables.
  private func processPageTemplate(_ template: TP_PageTemplateArchive) async throws {
    for drawableRef in template.sectionTemplateDrawables {
      try await traverseDrawable(drawableRef, coordinateSpace: .pageBody, containerInfo: nil)
    }

    for tagDrawablePair in template.placeholderDrawables {
      guard tagDrawablePair.hasDrawable else {
        continue
      }

      try await traverseDrawable(
        tagDrawablePair.drawable,
        coordinateSpace: .pageBody,
        containerInfo: nil
      )
    }
  }

  /// Collects floating drawables from all page groups and sorts them by z-index for rendering
  /// order.
  ///
  /// - Parameter floating: Archive containing background, foreground, and generic drawable groups.
  /// - Returns: Drawable references paired with their z-indices, sorted from back to front.
  private func parseFloatingDrawables(
    from floating: TP_FloatingDrawablesArchive
  ) -> [(TSP_Reference, Int)] {
    var allDrawables: [(TSP_Reference, Int)] = []

    for pageGroup in floating.pageGroups {
      for drawableEntry in pageGroup.backgroundDrawables {
        guard drawableEntry.hasDrawable else {
          continue
        }

        let ref = drawableEntry.drawable
        let zIndex = ref.hasIdentifier ? (getZIndex(for: ref.identifier) ?? Int.max) : Int.max
        allDrawables.append((ref, zIndex))
      }

      for drawableEntry in pageGroup.foregroundDrawables {
        guard drawableEntry.hasDrawable else {
          continue
        }

        let ref = drawableEntry.drawable
        let zIndex = ref.hasIdentifier ? (getZIndex(for: ref.identifier) ?? Int.max) : Int.max
        allDrawables.append((ref, zIndex))
      }

      for drawableEntry in pageGroup.drawables {
        guard drawableEntry.hasDrawable else {
          continue
        }

        let ref = drawableEntry.drawable
        let zIndex = ref.hasIdentifier ? (getZIndex(for: ref.identifier) ?? Int.max) : Int.max
        allDrawables.append((ref, zIndex))
      }
    }

    allDrawables.sort { $0.1 < $1.1 }
    return allDrawables
  }

  // MARK: - Numbers Document Traversal

  /// Traverses a Numbers document by visiting each sheet and its drawable contents.
  ///
  /// - Throws: Errors from processing sheets or their drawables.
  private func traverseNumbers() async throws {
    guard
      let docArchive: TN_DocumentArchive = document.firstRecord(ofType: TN_DocumentArchive.self)?
        .record
    else {
      return
    }

    let defaultPageWidth = docArchive.hasPageSize ? Double(docArchive.pageSize.width) : nil
    let defaultPageHeight = docArchive.hasPageSize ? Double(docArchive.pageSize.height) : nil

    for sheetRef in docArchive.sheets {
      guard let sheet: TN_SheetArchive = document.dereference(sheetRef) else {
        continue
      }

      let name = sheet.name
      let layout = parseSheetLayout(
        sheet: sheet,
        defaultPageWidth: defaultPageWidth,
        defaultPageHeight: defaultPageHeight
      )

      await visitor.willVisitSheet(name: name, layout: layout)
      currentZOrderMap.removeAll()

      let sortedDrawables = sortDrawablesByPosition(sheet.drawableInfos)

      for drawableRef in sortedDrawables {
        try await traverseDrawable(drawableRef, coordinateSpace: .sheet, containerInfo: nil)
      }

      await visitor.didVisitSheet(name: name)
    }
  }

  /// Parses layout properties from a Numbers sheet, falling back to document defaults.
  ///
  /// - Parameters:
  ///   - sheet: The sheet archive containing layout properties.
  ///   - defaultPageWidth: Default page width from the document level.
  ///   - defaultPageHeight: Default page height from the document level.
  /// - Returns: Layout properties including page dimensions, margins, and orientation.
  private func parseSheetLayout(
    sheet: TN_SheetArchive,
    defaultPageWidth: Double?,
    defaultPageHeight: Double?
  ) -> SheetLayout {
    let pageWidth = defaultPageWidth
    let pageHeight = defaultPageHeight

    let margins = sheet.hasPrintMargins ? sheet.printMargins : nil
    let topMargin = margins.map { Double($0.top) }
    let leftMargin = margins.map { Double($0.left) }
    let bottomMargin = margins.map { Double($0.bottom) }
    let rightMargin = margins.map { Double($0.right) }

    let isPortrait = sheet.hasInPortraitPageOrientation ? sheet.inPortraitPageOrientation : nil
    let contentScale = sheet.hasContentScale ? Double(sheet.contentScale) : nil
    let headerInset = sheet.hasPageHeaderInset ? Double(sheet.pageHeaderInset) : nil
    let footerInset = sheet.hasPageFooterInset ? Double(sheet.pageFooterInset) : nil

    return SheetLayout(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      topMargin: topMargin,
      leftMargin: leftMargin,
      bottomMargin: bottomMargin,
      rightMargin: rightMargin,
      isPortrait: isPortrait,
      contentScale: contentScale,
      headerInset: headerInset,
      footerInset: footerInset
    )
  }

  // MARK: - Keynote Document Traversal

  /// Traverses a Keynote presentation by visiting each slide and its drawables in reading order.
  ///
  /// Drawables are sorted by spatial position (top-to-bottom, left-to-right) rather than
  /// z-order to provide natural reading order instead of layer stacking order.
  ///
  /// - Throws: Errors from processing slides or their drawables.
  private func traverseKeynote() async throws {
    guard let showArchive = document.firstRecord(ofType: KN_ShowArchive.self)?.record else {
      return
    }

    guard let metadata: TSP_PackageMetadata = document.record(id: 2) else {
      return
    }

    let slideWidth = Double(showArchive.size.width)
    let slideHeight = Double(showArchive.size.height)
    let slideBounds = CGRect(x: 0, y: 0, width: slideWidth, height: slideHeight)

    var slideIDs: [UInt64] = []
    for component in metadata.components {
      guard component.preferredLocator == "Slide" else {
        continue
      }

      slideIDs.append(component.identifier)
    }
    slideIDs.sort()

    for (index, slideID) in slideIDs.enumerated() {
      guard let slide: KN_SlideArchive = document.record(id: slideID) else {
        continue
      }

      await visitor.willVisitSlide(index: index, bounds: slideBounds)

      currentZOrderMap.removeAll()
      buildZOrderMapFromArray(slide.drawablesZOrder)

      let sortedDrawables = sortDrawablesByPosition(slide.drawablesZOrder)

      for drawableRef in sortedDrawables {
        try await traverseDrawable(drawableRef, coordinateSpace: .slide, containerInfo: nil)
      }

      await visitor.didVisitSlide(index: index)
    }
  }

  /// Sorts drawable references by their spatial position for natural reading order.
  ///
  /// Sorts primarily by y-position (top to bottom), then by x-position (left to right).
  ///
  /// - Parameter drawables: Array of drawable references to sort.
  /// - Returns: Sorted array of drawable references in reading order.
  private func sortDrawablesByPosition(_ drawables: [TSP_Reference]) -> [TSP_Reference] {
    return drawables.sorted { refA, refB in
      guard let drawableA = document.dereference(refA),
        let drawableB = document.dereference(refB)
      else {
        return false
      }

      let frameA = parseFrameFromDrawable(drawableA)
      let frameB = parseFrameFromDrawable(drawableB)

      let centerYA = frameA.midY
      let centerYB = frameB.midY

      if centerYA != centerYB {
        return centerYA < centerYB
      }

      // If same Y center, sort by X center
      return frameA.midX < frameB.midX
    }
  }

  //// Parses the frame rectangle from any drawable type.
  ///
  /// For images with masks, returns the mask's frame as it defines the visible bounds.
  ///
  /// - Parameter drawable: The drawable to parse the frame from.
  /// - Returns: Frame rectangle, or zero rect if parsing fails.
  private func parseFrameFromDrawable(_ drawable: Any) -> CGRect {
    switch drawable {
    case let shape as TSWP_ShapeInfoArchive:
      return parseFrame(from: shape.super.super.geometry)

    case let image as TSD_ImageArchive:
      if image.hasMask,
        let maskRef = image.mask as TSP_Reference?,
        let maskArchive: TSD_MaskArchive = document.dereference(maskRef)
      {
        return parseFrame(from: maskArchive.super.geometry)
      }
      return parseFrame(from: image.super.geometry)

    case let table as TST_TableInfoArchive:
      return parseFrame(from: table.super.geometry)

    case let wpTable as TST_WPTableInfoArchive:
      return parseFrame(from: wpTable.super.super.geometry)

    case let group as TSD_GroupArchive:
      return parseFrame(from: group.super.geometry)

    case let movie as TSD_MovieArchive:
      return parseFrame(from: movie.super.geometry)

    case let placeholder as KN_PlaceholderArchive:
      return parseFrame(from: placeholder.super.super.super.geometry)

    case let chart as TSCH_ChartDrawableArchive:
      return parseFrame(from: chart.super.geometry)

    default:
      return .zero
    }
  }

  // MARK: - Z-Order Management

  /// Populates the z-order map from a drawable ordering archive.
  ///
  /// - Parameter zOrderRef: Reference to the z-order archive.
  private func buildZOrderMap(from zOrderRef: TSP_Reference) {
    guard let zOrderArchive: TP_DrawablesZOrderArchive = document.dereference(zOrderRef) else {
      return
    }

    buildZOrderMapFromArray(zOrderArchive.drawables)
  }

  /// Populates the z-order map by indexing drawable identifiers in their array order.
  ///
  /// - Parameter drawables: Array of drawable references.
  private func buildZOrderMapFromArray(_ drawables: [TSP_Reference]) {
    for (index, drawableRef) in drawables.enumerated() {
      guard drawableRef.hasIdentifier else {
        continue
      }

      currentZOrderMap[drawableRef.identifier] = index
    }
  }

  /// Returns the z-index for a drawable identifier.
  ///
  /// - Parameter drawableID: Unique identifier of the drawable.
  /// - Returns: The z-index position, or `nil` if not found in the current map.
  private func getZIndex(for drawableID: UInt64) -> Int? {
    currentZOrderMap[drawableID]
  }

  // MARK: - Storage Traversal (Text Content)

  /// Traverses text storage by processing each paragraph with its inline elements in sequential
  /// order.
  ///
  /// - Parameters:
  ///   - storage: Text storage containing paragraphs and formatting.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - containerInfo: Spatial bounds of the containing shape or cell.
  ///   - tableContext: Table location if this storage is within a table cell.
  /// - Throws: Errors from processing inline elements.
  private func traverseStorage(
    _ storage: TSWP_StorageArchive,
    coordinateSpace: CoordinateSpace,
    containerInfo: SpatialInfo?,
    tableContext: (model: TST_TableModelArchive, row: Int, column: Int)?
  ) async throws {
    guard let text = storage.text.first else {
      await visitor.willVisitParagraph(style: ParagraphStyle(), spatialInfo: containerInfo)
      await visitor.didVisitParagraph()
      return
    }

    let runes = Array(text)
    let paragraphStyles = storage.tableParaStyle.entries

    let allAttachments = parseAttachments(from: storage)
    let smartFields = parseSmartFields(from: storage)
    parseHyperlinks(from: storage)

    let paraDataMap = parseParaDataMap(from: storage)

    var lastParagraphStyleArchive: TSWP_ParagraphStyleArchive?
    var lastListStyleEntry: TSWP_ObjectAttributeTable.ObjectAttribute?

    var activeListStyleKey: String?

    for (paraIndex, paraEntry) in paragraphStyles.enumerated() {
      let paraStart = Int(paraEntry.characterIndex)
      let paraEnd =
        (paraIndex + 1 < paragraphStyles.count)
        ? Int(paragraphStyles[paraIndex + 1].characterIndex)
        : runes.count

      let listLevel = paraDataMap[paraStart]?.level ?? 0

      var paraStyle = buildParagraphStyle(
        from: paraEntry,
        storage: storage,
        lastListStyleEntry: &lastListStyleEntry,
        listLevel: listLevel,
        tableContext: tableContext
      )

      paraStyle.listItemNumber = trackListItemNumber(for: paraStyle)

      let paraStyleArchive = resolveParagraphStyleArchive(
        from: paraEntry,
        storage: storage,
        lastStyle: &lastParagraphStyleArchive,
        tableContext: tableContext
      )

      let isListItem = paraStyle.listStyle != .none

      if isListItem {
        let styleKey = listStyleKey(paraStyle.listStyle)

        if activeListStyleKey != styleKey {
          if activeListStyleKey != nil {
            await visitor.didVisitList()
          }

          await visitor.willVisitList(style: paraStyle.listStyle)
          activeListStyleKey = styleKey
        }

        await visitor.willVisitListItem(
          number: paraStyle.listItemNumber,
          level: paraStyle.listLevel,
          style: paraStyle,
          spatialInfo: containerInfo
        )

        try await processSequentialContent(
          runes: runes,
          range: paraStart..<paraEnd,
          attachments: allAttachments,
          charStyleTable: storage.tableCharStyle,
          smartFields: smartFields,
          paragraphStyle: paraStyleArchive,
          storage: storage,
          coordinateSpace: coordinateSpace
        )

        await visitor.didVisitListItem()

      } else {
        if activeListStyleKey != nil {
          await visitor.didVisitList()
          activeListStyleKey = nil
        }

        await visitor.willVisitParagraph(style: paraStyle, spatialInfo: containerInfo)

        try await processSequentialContent(
          runes: runes,
          range: paraStart..<paraEnd,
          attachments: allAttachments,
          charStyleTable: storage.tableCharStyle,
          smartFields: smartFields,
          paragraphStyle: paraStyleArchive,
          storage: storage,
          coordinateSpace: coordinateSpace
        )

        await visitor.didVisitParagraph()
      }
    }

    if activeListStyleKey != nil {
      await visitor.didVisitList()
    }

    currentHyperlinks.removeAll()
    currentListStyleKey = nil
  }

  /// Checks if an attachment reference is a shape.
  ///
  /// - Parameter reference: The attachment reference to check.
  /// - Returns: True if the attachment is a shape, false otherwise.
  private func isShapeAttachment(_ reference: TSP_Reference) -> Bool {
    guard let attachment = document.dereference(reference),
      let drawableAttachment = attachment as? TSWP_DrawableAttachmentArchive,
      drawableAttachment.hasDrawable
    else {
      return false
    }

    guard let drawable = document.dereference(drawableAttachment.drawable) else {
      return false
    }

    return drawable is TSWP_ShapeInfoArchive
  }

  /// Checks if an attachment reference is a table.
  ///
  /// - Parameter reference: The attachment reference to check.
  /// - Returns: True if the attachment is a table, false otherwise.
  private func isTableAttachment(_ reference: TSP_Reference) -> Bool {
    guard let attachment = document.dereference(reference),
      let drawableAttachment = attachment as? TSWP_DrawableAttachmentArchive,
      drawableAttachment.hasDrawable
    else {
      return false
    }

    guard let drawable = document.dereference(drawableAttachment.drawable) else {
      return false
    }

    return drawable is TST_WPTableInfoArchive || drawable is TST_TableInfoArchive
  }

  /// Processes all inline content (text, attachments, footnotes) in their exact sequential order.
  ///
  /// - Parameters:
  ///   - runes: Character array of the entire text storage.
  ///   - range: Character index range for this paragraph.
  ///   - attachments: All attachments from the storage.
  ///   - charStyleTable: Character style table for formatting overrides.
  ///   - smartFields: Smart fields within the text.
  ///   - paragraphStyle: Base paragraph style for inheriting character properties.
  ///   - storage: Text storage containing footnotes.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Throws: Errors from processing attachments or parsing data.
  private func processSequentialContent(
    runes: [Character],
    range: Range<Int>,
    attachments: [(position: UInt32, reference: TSP_Reference)],
    charStyleTable: TSWP_ObjectAttributeTable,
    smartFields: [(position: UInt32, reference: TSP_Reference)],
    paragraphStyle: TSWP_ParagraphStyleArchive?,
    storage: TSWP_StorageArchive,
    coordinateSpace: CoordinateSpace
  ) async throws {
    var allContent: [PositionedContent] = []

    let textSegments = parseTextSegments(
      runes: runes,
      range: range,
      charStyleTable: charStyleTable,
      smartFields: smartFields,
      paragraphStyle: paragraphStyle
    )

    var currentPosition = range.lowerBound
    for segment in textSegments {
      let hasAttachmentHere = attachments.contains { Int($0.position) == currentPosition }
      if segment.text != "\u{FFFC}" || !hasAttachmentHere {
        allContent.append(
          .inlineElement(
            position: currentPosition,
            element: .text(segment.text, style: segment.style, hyperlink: segment.hyperlink)
          )
        )
      }
      currentPosition += segment.text.count
    }

    let paraAttachments = attachments.filter {
      let pos = Int($0.position)
      return pos >= range.lowerBound && pos < range.upperBound
    }

    for attachment in paraAttachments {
      let position = Int(attachment.position)

      if isTableAttachment(attachment.reference) {
        allContent.append(.table(position: position, reference: attachment.reference))
        continue
      }

      if isShapeAttachment(attachment.reference) {
        allContent.append(.shape(position: position, reference: attachment.reference))
        continue
      }

      if let inlineElement = try await parseInlineAttachment(
        attachment.reference,
        coordinateSpace: coordinateSpace
      ) {
        allContent.append(.inlineElement(position: position, element: inlineElement))
      }
    }

    let footnotesInPara = try await processFootnotesInRange(
      from: storage,
      range: range,
      coordinateSpace: coordinateSpace
    )

    for footnote in footnotesInPara {
      allContent.append(
        .inlineElement(
          position: footnote.positionInTextRun,
          element: .footnoteMarker(footnote)
        )
      )
    }

    allContent.sort { lhs, rhs in
      let posL: Int
      let posR: Int

      switch lhs {
      case .inlineElement(let pos, _): posL = pos
      case .table(let pos, _): posL = pos
      case .shape(let pos, _): posL = pos
      }

      switch rhs {
      case .inlineElement(let pos, _): posR = pos
      case .table(let pos, _): posR = pos
      case .shape(let pos, _): posR = pos
      }

      return posL < posR
    }

    for content in allContent {
      switch content {
      case .inlineElement(_, let element):
        await visitor.visitInlineElement(element)

      case .table(_, let reference):
        try await processInlineTable(reference, coordinateSpace: coordinateSpace)

      case .shape(_, let reference):
        try await processInlineShape(reference, coordinateSpace: coordinateSpace)
      }
    }
  }

  /// Processes an inline shape with full shape callbacks and text content.
  ///
  /// - Parameters:
  ///   - reference: The shape attachment reference.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Throws: Errors from processing the shape.
  private func processInlineShape(
    _ reference: TSP_Reference,
    coordinateSpace: CoordinateSpace
  ) async throws {
    guard let attachment = document.dereference(reference),
      let drawableAttachment = attachment as? TSWP_DrawableAttachmentArchive,
      drawableAttachment.hasDrawable
    else {
      return
    }

    guard let drawable = document.dereference(drawableAttachment.drawable),
      let shapeInfo = drawable as? TSWP_ShapeInfoArchive
    else {
      return
    }

    let drawableID =
      drawableAttachment.drawable.hasIdentifier
      ? drawableAttachment.drawable.identifier
      : nil

    try await processShapeInfo(
      shapeInfo,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID,
      overrideSpatialInfo: nil
    )
  }

  /// Processes an inline table with full table callbacks.
  ///
  /// - Parameters:
  ///   - reference: The table attachment reference.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Throws: Errors from processing the table.
  private func processInlineTable(
    _ reference: TSP_Reference,
    coordinateSpace: CoordinateSpace
  ) async throws {
    guard let attachment = document.dereference(reference),
      let drawableAttachment = attachment as? TSWP_DrawableAttachmentArchive,
      drawableAttachment.hasDrawable
    else {
      return
    }

    guard let drawable = document.dereference(drawableAttachment.drawable) else {
      return
    }

    let drawableID =
      drawableAttachment.drawable.hasIdentifier
      ? drawableAttachment.drawable.identifier
      : nil

    switch drawable {
    case let wpTable as TST_WPTableInfoArchive:
      guard wpTable.super.hasTableModel,
        let model: TST_TableModelArchive = document.dereference(wpTable.super.tableModel)
      else {
        return
      }
      let tableName = model.hasTableName ? model.tableName : nil
      try await processTable(
        model,
        name: tableName,
        drawable: wpTable.super.super,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )

    case let tableInfo as TST_TableInfoArchive:
      guard tableInfo.hasTableModel,
        let model: TST_TableModelArchive = document.dereference(tableInfo.tableModel)
      else {
        return
      }

      let tableName = model.hasTableName ? model.tableName : nil

      try await processTable(
        model,
        name: tableName,
        drawable: tableInfo.super,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )

    default:
      break
    }
  }

  /// Parses simple inline attachments (images, media, 3D objects, and charts) as InlineElements.
  ///
  /// Note: Tables and shapes are processed separately with full callbacks.
  ///
  /// - Parameters:
  ///   - reference: The attachment reference.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: An inline element, or nil if the attachment cannot be processed.
  /// - Throws: Errors from parsing attachment data.
  private func parseInlineAttachment(
    _ reference: TSP_Reference,
    coordinateSpace: CoordinateSpace
  ) async throws -> InlineElement? {
    guard let attachment = document.dereference(reference),
      let drawableAttachment = attachment as? TSWP_DrawableAttachmentArchive,
      drawableAttachment.hasDrawable
    else {
      return nil
    }

    guard let drawable = document.dereference(drawableAttachment.drawable) else {
      return nil
    }

    let drawableID =
      drawableAttachment.drawable.hasIdentifier
      ? drawableAttachment.drawable.identifier
      : nil

    switch drawable {
    case let image as TSD_ImageArchive:
      if let equation = image.equation {
        return .equation(equation)
      }
      guard
        let imageData = try parseImageData(
          from: image,
          coordinateSpace: coordinateSpace,
          drawableID: drawableID
        )
      else {
        return nil
      }

      let ocrResult: OCRResult?

      if let provider = ocrProvider,
        let content = try? readFileFromArchive(path: imageData.filepath),
        let result = try? await provider.recognizeText(in: content, info: imageData.info)
      {
        ocrResult = result
      } else {
        ocrResult = nil
      }

      return .image(
        info: imageData.info,
        spatialInfo: imageData.spatialInfo,
        ocrResult: ocrResult,
        hyperlink: imageData.hyperlink
      )

    case let movie as TSD_MovieArchive:
      if is3DObject(from: movie) {
        guard
          let objectData = try parse3DObjectData(
            from: movie,
            coordinateSpace: coordinateSpace,
            drawableID: drawableID
          )
        else {
          return nil
        }

        return .object3D(
          info: objectData.info,
          spatialInfo: objectData.spatialInfo,
          hyperlink: objectData.info.hyperlink
        )
      }

      guard
        let mediaData = try parseMediaData(
          from: movie,
          coordinateSpace: coordinateSpace,
          drawableID: drawableID
        )
      else {
        return nil
      }

      return .media(
        info: mediaData.info,
        spatialInfo: mediaData.spatialInfo
      )

    case let chart as TSCH_ChartDrawableArchive:
      guard chart.hasTSCH_ChartArchive_unity else {
        return nil
      }

      guard var chartInfo = parseChartInfo(from: chart.TSCH_ChartArchive_unity) else {
        return nil
      }

      chartInfo.title = parseCaptionData(
        from: chart.super.hasTitle ? chart.super.title : nil,
        isHidden: chart.super.titleHidden,
        coordinateSpace: coordinateSpace
      )
      chartInfo.caption = parseCaptionData(
        from: chart.super.hasCaption ? chart.super.caption : nil,
        isHidden: chart.super.captionHidden,
        coordinateSpace: coordinateSpace
      )

      let spatialInfo = parseSpatialInfo(
        from: chart.super,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )

      return .chart(info: chartInfo, spatialInfo: spatialInfo)

    default:
      return nil
    }
  }

  // MARK: - Footnote Processing

  /// Parses inline content elements from a storage.
  ///
  /// - Parameters:
  ///   - storage: The text storage to parse from.
  ///   - coordinateSpace: Coordinate system for spatial positioning of inline elements.
  /// - Returns: Array of inline elements.
  /// - Throws: Errors from processing attachments or text.
  private func parseInlineContentFromStorage(
    _ storage: TSWP_StorageArchive,
    coordinateSpace: CoordinateSpace
  ) async throws -> [InlineElement] {
    guard let text = storage.text.first else {
      return []
    }

    let runes = Array(text)
    let paragraphStyles = storage.tableParaStyle.entries

    let attachments = parseAttachments(from: storage)
    let smartFields = parseSmartFields(from: storage)
    parseHyperlinks(from: storage)

    var inlineContent: [InlineElement] = []
    var lastParagraphStyleArchive: TSWP_ParagraphStyleArchive?

    for (paraIndex, paraEntry) in paragraphStyles.enumerated() {
      let paraStart = Int(paraEntry.characterIndex)
      let paraEnd =
        (paraIndex + 1 < paragraphStyles.count)
        ? Int(paragraphStyles[paraIndex + 1].characterIndex)
        : runes.count

      let paraStyleArchive = resolveParagraphStyleArchive(
        from: paraEntry,
        storage: storage,
        lastStyle: &lastParagraphStyleArchive,
        tableContext: nil
      )

      let textSegments = parseTextSegments(
        runes: runes,
        range: paraStart..<paraEnd,
        charStyleTable: storage.tableCharStyle,
        smartFields: smartFields,
        paragraphStyle: paraStyleArchive
      )

      var allElements: [(position: Int, content: InlineElement)] = []

      var currentPosition = paraStart
      for segment in textSegments {
        let content: InlineElement
        if let hyperlink = segment.hyperlink {
          content = .text(segment.text, style: segment.style, hyperlink: hyperlink)
        } else {
          content = .text(segment.text, style: segment.style, hyperlink: nil)
        }
        allElements.append((position: currentPosition, content: content))
        currentPosition += segment.text.count
      }

      let paraAttachments = attachments.filter {
        Int($0.position) >= paraStart && Int($0.position) < paraEnd
      }

      for (position, attachmentRef) in paraAttachments {
        let attachmentContent = try await parseAttachmentInlineContent(
          attachmentRef,
          coordinateSpace: coordinateSpace
        )
        for content in attachmentContent {
          allElements.append((position: Int(position), content: content))
        }
      }

      allElements.sort { $0.position < $1.position }
      inlineContent.append(contentsOf: allElements.map { $0.content })
    }

    return inlineContent
  }

  /// Parses inline content from attachments within cells or footnotes.
  ///
  /// - Parameters:
  ///   - reference: The attachment reference to parse from.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Array of inline elements.
  /// - Throws: Errors from processing images or other attachments.
  private func parseAttachmentInlineContent(
    _ reference: TSP_Reference,
    coordinateSpace: CoordinateSpace
  ) async throws -> [InlineElement] {
    guard let attachment = document.dereference(reference),
      let drawableAttachment = attachment as? TSWP_DrawableAttachmentArchive,
      drawableAttachment.hasDrawable,
      let drawable = document.dereference(drawableAttachment.drawable),
      let image = drawable as? TSD_ImageArchive
    else {
      return []
    }

    return try await parseInlineContentFromImage(image, coordinateSpace: coordinateSpace)
  }

  /// Parses inline content from an image, handling both equations and regular images.
  ///
  /// - Parameters:
  ///   - image: The image archive to parse from.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Array of inline elements.
  /// - Throws: Errors from processing image data.
  private func parseInlineContentFromImage(
    _ image: TSD_ImageArchive,
    coordinateSpace: CoordinateSpace
  ) async throws -> [InlineElement] {
    if let equation = image.equation {
      return [.equation(equation)]
    }
    guard
      let imageData = try parseImageData(
        from: image,
        coordinateSpace: coordinateSpace,
        drawableID: nil
      )
    else {
      return []
    }

    return [
      .image(
        info: imageData.info,
        spatialInfo: imageData.spatialInfo,
        ocrResult: nil,
        hyperlink: imageData.hyperlink
      )
    ]
  }

  /// Processes footnotes that appear in a text range.
  ///
  /// - Parameters:
  ///   - storage: Text storage containing the footnote table.
  ///   - range: Character range to check for footnotes.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Array of footnotes that appear in the range.
  /// - Throws: Errors from parsing footnote content.
  private func processFootnotesInRange(
    from storage: TSWP_StorageArchive,
    range: Range<Int>,
    coordinateSpace: CoordinateSpace
  ) async throws -> [Footnote] {
    guard storage.hasTableFootnote else {
      return []
    }

    var footnotes: [Footnote] = []

    for (index, entry) in storage.tableFootnote.entries.enumerated() {
      let position = Int(entry.characterIndex)

      guard range.contains(position) else {
        continue
      }

      guard entry.hasObject else {
        continue
      }

      guard
        let footnoteRef: TSWP_FootnoteReferenceAttachmentArchive = document.dereference(
          entry.object)
      else {
        continue
      }

      guard footnoteRef.hasContainedStorage else {
        continue
      }

      guard
        let footnoteStorage: TSWP_StorageArchive = document.dereference(
          footnoteRef.containedStorage)
      else {
        continue
      }

      let inlineContent = try await parseInlineContentFromStorage(
        footnoteStorage,
        coordinateSpace: coordinateSpace
      )

      let footnoteNumber = index + 1

      let footnote = Footnote(
        number: footnoteNumber,
        positionInTextRun: position,
        content: inlineContent
      )

      footnotes.append(footnote)
    }

    return footnotes
  }

  // MARK: - Text Data Parsing

  /// Parses text segments with their styles and hyperlinks from a text range.
  ///
  /// - Parameters:
  ///   - runes: Character array of the entire text storage.
  ///   - range: Character index range for this text run.
  ///   - charStyleTable: Character style table for formatting overrides.
  ///   - smartFields: Smart fields within the text.
  ///   - paragraphStyle: Base paragraph style for inheriting character properties.
  /// - Returns: Array of text segments with their styles and hyperlinks.
  private func parseTextSegments(
    runes: [Character],
    range: Range<Int>,
    charStyleTable: TSWP_ObjectAttributeTable,
    smartFields: [(position: UInt32, reference: TSP_Reference)],
    paragraphStyle: TSWP_ParagraphStyleArchive?
  ) -> [(text: String, style: CharacterStyle, hyperlink: Hyperlink?)] {
    let paragraphChain = StyleResolver.buildParagraphStyleChain(paragraphStyle, document: document)
    let defaultCharStyle = StyleResolver.extractCharacterPropertiesFromParagraphStyle(
      from: paragraphChain
    )

    var segments: [(text: String, style: CharacterStyle, hyperlink: Hyperlink?)] = []

    guard !charStyleTable.entries.isEmpty else {
      let text = String(runes[range])
      let hyperlink = createHyperlink(for: range, text: text)
      segments.append((text: text, style: defaultCharStyle, hyperlink: hyperlink))
      return segments
    }

    var position = range.lowerBound

    for (styleIndex, styleEntry) in charStyleTable.entries.enumerated() {
      let styleStart = Int(styleEntry.characterIndex)

      guard styleStart < range.upperBound else {
        break
      }

      guard styleStart >= range.lowerBound else {
        continue
      }

      let styleEnd: Int
      if styleIndex + 1 < charStyleTable.entries.count {
        styleEnd = min(Int(charStyleTable.entries[styleIndex + 1].characterIndex), range.upperBound)
      } else {
        styleEnd = range.upperBound
      }

      if position < styleStart {
        let text = String(runes[position..<styleStart])
        let hyperlink = createHyperlink(for: position..<styleStart, text: text)
        segments.append((text: text, style: defaultCharStyle, hyperlink: hyperlink))
        position = styleStart
      }

      let text = String(runes[styleStart..<styleEnd])
      let style = resolveCharacterStyle(from: styleEntry, baseParagraphStyle: paragraphStyle)
      let hyperlink = createHyperlink(for: styleStart..<styleEnd, text: text)
      segments.append((text: text, style: style, hyperlink: hyperlink))
      position = styleEnd
    }

    if position < range.upperBound {
      let text = String(runes[position..<range.upperBound])
      let hyperlink = createHyperlink(for: position..<range.upperBound, text: text)
      segments.append((text: text, style: defaultCharStyle, hyperlink: hyperlink))
    }

    return segments
  }

  // MARK: - Style Resolution

  /// Builds paragraph style by resolving the style inheritance chain and parsing properties.
  ///
  /// - Parameters:
  ///   - entry: Paragraph style table entry.
  ///   - storage: Text storage for fallback default styles.
  ///   - lastListStyleEntry: Previously used list style for continuation tracking.
  ///   - listLevel: Indentation level from paragraph data.
  ///   - tableContext: Table location for table-specific default styles.
  /// - Returns: Resolved paragraph style properties.
  private func buildParagraphStyle(
    from entry: TSWP_ObjectAttributeTable.ObjectAttribute,
    storage: TSWP_StorageArchive,
    lastListStyleEntry: inout TSWP_ObjectAttributeTable.ObjectAttribute?,
    listLevel: Int,
    tableContext: (model: TST_TableModelArchive, row: Int, column: Int)?
  ) -> ParagraphStyle {
    var style: TSWP_ParagraphStyleArchive? = document.dereference(
      entry.hasObject ? entry.object : nil
    )

    if style == nil {
      style = findDefaultParagraphStyle(from: storage)
    }

    if style == nil {
      if let context = tableContext {
        style = getDefaultTableTextStyle(
          tableModel: context.model,
          row: context.row,
          column: context.column
        )
      }
    }

    guard let style = style else {
      return ParagraphStyle()
    }

    let chain = StyleResolver.buildParagraphStyleChain(style, document: document)

    let listStyleArchive = resolveListStyleArchive(
      from: entry,
      storage: storage,
      chain: chain,
      lastListStyleEntry: &lastListStyleEntry
    )

    return StyleResolver.extractParagraphProperties(
      from: chain,
      listStyleArchive: listStyleArchive,
      listLevel: listLevel
    )
  }

  /// Resolves the list style archive for a paragraph by checking storage tables and style chain.
  ///
  /// - Parameters:
  ///   - entry: Paragraph style table entry.
  ///   - storage: Text storage containing list style table.
  ///   - chain: Paragraph style inheritance chain.
  ///   - lastListStyleEntry: Previously used list style entry for continuation.
  /// - Returns: List style archive, or `nil` if this paragraph is not part of a list.
  private func resolveListStyleArchive(
    from entry: TSWP_ObjectAttributeTable.ObjectAttribute,
    storage: TSWP_StorageArchive,
    chain: [TSWP_ParagraphStyleArchive],
    lastListStyleEntry: inout TSWP_ObjectAttributeTable.ObjectAttribute?
  ) -> TSWP_ListStyleArchive? {
    if storage.hasTableListStyle {
      for listEntry in storage.tableListStyle.entries {
        guard Int(listEntry.characterIndex) == Int(entry.characterIndex) else {
          continue
        }

        guard listEntry.hasObject else {
          continue
        }

        guard let listStyleRef = listEntry.object as TSP_Reference? else {
          continue
        }

        lastListStyleEntry = listEntry
        return document.dereference(listStyleRef)
      }
    }

    if let lastEntry = lastListStyleEntry {
      guard lastEntry.hasObject else {
        return nil
      }

      guard let listStyleRef = lastEntry.object as TSP_Reference? else {
        return nil
      }

      return document.dereference(listStyleRef)
    }

    for style in chain.reversed() {
      let props = style.paraProperties
      guard props.hasListStyle else {
        continue
      }

      guard let listStyleRef = props.listStyle as TSP_Reference? else {
        continue
      }

      return document.dereference(listStyleRef)
    }

    return nil
  }

  /// Resolves the paragraph style archive, inheriting from previous paragraph or table defaults.
  ///
  /// - Parameters:
  ///   - entry: Paragraph style table entry.
  ///   - storage: Text storage for stylesheet defaults.
  ///   - lastStyle: Previously used paragraph style for inheritance.
  ///   - tableContext: Table location for table-specific defaults.
  /// - Returns: Paragraph style archive, or `nil` if no style is available.
  private func resolveParagraphStyleArchive(
    from entry: TSWP_ObjectAttributeTable.ObjectAttribute,
    storage: TSWP_StorageArchive,
    lastStyle: inout TSWP_ParagraphStyleArchive?,
    tableContext: (model: TST_TableModelArchive, row: Int, column: Int)?
  ) -> TSWP_ParagraphStyleArchive? {
    var paraStyleArchive: TSWP_ParagraphStyleArchive? = document.dereference(
      entry.hasObject ? entry.object : nil
    )

    if paraStyleArchive == nil {
      if let last = lastStyle {
        paraStyleArchive = last
      } else {
        paraStyleArchive = findDefaultParagraphStyle(from: storage)
      }
    }

    if paraStyleArchive == nil {
      if let context = tableContext {
        paraStyleArchive = getDefaultTableTextStyle(
          tableModel: context.model,
          row: context.row,
          column: context.column
        )
      }
    }

    if paraStyleArchive != nil {
      lastStyle = paraStyleArchive
    }

    return paraStyleArchive
  }

  /// Finds the default paragraph style from the storage's stylesheet.
  ///
  /// - Parameter storage: Text storage containing stylesheet reference.
  /// - Returns: First paragraph style in the stylesheet, or `nil` if unavailable.
  private func findDefaultParagraphStyle(
    from storage: TSWP_StorageArchive
  ) -> TSWP_ParagraphStyleArchive? {
    guard storage.hasStyleSheet else {
      return nil
    }

    guard let stylesheetRef = storage.styleSheet as TSP_Reference? else {
      return nil
    }

    guard let stylesheet: TSS_StylesheetArchive = document.dereference(stylesheetRef) else {
      return nil
    }

    for styleRef in stylesheet.styles {
      if let paraStyle: TSWP_ParagraphStyleArchive = document.dereference(styleRef) {
        return paraStyle
      }
    }

    return nil
  }

  /// Gets the default text style for a table cell based on its location.
  ///
  /// Header rows and columns use their specific styles; footer rows have their own style;
  /// all other cells use the body text style.
  ///
  /// - Parameters:
  ///   - tableModel: Table model containing region counts and default styles.
  ///   - row: Zero-based row index.
  ///   - column: Zero-based column index.
  /// - Returns: Default paragraph style for the cell location, or `nil` if unavailable.
  private func getDefaultTableTextStyle(
    tableModel: TST_TableModelArchive,
    row: Int,
    column: Int
  ) -> TSWP_ParagraphStyleArchive? {
    if row < tableModel.numberOfHeaderRows {
      guard tableModel.hasHeaderRowTextStyle else {
        return nil
      }

      return document.dereference(tableModel.headerRowTextStyle)
    }

    if column < tableModel.numberOfHeaderColumns {
      guard tableModel.hasHeaderColumnTextStyle else {
        return nil
      }

      return document.dereference(tableModel.headerColumnTextStyle)
    }

    if tableModel.numberOfFooterRows > 0 {
      let footerStartRow = Int(tableModel.numberOfRows) - Int(tableModel.numberOfFooterRows)
      if row >= footerStartRow {
        guard tableModel.hasFooterRowTextStyle else {
          return nil
        }

        return document.dereference(tableModel.footerRowTextStyle)
      }
    }

    guard tableModel.hasBodyTextStyle else {
      return nil
    }

    return document.dereference(tableModel.bodyTextStyle)
  }

  // MARK: - List Tracking

  /// Tracks list item numbering across paragraphs, incrementing counters for continued lists.
  ///
  /// - Parameter style: Paragraph style containing list formatting.
  /// - Returns: Item number for this list item, or `nil` if not part of a list.
  private func trackListItemNumber(for style: ParagraphStyle) -> Int? {
    if case .none = style.listStyle {
      currentListStyleKey = nil
      return nil
    }

    let styleKey = listStyleKey(style.listStyle)
    let level = style.listLevel

    if listCounters[styleKey] == nil {
      listCounters[styleKey] = [:]
    }

    if currentListStyleKey != styleKey {
      listCounters[styleKey] = [level: 1]
      currentListStyleKey = styleKey
    } else {
      listCounters[styleKey]![level, default: 0] += 1

      let deeperLevels = listCounters[styleKey]!.keys.filter { $0 > level }
      for deeperLevel in deeperLevels {
        listCounters[styleKey]![deeperLevel] = nil
      }
    }

    return listCounters[styleKey]![level]
  }

  /// Generates a unique key for a list style to track numbering continuity.
  ///
  /// - Parameter listStyle: The list style to generate a key for.
  /// - Returns: A unique string key for the list style.
  private func listStyleKey(_ listStyle: ListStyle) -> String {
    switch listStyle {
    case .none:
      return "none"
    case .bullet(let char):
      return "bullet:\(char)"
    case .numbered(let type):
      return "numbered:\(type)"
    }
  }

  /// Resolves character style by merging paragraph defaults with character-specific overrides.
  ///
  /// - Parameters:
  ///   - entry: Character style table entry.
  ///   - baseParagraphStyle: Base paragraph style for inheriting properties.
  /// - Returns: Merged character style with all formatting properties.
  private func resolveCharacterStyle(
    from entry: TSWP_ObjectAttributeTable.ObjectAttribute,
    baseParagraphStyle: TSWP_ParagraphStyleArchive?
  ) -> CharacterStyle {
    let paragraphChain = StyleResolver.buildParagraphStyleChain(
      baseParagraphStyle,
      document: document
    )
    let baseStyle = StyleResolver.extractCharacterPropertiesFromParagraphStyle(from: paragraphChain)

    guard entry.hasObject else {
      return baseStyle
    }

    guard let charStyle: TSWP_CharacterStyleArchive = document.dereference(entry.object) else {
      return baseStyle
    }

    let charChain = StyleResolver.buildCharacterStyleChain(charStyle, document: document)
    let overlayStyle = StyleResolver.extractCharacterPropertiesFromCharacterStyle(from: charChain)
    return StyleResolver.mergeCharacterStyles(base: baseStyle, overlay: overlayStyle)
  }

  // MARK: - Helper Data Collection

  /// Collects attachments from storage and sorts them by position.
  ///
  /// - Parameter storage: Text storage containing attachments.
  /// - Returns: Array of position-reference tuples sorted by position.
  private func parseAttachments(
    from storage: TSWP_StorageArchive
  ) -> [(position: UInt32, reference: TSP_Reference)] {
    var attachments: [(position: UInt32, reference: TSP_Reference)] = []
    for entry in storage.tableAttachment.entries {
      guard entry.hasCharacterIndex else {
        continue
      }

      guard entry.hasObject else {
        continue
      }

      attachments.append((entry.characterIndex, entry.object))
    }
    attachments.sort { $0.position < $1.position }
    return attachments
  }

  /// Collects smart fields from storage and sorts them by position.
  ///
  /// - Parameter storage: Text storage containing smart fields.
  /// - Returns: Array of position-reference tuples sorted by position.
  private func parseSmartFields(
    from storage: TSWP_StorageArchive
  ) -> [(position: UInt32, reference: TSP_Reference)] {
    var smartFields: [(position: UInt32, reference: TSP_Reference)] = []
    for entry in storage.tableSmartfield.entries {
      guard entry.hasCharacterIndex else {
        continue
      }

      guard entry.hasObject else {
        continue
      }

      smartFields.append((entry.characterIndex, entry.object))
    }
    smartFields.sort { $0.position < $1.position }
    return smartFields
  }

  /// Builds a map of paragraph data containing list level information.
  ///
  /// - Parameter storage: Text storage containing paragraph data.
  /// - Returns: Dictionary mapping character positions to level and value tuples.
  private func parseParaDataMap(
    from storage: TSWP_StorageArchive
  ) -> [Int: (level: Int, value: UInt32)] {
    var paraDataMap: [Int: (level: Int, value: UInt32)] = [:]
    for entry in storage.tableParaData.entries {
      paraDataMap[Int(entry.characterIndex)] = (level: Int(entry.first), value: entry.second)
    }
    return paraDataMap
  }

  // MARK: - Hyperlink Parsing

  /// Parses hyperlink fields from storage and caches them for the current text traversal.
  ///
  /// - Parameter storage: Text storage containing hyperlink fields.
  private func parseHyperlinks(from storage: TSWP_StorageArchive) {
    currentHyperlinks.removeAll()

    for entry in storage.tableSmartfield.entries {
      guard entry.hasCharacterIndex else {
        continue
      }

      guard entry.hasObject else {
        continue
      }

      let startIndex = Int(entry.characterIndex)

      guard let hyperlinkField: TSWP_HyperlinkFieldArchive = document.dereference(entry.object)
      else {
        continue
      }

      let url = hyperlinkField.urlRef
      let endIndex = startIndex + 1

      currentHyperlinks.append((range: startIndex..<endIndex, url: url))
    }

    currentHyperlinks.sort { $0.range.lowerBound < $1.range.lowerBound }
  }

  /// Creates a hyperlink if the text range overlaps with any cached hyperlink field.
  ///
  /// - Parameters:
  ///   - range: Character index range of the text.
  ///   - text: Text content for the hyperlink.
  /// - Returns: Hyperlink with URL and display text, or `nil` if no hyperlink applies.
  private func createHyperlink(for range: Range<Int>, text: String) -> Hyperlink? {
    if let hyperlinkInfo = currentHyperlinks.first(where: {
      range.overlaps($0.range) || $0.range.overlaps(range)
    }) {
      return Hyperlink(text: text, url: hyperlinkInfo.url, range: range)
    }
    return nil
  }

  // MARK: - Drawable Traversal

  /// Traverses a drawable by type, dispatching to specialized handlers for images, tables, shapes,
  /// and groups.
  ///
  /// - Parameters:
  ///   - reference: Drawable reference.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - containerInfo: Spatial bounds of the parent container.
  /// - Throws: Errors from processing the drawable.
  private func traverseDrawable(
    _ reference: TSP_Reference,
    coordinateSpace: CoordinateSpace,
    containerInfo: SpatialInfo?
  ) async throws {
    guard let drawable = document.dereference(reference) else {
      return
    }

    let drawableID = reference.hasIdentifier ? reference.identifier : nil

    switch drawable {
    case let image as TSD_ImageArchive:
      try await processImage(image, coordinateSpace: coordinateSpace, drawableID: drawableID)

    case let wpTable as TST_WPTableInfoArchive:
      guard wpTable.super.hasTableModel else {
        return
      }

      guard let model: TST_TableModelArchive = document.dereference(wpTable.super.tableModel) else {
        return
      }

      let tableName = model.hasTableName ? model.tableName : nil

      try await processTable(
        model,
        name: tableName,
        drawable: wpTable.super.super,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )

    case let tableInfo as TST_TableInfoArchive:
      guard tableInfo.hasTableModel else {
        return
      }

      guard let model: TST_TableModelArchive = document.dereference(tableInfo.tableModel) else {
        return
      }

      let tableName = model.hasTableName ? model.tableName : nil

      try await processTable(
        model,
        name: tableName,
        drawable: tableInfo.super,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )

    case let shapeInfo as TSWP_ShapeInfoArchive:
      try await processShapeInfo(
        shapeInfo,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )

    case let group as TSD_GroupArchive:
      try await processGroup(group, coordinateSpace: coordinateSpace, drawableID: drawableID)

    case let movie as TSD_MovieArchive:
      try await processMovie(movie, coordinateSpace: coordinateSpace, drawableID: drawableID)

    case let chart as TSCH_ChartDrawableArchive:
      try await processChart(chart, coordinateSpace: coordinateSpace, drawableID: drawableID)

    case let placeholder as KN_PlaceholderArchive:
      let spatialInfo =
        containerInfo
        ?? parseSpatialInfo(
          from: placeholder.super.super.super,
          coordinateSpace: coordinateSpace,
          drawableID: drawableID
        )
      try await processShapeInfo(
        placeholder.super,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID,
        overrideSpatialInfo: spatialInfo
      )

    default:
      break
    }
  }

  // MARK: - Path Bounds Calculation

  /// Calculates the bounding rectangle from a path source.
  ///
  /// - Parameter pathSource: The path source to calculate bounds from.
  /// - Returns: The bounding rectangle, or nil if it cannot be calculated.
  private func calculateBounds(from pathSource: PathSource) -> CGRect? {
    switch pathSource {
    case .bezier(let bezierPath):
      return calculateBezierPathBounds(bezierPath)

    case .scalar(let scalarPath):
      return CGRect(origin: .zero, size: scalarPath.naturalSize)

    case .point(let pointPath):
      return CGRect(origin: .zero, size: pointPath.naturalSize)

    case .callout(let calloutPath):
      return CGRect(origin: .zero, size: calloutPath.naturalSize)

    case .connectionLine(let connectionPath):
      return calculateBezierPathBounds(connectionPath.path)

    case .editableBezier(let editablePath):
      return CGRect(origin: .zero, size: editablePath.naturalSize)
    }
  }

  private func calculateBounds(from mask: Mask) -> CGRect? {
    guard let pathBounds = calculateBounds(from: mask.path) else {
      return nil
    }
    return pathBounds
  }

  /// Calculates bounds from a Bézier path by examining all path elements.
  ///
  /// - Parameter path: The Bézier path to calculate bounds from.
  /// - Returns: The bounding rectangle containing all path points.
  private func calculateBezierPathBounds(_ path: BezierPath) -> CGRect {
    guard !path.elements.isEmpty else {
      return CGRect(origin: .zero, size: path.naturalSize)
    }

    var minX = Double.infinity
    var minY = Double.infinity
    var maxX = -Double.infinity
    var maxY = -Double.infinity

    for element in path.elements {
      for point in element.points {
        minX = min(minX, point.x)
        minY = min(minY, point.y)
        maxX = max(maxX, point.x)
        maxY = max(maxY, point.y)
      }
    }

    if minX.isInfinite || minY.isInfinite {
      return CGRect(origin: .zero, size: path.naturalSize)
    }

    return CGRect(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY
    )
  }

  // MARK: - Shape Parsing Methods

  private func parseImageMask(from image: TSD_ImageArchive) -> Mask? {
    guard image.hasMask,
      let maskRef = image.mask as TSP_Reference?,
      let maskArchive: TSD_MaskArchive = document.dereference(maskRef)
    else {
      return nil
    }

    let imageGeometry = image.super.geometry  
    let maskGeometry = maskArchive.super.geometry 

    let imageOffset = CGPoint(
      x: CGFloat(imageGeometry.position.x - maskGeometry.position.x),
      y: CGFloat(imageGeometry.position.y - maskGeometry.position.y)
    )

    let imageScale = CGSize(
      width: maskGeometry.size.width > 0
        ? CGFloat(imageGeometry.size.width / maskGeometry.size.width) : 1.0,
      height: maskGeometry.size.height > 0
        ? CGFloat(imageGeometry.size.height / maskGeometry.size.height) : 1.0
    )

    let imageRotation = CGFloat(imageGeometry.angle - maskGeometry.angle)

    var imageTransform = CGAffineTransform.identity
    imageTransform = imageTransform.translatedBy(x: imageOffset.x, y: imageOffset.y)
    imageTransform = imageTransform.rotated(by: imageRotation)
    imageTransform = imageTransform.scaledBy(x: imageScale.width, y: imageScale.height)

    guard let maskPath = parsePathSource(from: maskArchive.pathsource) else {  
      return nil
    }

    return Mask(
      path: maskPath,
      position: CGPoint(x: CGFloat(maskGeometry.position.x), y: CGFloat(maskGeometry.position.y)),
      size: CGSize(
        width: CGFloat(maskGeometry.size.width), height: CGFloat(maskGeometry.size.height)),
      angle: CGFloat(maskGeometry.angle),
      imageTransform: imageTransform
    )
  }

  /// Parses path source from a path source archive, supporting all path types.
  ///
  /// - Parameter pathSource: The path source containing path elements.
  /// - Returns: A path source, or `nil` if parsing fails.
  private func parsePathSource(from pathSource: TSD_PathSourceArchive) -> PathSource? {
    if pathSource.hasPointPathSource {
      let pointSource = pathSource.pointPathSource

      let type: PointPathSource.PointType
      switch pointSource.type {
      case .kTsdleftSingleArrow:
        type = .leftSingleArrow
      case .kTsdrightSingleArrow:
        type = .rightSingleArrow
      case .kTsddoubleArrow:
        type = .doubleArrow
      case .kTsdstar:
        type = .star
      case .kTsdplus:
        type = .plus
      }

      let point = PathPoint(
        x: Double(pointSource.point.x),
        y: Double(pointSource.point.y)
      )

      let naturalSize = CGSize(
        width: CGFloat(pointSource.naturalSize.width),
        height: CGFloat(pointSource.naturalSize.height)
      )

      return .point(
        PointPathSource(
          type: type,
          point: point,
          naturalSize: naturalSize
        ))
    }

    if pathSource.hasScalarPathSource {
      let scalarSource = pathSource.scalarPathSource

      let type: ScalarPathSource.ScalarType
      switch scalarSource.type {
      case .kTsdroundedRectangle:
        type = .roundedRectangle
      case .kTsdregularPolygon:
        type = .regularPolygon
      case .kTsdchevron:
        type = .chevron
      }

      let naturalSize = CGSize(
        width: CGFloat(scalarSource.naturalSize.width),
        height: CGFloat(scalarSource.naturalSize.height)
      )

      return .scalar(
        ScalarPathSource(
          type: type,
          scalar: Double(scalarSource.scalar),
          naturalSize: naturalSize,
          isCurveContinuous: scalarSource.isCurveContinuous
        ))
    }

    if pathSource.hasBezierPathSource {
      guard let bezierPath = parseBezierPath(from: pathSource) else {
        return nil
      }
      return .bezier(bezierPath)
    }

    if pathSource.hasCalloutPathSource {
      let calloutSource = pathSource.calloutPathSource

      let naturalSize = CGSize(
        width: CGFloat(calloutSource.naturalSize.width),
        height: CGFloat(calloutSource.naturalSize.height)
      )

      let tailPosition = PathPoint(
        x: Double(calloutSource.tailPosition.x),
        y: Double(calloutSource.tailPosition.y)
      )

      return .callout(
        CalloutPathSource(
          naturalSize: naturalSize,
          tailPosition: tailPosition,
          tailSize: Double(calloutSource.tailSize),
          cornerRadius: Double(calloutSource.cornerRadius),
          centerTail: calloutSource.centerTail
        ))
    }

    if pathSource.hasConnectionLinePathSource {
      let connectionSource = pathSource.connectionLinePathSource

      let type: ConnectionLinePathSource.ConnectionType
      switch connectionSource.type {
      case .kTsdconnectionLineTypeQuadratic:
        type = .quadratic
      case .kTsdconnectionLineTypeOrthogonal:
        type = .orthogonal
      }

      guard let bezierPath = parseBezierPath(from: pathSource) else {
        return nil
      }

      return .connectionLine(
        ConnectionLinePathSource(
          type: type,
          path: bezierPath,
          outsetFrom: Double(connectionSource.outsetFrom),
          outsetTo: Double(connectionSource.outsetTo)
        ))
    }

    if pathSource.hasEditableBezierPathSource {
      let editableSource = pathSource.editableBezierPathSource

      let naturalSize = CGSize(
        width: CGFloat(editableSource.naturalSize.width),
        height: CGFloat(editableSource.naturalSize.height)
      )

      let subpaths = editableSource.subpaths.map { subpathArchive in
        let nodes = subpathArchive.nodes.map { nodeArchive in
          let nodeType: EditableBezierPathSource.Node.NodeType
          switch nodeArchive.type {
          case .sharp:
            nodeType = .sharp
          case .bezier:
            nodeType = .bezier
          case .smooth:
            nodeType = .smooth
          }

          return EditableBezierPathSource.Node(
            inControlPoint: PathPoint(
              x: Double(nodeArchive.inControlPoint.x),
              y: Double(nodeArchive.inControlPoint.y)
            ),
            nodePoint: PathPoint(
              x: Double(nodeArchive.nodePoint.x),
              y: Double(nodeArchive.nodePoint.y)
            ),
            outControlPoint: PathPoint(
              x: Double(nodeArchive.outControlPoint.x),
              y: Double(nodeArchive.outControlPoint.y)
            ),
            type: nodeType
          )
        }

        return EditableBezierPathSource.Subpath(
          nodes: nodes,
          closed: subpathArchive.closed
        )
      }

      return .editableBezier(
        EditableBezierPathSource(
          subpaths: subpaths,
          naturalSize: naturalSize
        ))
    }

    return nil
  }

  /// Parses a Bézier path from a path source archive.
  ///
  /// - Parameter pathSource: The path source containing path elements.
  /// - Returns: A Bézier path, or `nil` if parsing fails.
  private func parseBezierPath(from pathSource: TSD_PathSourceArchive) -> BezierPath? {
    guard pathSource.hasBezierPathSource else {
      return nil
    }

    let bezierSource = pathSource.bezierPathSource
    let naturalSize = CGSize(
      width: CGFloat(bezierSource.naturalSize.width),
      height: CGFloat(bezierSource.naturalSize.height)
    )

    guard bezierSource.hasPath else {
      return nil
    }

    let elements = bezierSource.path.elements.map { element -> PathElement in
      let type: PathElementType
      switch element.type {
      case .moveTo:
        type = .moveTo
      case .lineTo:
        type = .lineTo
      case .quadCurveTo:
        type = .quadCurveTo
      case .curveTo:
        type = .curveTo
      case .closeSubpath:
        type = .closeSubpath
      }

      let points = element.points.map { point in
        PathPoint(x: Double(point.x), y: Double(point.y))
      }

      return PathElement(type: type, points: points)
    }

    return BezierPath(elements: elements, naturalSize: naturalSize)
  }

  /// Parses shape fill information from a fill archive.
  ///
  /// - Parameter fill: The fill archive to parse from.
  /// - Returns: A shape fill, or `.none` if no fill is defined.
  private func parseShapeFill(from fill: TSD_FillArchive?) -> ShapeFill {
    guard let fill = fill else {
      return .none
    }

    if fill.hasColor {
      return .color(StyleConverters.convertColor(fill.color))
    }

    if fill.hasGradient {
      let colors = fill.gradient.stops.map { stop in
        StyleConverters.convertColor(stop.color)
      }
      return .gradient(colors)
    }

    return .none
  }

  /// Parses shape style information from a shape archive.
  ///
  /// - Parameters:
  ///   - shapeArchive: The shape archive containing style information.
  ///   - shapeInfo: The shape info archive for additional properties.
  /// - Returns: Complete shape style with fill, stroke, opacity, and shadow.
  private func parseShapeStyle(
    from shapeArchive: TSD_ShapeArchive,
    shapeInfo: TSWP_ShapeInfoArchive
  ) -> ShapeStyle {
    var fill: ShapeFill = .none
    var stroke: Border?
    var opacity: Double = 1.0
    var shadow: Shadow?
    var verticalAlignment: ShapeStyle.VerticalAlignment?
    var padding: ShapeStyle.Padding?
    var columns: ShapeStyle.Columns?

    if shapeArchive.hasStyle,
      let styleRef: TSP_Reference = shapeArchive.style as TSP_Reference?,
      let shapeStyle: TSWP_ShapeStyleArchive = document.dereference(styleRef)
    {
      let props = shapeStyle.super.shapeProperties

      if props.hasFill {
        fill = parseShapeFill(from: props.fill)
      }

      if props.hasStroke {
        let strokeArchive = props.stroke
        stroke = Border(
          width: Double(strokeArchive.width),
          color: StyleConverters.convertColor(strokeArchive.color),
          style: StyleConverters.convertBorderStyle(strokeArchive.pattern)
        )
      }

      if props.hasOpacity {
        opacity = Double(props.opacity)
      }

      if props.hasShadow {
        shadow = StyleConverters.convertShadow(props.shadow)
      }

      let tswpProps = shapeStyle.shapeProperties

      if tswpProps.hasVerticalAlignment {
        switch tswpProps.verticalAlignment {
        case .kFrameAlignTop:
          verticalAlignment = .top
        case .kFrameAlignMiddle:
          verticalAlignment = .middle
        case .kFrameAlignBottom:
          verticalAlignment = .bottom
        case .kFrameAlignJustify:
          verticalAlignment = .justify
        }
      }

      if tswpProps.hasPadding {
        let paddingArchive = tswpProps.padding
        padding = ShapeStyle.Padding(
          top: Double(paddingArchive.top),
          left: Double(paddingArchive.left),
          bottom: Double(paddingArchive.bottom),
          right: Double(paddingArchive.right)
        )
      }

      if tswpProps.hasColumns {
        let columnsArchive = tswpProps.columns
        if columnsArchive.hasEqualColumns {
          columns = .equal(
            count: Int(columnsArchive.equalColumns.count),
            gap: Double(columnsArchive.equalColumns.gap)
          )
        } else if columnsArchive.hasNonEqualColumns {
          let nonEqualArchive = columnsArchive.nonEqualColumns
          var definitions: [ShapeStyle.Columns.ColumnDefinition] = []

          // Add the first column (it has no preceding gap)
          definitions.append(
            .init(width: Double(nonEqualArchive.first), gap: 0)
          )

          // Add the rest of the columns and their preceding gaps
          for followingColumn in nonEqualArchive.following {
            definitions.append(
              .init(width: Double(followingColumn.width), gap: Double(followingColumn.gap))
            )
          }
          columns = .nonEqual(definitions)
        }
      }
    }

    return ShapeStyle(
      fill: fill, verticalAlignment: verticalAlignment, padding: padding, columns: columns,
      stroke: stroke, opacity: opacity,
      shadow: shadow)
  }

  /// Parses caption data from a reference.
  ///
  /// - Parameters:
  ///   - reference: Caption info reference.
  ///   - isHidden: Whether the caption is hidden.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Caption data, or nil if parsing fails.
  private func parseCaptionData(
    from reference: TSP_Reference?,
    isHidden: Bool,
    coordinateSpace: CoordinateSpace
  ) -> CaptionData? {
    guard let reference = reference,
      !isHidden,
      let captionInfo: TSA_CaptionInfoArchive = document.dereference(reference)
    else {
      return nil
    }

    let spatialInfo = parseSpatialInfo(
      from: captionInfo.super.super.super,
      coordinateSpace: coordinateSpace,
      drawableID: reference.hasIdentifier ? reference.identifier : nil
    )

    guard captionInfo.super.hasOwnedStorage,
      let storageRef = captionInfo.super.ownedStorage as TSP_Reference?,
      let textData = parseTextAndStyle(from: storageRef)
    else {
      return CaptionData(text: "", style: nil, spatialInfo: spatialInfo)
    }

    return CaptionData(text: textData.text, style: textData.style, spatialInfo: spatialInfo)
  }

  // MARK: - Drawable Data Parsing

  /// Parses group information from a group drawable.
  ///
  /// - Parameters:
  ///   - group: Group drawable archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the group.
  /// - Returns: Spatial info and child references.
  private func parseGroupInfo(
    from group: TSD_GroupArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) -> (spatialInfo: SpatialInfo, children: [TSP_Reference]) {
    let spatialInfo = parseSpatialInfo(
      from: group.super,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID
    )

    return (spatialInfo: spatialInfo, children: group.children)
  }

  /// Parses shape information from a shape drawable.
  ///
  /// - Parameters:
  ///   - shapeInfo: Shape info archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the shape.
  ///   - overrideSpatialInfo: Precomputed spatial info for placeholders.
  /// - Returns: Spatial info and optional storage reference for text content.
  private func parseShapeInfoData(
    from shapeInfo: TSWP_ShapeInfoArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?,
    overrideSpatialInfo: SpatialInfo? = nil
  ) -> (
    spatialInfo: SpatialInfo, storage: TSWP_StorageArchive?, isTextBox: Bool, hyperlink: Hyperlink?
  ) {
    let spatialInfo: SpatialInfo

    if let override = overrideSpatialInfo {
      spatialInfo = override
    } else {
      var frame = parseFrame(from: shapeInfo.super.super.geometry)

      if frame.size.width == 0 && frame.size.height == 0 {
        if shapeInfo.super.hasPathsource {
          let pathSource = shapeInfo.super.pathsource
          if pathSource.hasBezierPathSource {
            let naturalSize = pathSource.bezierPathSource.naturalSize
            frame.size = CGSize(
              width: CGFloat(naturalSize.width),
              height: CGFloat(naturalSize.height)
            )
          }
        }
      }

      let rotation = Double(shapeInfo.super.super.geometry.angle)
      let zIndex = drawableID.flatMap { getZIndex(for: $0) }

      let isAnchoredToText: Bool
      let isFloatingAboveText: Bool

      if shapeInfo.super.super.hasExteriorTextWrap {
        let wrap = shapeInfo.super.super.exteriorTextWrap
        isFloatingAboveText = wrap.type == 1
        isAnchoredToText = wrap.type == 0
      } else {
        isAnchoredToText = false
        isFloatingAboveText = false
      }

      spatialInfo = SpatialInfo(
        coordinateSpace: coordinateSpace,
        frame: frame,
        rotation: rotation,
        zIndex: zIndex,
        isAnchoredToText: isAnchoredToText,
        isFloatingAboveText: isFloatingAboveText
      )
    }

    let hyperlink: Hyperlink?
    if shapeInfo.hasSuper && shapeInfo.super.hasSuper && shapeInfo.super.super.hasHyperlinkURL {
      let url = shapeInfo.super.super.hyperlinkURL
      hyperlink = Hyperlink(text: String(), url: url, range: 0..<0)
    } else {
      hyperlink = nil
    }

    let isTextBox = shapeInfo.hasIsTextBox && shapeInfo.isTextBox

    var storage: TSWP_StorageArchive?
    if shapeInfo.hasOwnedStorage {
      storage = document.dereference(shapeInfo.ownedStorage)
    } else if shapeInfo.hasDeprecatedStorage {
      storage = document.dereference(shapeInfo.deprecatedStorage)
    }

    return (spatialInfo: spatialInfo, storage: storage, isTextBox: isTextBox, hyperlink: hyperlink)
  }

  /// Parses text and style from a storage reference.
  ///
  /// - Parameter storageRef: Storage reference containing text.
  /// - Returns: Text and character style, or nil if parsing fails.
  private func parseTextAndStyle(
    from storageRef: TSP_Reference
  ) -> (text: String, style: CharacterStyle?)? {
    guard let storage: TSWP_StorageArchive = document.dereference(storageRef) else {
      return nil
    }

    guard let text = storage.text.first else {
      return nil
    }

    let textString = String(text)

    var characterStyle: CharacterStyle?

    if !storage.tableCharStyle.entries.isEmpty {
      let firstStyleEntry = storage.tableCharStyle.entries[0]
      characterStyle = resolveCharacterStyle(
        from: firstStyleEntry,
        baseParagraphStyle: nil
      )
    } else {
      if !storage.tableParaStyle.entries.isEmpty {
        let paraEntry = storage.tableParaStyle.entries[0]
        if let paraStyle: TSWP_ParagraphStyleArchive = document.dereference(
          paraEntry.hasObject ? paraEntry.object : nil
        ) {
          let chain = StyleResolver.buildParagraphStyleChain(paraStyle, document: document)
          characterStyle = StyleResolver.extractCharacterPropertiesFromParagraphStyle(from: chain)
        }
      }
    }

    return (text: textString, style: characterStyle)
  }

  // MARK: - Media Data Parsing

  /// Parses the data identifier from a movie archive.
  ///
  /// - Parameter movie: Movie archive.
  /// - Returns: Data identifier, or nil if not found.
  private func parseMediaDataID(from movie: TSD_MovieArchive) -> UInt64? {
    if movie.hasMovieData && movie.movieData.hasIdentifier {
      return movie.movieData.identifier
    } else if movie.hasDatabaseMovieData && movie.databaseMovieData.hasIdentifier {
      return movie.databaseMovieData.identifier
    } else if movie.is3DObject, movie.TSA_Object3DInfo_object3DInfo.hasObjectData,
      movie.TSA_Object3DInfo_object3DInfo.objectData.hasIdentifier
    {
      return movie.TSA_Object3DInfo_object3DInfo.objectData.identifier
    }
    return nil
  }

  /// Parses complete media information including data and metadata.
  ///
  /// - Parameters:
  ///   - movie: Movie archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the media.
  /// - Returns: Media data, info, spatial info, and filepath, or nil if parsing fails.
  /// - Throws: Errors from reading media files.
  private func parseMediaData(
    from movie: TSD_MovieArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) throws -> (info: MediaInfo, spatialInfo: SpatialInfo, filepath: String)? {
    guard let dataID = parseMediaDataID(from: movie),
      let metadata: TSP_PackageMetadata = document.record(id: 2),
      let resolvedFile = resolveFile(from: metadata, dataID: dataID),
      let filename = resolvedFile.0,
      let filepath = resolvedFile.1
    else {
      return nil
    }

    let mediaType = parseMediaType(from: movie)
    let captionInfo = parseMediaCaptionInfo(from: movie, coordinateSpace: coordinateSpace)

    var posterImage: ImageInfo?
    if mediaType != .audio {
      posterImage = try parsePosterImage(from: movie, coordinateSpace: coordinateSpace)
    }

    let loopOption: MediaInfo.LoopOption
    if movie.hasLoopOption {
      switch movie.loopOption {
      case .none:
        loopOption = .none
      case .repeat:
        loopOption = .repeat
      case .backAndForth:
        loopOption = .backAndForth
      }
    } else {
      loopOption = .none
    }

    let duration = Double(movie.endTime - movie.startTime)
    let width = movie.hasNaturalSize ? Int(movie.naturalSize.width) : nil
    let height = movie.hasNaturalSize ? Int(movie.naturalSize.height) : nil
    let style = movie.resolveMediaStyle(using: self.document)

    let info = MediaInfo(
      type: mediaType,
      width: width,
      height: height,
      duration: duration,
      filename: filename,
      filepath: filepath,
      volume: movie.hasVolume ? movie.volume : 1.0,
      loopOption: loopOption,
      posterImage: posterImage,
      title: captionInfo.title,
      caption: captionInfo.caption,
      style: style
    )

    let spatialInfo = parseSpatialInfo(
      from: movie.super,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID
    )

    return (info: info, spatialInfo: spatialInfo, filepath: filepath)
  }

  /// Parses media caption information.
  ///
  /// - Parameters:
  ///   - movie: Movie archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Title and caption data.
  private func parseMediaCaptionInfo(
    from movie: TSD_MovieArchive,
    coordinateSpace: CoordinateSpace
  ) -> (title: CaptionData?, caption: CaptionData?) {
    let title = parseCaptionData(
      from: movie.super.hasTitle ? movie.super.title : nil,
      isHidden: movie.super.titleHidden,
      coordinateSpace: coordinateSpace
    )

    let caption = parseCaptionData(
      from: movie.super.hasCaption ? movie.super.caption : nil,
      isHidden: movie.super.captionHidden,
      coordinateSpace: coordinateSpace
    )

    return (title: title, caption: caption)
  }

  /// Parses poster image data for video/gif.
  ///
  /// - Parameters:
  ///   - movie: Movie archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Poster image, or nil if not available.
  /// - Throws: Errors from reading image files.
  private func parsePosterImage(
    from movie: TSD_MovieArchive,
    coordinateSpace: CoordinateSpace
  ) throws -> ImageInfo? {
    var dataID: UInt64?
    if movie.hasPosterImageData && movie.posterImageData.hasIdentifier {
      dataID = movie.posterImageData.identifier
    } else if movie.hasDatabasePosterImageData && movie.databasePosterImageData.hasIdentifier {
      dataID = movie.databasePosterImageData.identifier
    }

    guard let posterDataID = dataID,
      let metadata: TSP_PackageMetadata = document.record(id: 2),
      let resolvedFile = resolveFile(from: metadata, dataID: posterDataID),
      let filename = resolvedFile.0,
      let filepath = resolvedFile.1
    else {
      return nil
    }
    let width = movie.hasNaturalSize ? Int(movie.naturalSize.width) : 0
    let height = movie.hasNaturalSize ? Int(movie.naturalSize.height) : 0

    let info = ImageInfo(
      width: width,
      height: height,
      filename: filename,
      description: nil,
      filepath: filepath,
      title: nil,
      caption: nil
    )

    return info
  }

  /// Determines the media type from a movie archive.
  ///
  /// - Parameter movie: Movie archive to analyze.
  /// - Returns: The type of media (audio, video, or gif).
  private func parseMediaType(from movie: TSD_MovieArchive) -> MediaType {
    if movie.audioOnly {
      return .audio
    }

    if let dataID = parseMediaDataID(from: movie),
      let metadata: TSP_PackageMetadata = document.record(id: 2),
      let fileInfo = resolveFile(from: metadata, dataID: dataID),
      let filename = fileInfo.0
    {
      if filename.lowercased().hasSuffix(".gif") {
        return .gif
      }
    }

    return .video
  }

  /// Parses image caption information.
  ///
  /// - Parameters:
  ///   - image: Image archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Title and caption data.
  private func parseImageCaptionInfo(
    from image: TSD_ImageArchive,
    coordinateSpace: CoordinateSpace
  ) -> (title: CaptionData?, caption: CaptionData?) {
    let title = parseCaptionData(
      from: image.super.hasTitle ? image.super.title : nil,
      isHidden: image.super.titleHidden,
      coordinateSpace: coordinateSpace
    )

    let caption = parseCaptionData(
      from: image.super.hasCaption ? image.super.caption : nil,
      isHidden: image.super.captionHidden,
      coordinateSpace: coordinateSpace
    )

    return (title: title, caption: caption)
  }

  /// Resolves file information from a data info entry.
  ///
  /// - Parameters:
  ///   - dataInfo: Data info to resolve.
  ///   - expectedID: Expected data identifier.
  /// - Returns: Filename and filepath, or nil if not found.
  private func resolveFile(from dataInfo: TSP_DataInfo, expectedID: UInt64) -> (
    filename: String?, filepath: String?
  )? {
    guard dataInfo.identifier == expectedID else {
      return nil
    }

    var filename: String?
    var filepath: String?

    if !dataInfo.fileName.isEmpty {
      let testPath = "Data/\(dataInfo.fileName)"
      if document.storage.contains(path: testPath) {
        filename = dataInfo.fileName
        filepath = testPath
      }
    }

    if filepath == nil && !dataInfo.preferredFileName.isEmpty {
      let testPath = "Data/\(dataInfo.preferredFileName)"
      if document.storage.contains(path: testPath) {
        filename = dataInfo.preferredFileName
        filepath = testPath
      }
    }

    if let filename = filename, let filepath = filepath {
      return (filename: filename, filepath: filepath)
    }

    return nil
  }

  /// Resolves file information from metadata.
  ///
  /// - Parameters:
  ///   - metadata: Package metadata.
  ///   - dataID: Data identifier to resolve.
  /// - Returns: Filename, filepath, and data ID, or nil if not found.
  private func resolveFile(from metadata: TSP_PackageMetadata, dataID: UInt64) -> (
    filename: String?, filepath: String?, dataID: UInt64
  )? {
    for data in metadata.datas {
      if let fileInfo = resolveFile(from: data, expectedID: dataID) {
        return (fileInfo.filename!, fileInfo.filepath!, dataID)
      }
    }
    return nil
  }

  /// Resolves file information from an image.
  ///
  /// - Parameter image: Image archive.
  /// - Returns: Filename, filepath, and data ID, or nil if not found.
  private func resolveFile(from image: TSD_ImageArchive) -> (
    filename: String?, filepath: String?, dataID: UInt64
  )? {
    guard let dataID = parseDataID(from: image),
      let metadata: TSP_PackageMetadata = document.record(id: 2)
    else {
      return nil
    }
    return resolveFile(from: metadata, dataID: dataID)
  }

  /// Parses data identifier from an image.
  ///
  /// - Parameter image: Image archive.
  /// - Returns: Data identifier, or nil if not found.
  private func parseDataID(from image: TSD_ImageArchive) -> UInt64? {
    if image.hasData && image.data.hasIdentifier {
      return image.data.identifier
    } else if image.hasDatabaseData && image.databaseData.hasIdentifier {
      return image.databaseData.identifier
    }
    return nil
  }

  /// Candidate data identifiers to try when resolving an image's on-disk bytes, in
  /// preferred-quality order. Creator Studio template placeholders reference a primary
  /// `data` asset that isn't materialized locally (it lives in the template via a
  /// `document_resource_locator`), while the `-small-N` derivative IS shipped —
  /// falling back through `adjustedImageData` → `enhancedImageData` → `originalData`
  /// → `thumbnailAdjustedImageData` → `thumbnailData` → `databaseData` picks up the
  /// best available local byte representation. Order preserves the primary first so
  /// fully-materialized user-inserted images are unaffected.
  private func candidateImageDataIDs(_ image: TSD_ImageArchive) -> [UInt64] {
    var ids: [UInt64] = []
    func appendData(_ has: Bool, _ ref: TSP_DataReference) {
      if has && ref.hasIdentifier { ids.append(ref.identifier) }
    }
    func appendRef(_ has: Bool, _ ref: TSP_Reference) {
      if has && ref.hasIdentifier { ids.append(ref.identifier) }
    }
    appendData(image.hasData, image.data)
    appendData(image.hasAdjustedImageData, image.adjustedImageData)
    appendData(image.hasEnhancedImageData, image.enhancedImageData)
    appendData(image.hasOriginalData, image.originalData)
    appendData(image.hasThumbnailAdjustedImageData, image.thumbnailAdjustedImageData)
    appendData(image.hasThumbnailData, image.thumbnailData)
    appendRef(image.hasDatabaseData, image.databaseData)

    var seen = Set<UInt64>()
    return ids.filter { seen.insert($0).inserted }
  }

  /// Walks the image's candidate data references and returns the first one whose file
  /// is actually present on disk in the document package. Returns `nil` only when the
  /// image has no locally-materialized representation at all.
  private func resolveMaterializedImageFile(
    from image: TSD_ImageArchive,
    metadata: TSP_PackageMetadata
  ) -> (filename: String, filepath: String)? {
    for dataID in candidateImageDataIDs(image) {
      if let resolved = resolveFile(from: metadata, dataID: dataID),
        let filename = resolved.filename,
        let filepath = resolved.filepath
      {
        return (filename, filepath)
      }
    }
    return nil
  }

  /// Parses accessibility description from an image.
  ///
  /// - Parameter image: Image archive.
  /// - Returns: Accessibility description, or nil if not available.
  private func parseAccessibilityDescription(from image: TSD_ImageArchive) -> String? {
    return image.hasSuper && image.super.hasAccessibilityDescription
      ? image.super.accessibilityDescription
      : nil
  }

  /// Parses complete image information including data and metadata.
  ///
  /// - Parameters:
  ///   - image: Image archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the image.
  /// - Returns: Image data, info, spatial info, filepath, and hyperlink, or nil if parsing fails.
  /// - Throws: Errors from reading image files.
  private func parseImageData(
    from image: TSD_ImageArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) throws -> (
    info: ImageInfo, spatialInfo: SpatialInfo, filepath: String, hyperlink: Hyperlink?
  )? {
    guard let metadata: TSP_PackageMetadata = document.record(id: 2),
      let (filename, filepath) = resolveMaterializedImageFile(from: image, metadata: metadata)
    else {
      return nil
    }

    let captionInfo = parseImageCaptionInfo(from: image, coordinateSpace: coordinateSpace)
    let description = parseAccessibilityDescription(from: image)
    let spatialInfo: SpatialInfo

    spatialInfo = parseSpatialInfo(
      from: image.super,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID
    )

    let mask = parseImageMask(from: image)

    let style = image.resolveMediaStyle(using: self.document, mask: mask)

    let info = ImageInfo(
      width: Int(image.naturalSize.width),
      height: Int(image.naturalSize.height),
      filename: filename,
      description: description,
      filepath: filepath,
      title: captionInfo.title,
      caption: captionInfo.caption,
      attributes: image.webVideoAttributes,
      style: style
    )

    let hyperlink: Hyperlink?
    if image.hasSuper && image.super.hasHyperlinkURL {
      hyperlink = Hyperlink(text: filename, url: image.super.hyperlinkURL, range: 0..<0)
    } else {
      hyperlink = nil
    }

    return (info: info, spatialInfo: spatialInfo, filepath: filepath, hyperlink: hyperlink)
  }

  /// Parses table structure and cell data.
  ///
  /// - Parameters:
  ///   - table: Table model archive.
  ///   - name: Optional table name.
  ///   - drawable: Base drawable archive for spatial positioning.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the table.
  /// - Returns: Table structure and data maps, or nil if parsing fails.
  private func parseTableData(
    from table: TST_TableModelArchive,
    name: String?,
    drawable: TSD_DrawableArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) -> (
    rowCount: UInt32, columnCount: UInt32, spatialInfo: SpatialInfo, stringMap: [UInt32: String],
    richMap: [UInt32: TSP_Reference], tiles: [TST_TileStorage.Tile]
  )? {
    let rowCount = table.numberOfRows
    let columnCount = table.numberOfColumns

    let spatialInfo = parseSpatialInfo(
      from: drawable,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID
    )

    guard table.baseDataStore.hasStringTable else {
      return nil
    }

    guard table.baseDataStore.hasRichTextTable else {
      return nil
    }

    let stringTable: TST_TableDataList? = document.dereference(table.baseDataStore.stringTable)
    let richTable: TST_TableDataList? = document.dereference(table.baseDataStore.richTextTable)

    let stringMap = Dictionary(
      uniqueKeysWithValues: (stringTable?.entries ?? []).map { ($0.key, $0.string) }
    )
    let richMap = Dictionary(
      uniqueKeysWithValues: (richTable?.entries ?? []).map { ($0.key, $0.richTextPayload) }
    )

    let tiles = table.baseDataStore.tiles.tiles

    return (
      rowCount: rowCount, columnCount: columnCount, spatialInfo: spatialInfo, stringMap: stringMap,
      richMap: richMap, tiles: tiles
    )
  }

  // MARK: - Process Functions

  /// Processes a movie drawable (video, audio, gif, or 3D object).
  ///
  /// - Parameters:
  ///   - movie: Movie archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the movie.
  /// - Throws: Errors from reading media data.
  private func processMovie(
    _ movie: TSD_MovieArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) async throws {
    if movie.is3DObject {
      print("Processing 3D object drawable with ID \(drawableID?.description ?? "nil")")
      try await process3DObject(movie, coordinateSpace: coordinateSpace, drawableID: drawableID)
      return
    }

    guard
      let mediaData: (info: MediaInfo, spatialInfo: SpatialInfo, filepath: String) =
        try parseMediaData(
          from: movie,
          coordinateSpace: coordinateSpace,
          drawableID: drawableID
        )
    else {
      return
    }

    await visitor.visitMedia(
      info: mediaData.info,
      spatialInfo: mediaData.spatialInfo
    )
  }

  /// Processes a 3D object drawable.
  ///
  /// - Parameters:
  ///   - movie: Movie archive containing 3D object data.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the 3D object.
  /// - Throws: Errors from reading 3D model data.
  private func process3DObject(
    _ movie: TSD_MovieArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) async throws {
    guard
      let objectData = try parse3DObjectData(
        from: movie,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )
    else {
      return
    }

    await visitor.visitObject3D(
      info: objectData.info,
      spatialInfo: objectData.spatialInfo
    )
  }

  /// Processes a group drawable by visiting its child drawables.
  ///
  /// - Parameters:
  ///   - group: Group drawable archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the group.
  /// - Throws: Errors from traversing child drawables.
  private func processGroup(
    _ group: TSD_GroupArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) async throws {
    let groupInfo = parseGroupInfo(
      from: group, coordinateSpace: coordinateSpace, drawableID: drawableID)

    await visitor.willVisitGroup(spatialInfo: groupInfo.spatialInfo)

    for childRef in groupInfo.children {
      try await traverseDrawable(childRef, coordinateSpace: coordinateSpace, containerInfo: nil)
    }

    await visitor.didVisitGroup()
  }

  // MARK: - Shape Processing

  /// Processes a floating shape drawable, emitting both shape geometry and any text content as
  /// inline elements.
  ///
  /// - Parameters:
  ///   - shapeInfo: Shape info archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the shape.
  ///   - overrideSpatialInfo: Precomputed spatial info for placeholders.
  /// - Throws: Errors from traversing the text storage or parsing shape data.
  private func processShapeInfo(
    _ shapeInfo: TSWP_ShapeInfoArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?,
    overrideSpatialInfo: SpatialInfo? = nil
  ) async throws {
    let shapeData = parseShapeInfoData(
      from: shapeInfo,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID,
      overrideSpatialInfo: overrideSpatialInfo
    )

    guard let path = parsePathSource(from: shapeInfo.super.pathsource) else {
      return
    }

    let style = parseShapeStyle(from: shapeInfo.super, shapeInfo: shapeInfo)

    let title = parseCaptionData(
      from: shapeInfo.super.super.hasTitle ? shapeInfo.super.super.title : nil,
      isHidden: shapeInfo.super.super.titleHidden,
      coordinateSpace: coordinateSpace
    )

    let caption = parseCaptionData(
      from: shapeInfo.super.super.hasCaption ? shapeInfo.super.super.caption : nil,
      isHidden: shapeInfo.super.super.captionHidden,
      coordinateSpace: coordinateSpace
    )

    let pathSource = shapeInfo.super.pathsource
    let isHorizontallyFlipped = pathSource.hasHorizontalFlip ? pathSource.horizontalFlip : false
    let isVerticallyFlipped = pathSource.hasVerticalFlip ? pathSource.verticalFlip : false
    let localizationKey = pathSource.hasLocalizationKey ? pathSource.localizationKey : nil
    let userDefinedName = pathSource.hasUserDefinedName ? pathSource.userDefinedName : nil

    let info = ShapeInfo(
      path: path,
      style: style,
      title: title,
      caption: caption,
      isHorizontallyFlipped: isHorizontallyFlipped,
      isVerticallyFlipped: isVerticallyFlipped,
      localizationKey: localizationKey,
      userDefinedName: userDefinedName,
      hyperlink: shapeData.hyperlink
    )

    await visitor.willVisitShape(info: info, spatialInfo: shapeData.spatialInfo)

    if let storage = shapeData.storage {
      let hasText = storage.text.first.map { !$0.isEmpty } ?? false

      if hasText {
        try await traverseStorage(
          storage,
          coordinateSpace: coordinateSpace,
          containerInfo: shapeData.spatialInfo,
          tableContext: nil
        )
      }
    }

    await visitor.didVisitShape()
  }

  /// Processes a floating image drawable, optionally performing OCR on the image data.
  ///
  /// - Parameters:
  ///   - image: Image archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the image.
  /// - Throws: Errors from reading image data or performing OCR.
  private func processImage(
    _ image: TSD_ImageArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) async throws {
    guard
      let imageData = try parseImageData(
        from: image,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )
    else {
      return
    }

    let ocrResult: OCRResult?
    if let provider = ocrProvider,
      let content = try? readFileFromArchive(path: imageData.filepath),
      let result = try? await provider.recognizeText(in: content, info: imageData.info)
    {
      ocrResult = result
    } else {
      ocrResult = nil
    }

    await visitor.visitImage(
      info: imageData.info,
      spatialInfo: imageData.spatialInfo,
      ocrResult: ocrResult,
      hyperlink: imageData.hyperlink
    )
  }

  /// Processes a floating table by visiting each row and cell in order.
  ///
  /// - Parameters:
  ///   - table: Table model archive.
  ///   - name: Optional table name.
  ///   - drawable: Base drawable archive for spatial positioning.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the table.
  /// - Throws: Errors from processing cells or their content.
  private func processTable(
    _ table: TST_TableModelArchive,
    name: String?,
    drawable: TSD_DrawableArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) async throws {
    guard
      let tableData = parseTableData(
        from: table,
        name: name,
        drawable: drawable,
        coordinateSpace: coordinateSpace,
        drawableID: drawableID
      )
    else {
      return
    }

    await visitor.willVisitTable(
      name: name ?? table.tableName,
      rowCount: tableData.rowCount,
      columnCount: tableData.columnCount,
      spatialInfo: tableData.spatialInfo
    )

    for (tileIndex, tileInfo) in tableData.tiles.enumerated() {
      guard tileInfo.hasTile else {
        continue
      }

      guard let tile: TST_Tile = document.dereference(tileInfo.tile) else {
        continue
      }

      for (rowIndex, rowInfo) in tile.rowInfos.enumerated() {
        let actualRowIndex = tileIndex * Int(tile.numrows) + rowIndex

        await visitor.willVisitTableRow(index: actualRowIndex)

        try await processCellRow(
          rowInfo: rowInfo,
          rowIndex: actualRowIndex,
          columnCount: Int(tableData.columnCount),
          stringMap: tableData.stringMap,
          richMap: tableData.richMap,
          coordinateSpace: coordinateSpace,
          tableModel: table
        )

        await visitor.didVisitTableRow(index: actualRowIndex)
      }
    }

    await visitor.didVisitTable()
  }

  /// Processes all cells in a table row.
  ///
  /// - Parameters:
  ///   - rowInfo: Row information containing cell storage buffer.
  ///   - rowIndex: Zero-based row index.
  ///   - columnCount: Total number of columns.
  ///   - stringMap: Map of string IDs to their values.
  ///   - richMap: Map of rich text IDs to storage references.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - tableModel: Table model for style lookups.
  /// - Throws: Errors from parsing or processing cell content.
  private func processCellRow(
    rowInfo: TST_TileRowInfo,
    rowIndex: Int,
    columnCount: Int,
    stringMap: [UInt32: String],
    richMap: [UInt32: TSP_Reference],
    coordinateSpace: CoordinateSpace,
    tableModel: TST_TableModelArchive
  ) async throws {
    let offsets = rowInfo.cellOffsets.withUnsafeBytes { buffer in
      Array(buffer.bindMemory(to: UInt16.self))
    }
    let cellStorageBuffer = rowInfo.cellStorageBuffer

    for columnIndex in 0..<columnCount {
      let offset = offsets[columnIndex]

      guard offset != 0xFFFF else {
        await visitor.visitTableCell(row: rowIndex, column: columnIndex, content: .empty)
        continue
      }

      let content = try await parseCellContent(
        from: cellStorageBuffer,
        offset: Int(offset),
        row: rowIndex,
        column: columnIndex,
        stringMap: stringMap,
        richMap: richMap,
        coordinateSpace: coordinateSpace,
        tableModel: tableModel
      )

      await visitor.visitTableCell(row: rowIndex, column: columnIndex, content: content)
    }
  }

  // MARK: - Cell Content Parsing

  /// Parses cell content from the storage buffer at the specified offset.
  ///
  /// - Parameters:
  ///   - buffer: Cell storage buffer containing packed cell data.
  ///   - offset: Byte offset to the start of the cell.
  ///   - row: Zero-based row index.
  ///   - column: Zero-based column index.
  ///   - stringMap: Map of string IDs to their values.
  ///   - richMap: Map of rich text IDs to storage references.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - tableModel: Table model for style and border lookups.
  /// - Returns: Parsed cell content with type and formatting.
  /// - Throws: Errors from traversing rich text storage.
  private func parseCellContent(
    from buffer: Data,
    offset: Int,
    row: Int,
    column: Int,
    stringMap: [UInt32: String],
    richMap: [UInt32: TSP_Reference],
    coordinateSpace: CoordinateSpace,
    tableModel: TST_TableModelArchive
  ) async throws -> TableCellContent {
    guard offset + 12 <= buffer.count else {
      return .empty
    }

    let version = buffer[offset]
    let cellType = buffer[offset + 1]

    let extras = buffer.withUnsafeBytes { bytes in
      bytes.loadUnaligned(fromByteOffset: offset + 6, as: UInt16.self)
    }

    let flagsRawValue = buffer.withUnsafeBytes { bytes in
      bytes.loadUnaligned(fromByteOffset: offset + 8, as: UInt32.self)
    }

    let flags = CellStorageFlags(rawValue: flagsRawValue)

    guard version == 5 else {
      return .empty
    }

    var dataOffset = offset + 12

    var decimal128: Double?
    var double: Double?
    var seconds: Double?
    var stringId: UInt32?
    var richTextId: UInt32?
    var cellStyleId: UInt32?
    var textStyleId: UInt32?
    var formulaId: UInt32?
    var controlId: UInt32?
    var suggestId: UInt32?
    var numFormatId: UInt32?
    var currencyFormatId: UInt32?
    var dateFormatId: UInt32?
    var durationFormatId: UInt32?
    var textFormatId: UInt32?
    var boolFormatId: UInt32?

    if flags.contains(.hasDecimal128) {
      if dataOffset + 16 <= buffer.count {
        decimal128 = unpackDecimal128(from: buffer, offset: dataOffset)
        dataOffset += 16
      }
    }

    if flags.contains(.hasDouble) {
      if dataOffset + 8 <= buffer.count {
        double = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: Double.self)
        }
        dataOffset += 8
      }
    }

    if flags.contains(.hasSeconds) {
      if dataOffset + 8 <= buffer.count {
        seconds = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: Double.self)
        }
        dataOffset += 8
      }
    }

    if flags.contains(.hasStringID) {
      if dataOffset + 4 <= buffer.count {
        stringId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasRichTextID) {
      if dataOffset + 4 <= buffer.count {
        richTextId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasCellStyleID) {
      if dataOffset + 4 <= buffer.count {
        cellStyleId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasTextStyleID) {
      if dataOffset + 4 <= buffer.count {
        textStyleId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasConditionalFormatID) {
      dataOffset += 4
    }

    if flags.contains(.hasFormatID) {
      dataOffset += 4
    }

    if flags.contains(.hasFormulaID) {
      if dataOffset + 4 <= buffer.count {
        formulaId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasControlID) {
      if dataOffset + 4 <= buffer.count {
        controlId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasCommentID) {
      dataOffset += 4
    }

    if flags.contains(.hasSuggestionID) {
      if dataOffset + 4 <= buffer.count {
        suggestId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasNumberFormatID) {
      if dataOffset + 4 <= buffer.count {
        numFormatId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasCurrencyFormatID) {
      if dataOffset + 4 <= buffer.count {
        currencyFormatId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasDateFormatID) {
      if dataOffset + 4 <= buffer.count {
        dateFormatId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasDurationFormatID) {
      if dataOffset + 4 <= buffer.count {
        durationFormatId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasTextFormatID) {
      if dataOffset + 4 <= buffer.count {
        textFormatId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    if flags.contains(.hasBooleanFormatID) {
      if dataOffset + 4 <= buffer.count {
        boolFormatId = buffer.withUnsafeBytes { bytes in
          bytes.loadUnaligned(fromByteOffset: dataOffset, as: UInt32.self)
        }
        dataOffset += 4
      }
    }

    let border = parseCellBorder(
      styleId: cellStyleId,
      tableModel: tableModel,
      row: row,
      column: column
    )
    let cellStyle = parseCellStyle(styleId: cellStyleId, tableModel: tableModel)
    let textStyle = parseTextStyle(styleId: textStyleId, tableModel: tableModel)

    let currencyFormat = parseCurrencyFormat(
      formatId: currencyFormatId,
      tableModel: tableModel
    )

    let metadata = CellStorageMetadata(
      cellType: cellType,
      version: version,
      flags: flagsRawValue,
      extras: extras,
      decimal128: decimal128,
      double: double,
      seconds: seconds,
      stringId: stringId,
      richTextId: richTextId,
      cellStyleId: cellStyleId,
      textStyleId: textStyleId,
      formulaId: formulaId,
      controlId: controlId,
      suggestId: suggestId,
      numFormatId: numFormatId,
      currencyFormatId: currencyFormatId,
      dateFormatId: dateFormatId,
      durationFormatId: durationFormatId,
      textFormatId: textFormatId,
      boolFormatId: boolFormatId,
      border: border,
      cellStyle: cellStyle,
      textStyle: textStyle,
      currencyFormat: currencyFormat
    )

    switch cellType {
    case CellType.empty.rawValue:
      return .empty

    case CellType.number.rawValue:
      if let value = decimal128 {
        return .number(value, metadata: metadata)
      } else if let value = double {
        return .number(value, metadata: metadata)
      }
      return .empty

    case CellType.text.rawValue:
      if let stringId = stringId {
        if let text = stringMap[stringId] {
          return .text(text, metadata: metadata)
        }
      }
      return .empty

    case CellType.date.rawValue:
      if let seconds = seconds {
        guard seconds != 0.0 else {
          return .empty
        }
        let date = IWorkConstants.date(fromAppleTimestamp: seconds)
        return .date(date, metadata: metadata)
      }
      return .empty

    case CellType.boolean.rawValue:
      if let double = double {
        return .boolean(double > 0.0, metadata: metadata)
      }
      return .empty

    case CellType.duration.rawValue:
      if let double = double {
        guard double != 0.0 else {
          return .empty
        }
        return .duration(double, metadata: metadata)
      }
      return .empty

    case CellType.error.rawValue:
      return .formulaError(metadata: metadata)

    case CellType.richText.rawValue, 9:
      if let richId = richTextId {
        if let richRef = richMap[richId] {
          guard let richTextPayload: TST_RichTextPayloadArchive = document.dereference(richRef)
          else {
            return .empty
          }

          guard let storage: TSWP_StorageArchive = document.dereference(richTextPayload.storage)
          else {
            return .empty
          }

          let inlineContent = try await parseInlineContentFromStorage(
            storage,
            coordinateSpace: coordinateSpace
          )
          return .richText(inlineContent, metadata: metadata)
        }
      }
      return .empty

    case CellType.currency.rawValue:
      if let value = decimal128 ?? double, let format = currencyFormat {
        return .currency(value, format: format, metadata: metadata)
      } else if let value = decimal128 ?? double {
        return .number(value, metadata: metadata)
      }
      return .empty

    default:
      return .empty
    }
  }

  /// Parses currency format information from a format ID.
  ///
  /// - Parameters:
  ///   - formatId: Currency format identifier.
  ///   - tableModel: Table model containing format tables.
  /// - Returns: Currency format information, or nil if unavailable.
  private func parseCurrencyFormat(
    formatId: UInt32?,
    tableModel: TST_TableModelArchive
  ) -> CurrencyFormat? {
    guard let formatId = formatId else {
      return nil
    }

    guard tableModel.baseDataStore.hasFormatTable else {
      return nil
    }

    guard
      let formatTable: TST_TableDataList = document.dereference(
        tableModel.baseDataStore.formatTable
      )
    else {
      return nil
    }

    guard let formatEntry = formatTable.entries.first(where: { $0.key == formatId }) else {
      return nil
    }

    guard formatEntry.hasFormat else {
      return nil
    }

    let formatStruct = formatEntry.format

    let currencyCode: String
    if formatStruct.hasCurrencyCode && !formatStruct.currencyCode.isEmpty {
      currencyCode = formatStruct.currencyCode
    } else {
      currencyCode = "USD"
    }

    guard IWorkConstants.isValidCurrency(currencyCode) else {
      return CurrencyFormat(code: "USD")
    }

    let decimalPlaces: UInt8
    if formatStruct.hasDecimalPlaces {
      let places = formatStruct.decimalPlaces
      if places == IWorkConstants.decimalPlacesAuto {
        decimalPlaces = IWorkConstants.decimalPlacesAuto
      } else {
        decimalPlaces = UInt8(min(places, 255))
      }
    } else {
      decimalPlaces = 2
    }

    let showSymbol = true

    let useAccountingStyle: Bool
    if formatStruct.hasUseAccountingStyle {
      useAccountingStyle = formatStruct.useAccountingStyle
    } else {
      useAccountingStyle = false
    }

    return CurrencyFormat(
      code: currencyCode,
      decimalPlaces: decimalPlaces,
      showSymbol: showSymbol,
      useAccountingStyle: useAccountingStyle
    )
  }

  // MARK: - Cell Style
  /// Parses cell border styling by finding the highest-priority stroke for each edge.
  ///
  /// - Parameters:
  ///   - styleId: Cell style identifier.
  ///   - tableModel: Table model containing stroke sidecar.
  ///   - row: Zero-based row index.
  ///   - column: Zero-based column index.
  /// - Returns: Border styling for all four edges, or `nil` if no borders are defined.
  private func parseCellBorder(
    styleId: UInt32?,
    tableModel: TST_TableModelArchive,
    row: Int,
    column: Int
  ) -> CellBorder? {
    guard tableModel.hasStrokeSidecar else {
      return nil
    }

    guard let sidecarRef = tableModel.strokeSidecar as TSP_Reference? else {
      return nil
    }

    guard let sidecar: TST_StrokeSidecarArchive = document.dereference(sidecarRef) else {
      return nil
    }

    let topBorder = parseBorderForSide(
      layers: sidecar.topRowStrokeLayers,
      row: row,
      column: column,
      isHorizontal: true
    )

    let rightBorder = parseBorderForSide(
      layers: sidecar.rightColumnStrokeLayers,
      row: row,
      column: column,
      isHorizontal: false
    )

    let bottomBorder = parseBorderForSide(
      layers: sidecar.bottomRowStrokeLayers,
      row: row,
      column: column,
      isHorizontal: true
    )

    let leftBorder = parseBorderForSide(
      layers: sidecar.leftColumnStrokeLayers,
      row: row,
      column: column,
      isHorizontal: false
    )

    if topBorder != nil || rightBorder != nil || bottomBorder != nil || leftBorder != nil {
      return CellBorder(top: topBorder, right: rightBorder, bottom: bottomBorder, left: leftBorder)
    }

    return nil
  }

  /// Parses border styling for one cell edge by finding overlapping stroke runs.
  ///
  /// When multiple strokes overlap, the one with the highest order value wins.
  ///
  /// - Parameters:
  ///   - layers: Stroke layers for this edge type.
  ///   - row: Zero-based row index.
  ///   - column: Zero-based column index.
  ///   - isHorizontal: Whether this is a horizontal edge.
  /// - Returns: Border styling for this edge, or `nil` if no stroke applies.
  private func parseBorderForSide(
    layers: [TSP_Reference],
    row: Int,
    column: Int,
    isHorizontal: Bool
  ) -> Border? {
    var bestBorder: (border: Border, order: Int)?

    for layerRef in layers {
      guard let strokeLayer: TST_StrokeLayerArchive = document.dereference(layerRef) else {
        continue
      }

      let layerIndex = Int(strokeLayer.rowColumnIndex)

      for strokeRun in strokeLayer.strokeRuns {
        let origin = Int(strokeRun.origin)
        let length = Int(strokeRun.length)
        let order = Int(strokeRun.order)

        let intersects: Bool
        if isHorizontal {
          intersects = (layerIndex == row) && (column >= origin) && (column < origin + length)
        } else {
          intersects = (layerIndex == column) && (row >= origin) && (row < origin + length)
        }

        guard intersects else {
          continue
        }

        let border = createBorderFromStroke(strokeRun)

        if bestBorder == nil || order > bestBorder!.order {
          bestBorder = (border, order)
        }
      }
    }

    return bestBorder?.border
  }

  /// Creates a border from a stroke run.
  ///
  /// - Parameter strokeRun: The stroke run to convert.
  /// - Returns: A border with the stroke's properties.
  private func createBorderFromStroke(_ strokeRun: TST_StrokeLayerArchive.StrokeRunArchive)
    -> Border
  {
    let stroke = strokeRun.stroke
    let width = Double(stroke.width)
    let color = StyleConverters.convertColor(stroke.color)
    let style = StyleConverters.convertBorderStyle(stroke.pattern)

    return Border(width: width, color: color, style: style)
  }

  /// Creates a border from a stroke archive (used for charts and shapes).
  ///
  /// - Parameter stroke: The stroke archive to convert.
  /// - Returns: A border with the stroke's properties.
  private func createBorderFromStroke(_ stroke: TSD_StrokeArchive) -> Border {
    let width = Double(stroke.width)
    let color = StyleConverters.convertColor(stroke.color)
    let style = StyleConverters.convertBorderStyle(stroke.pattern)

    return Border(width: width, color: color, style: style)
  }

  /// Parses cell background and fill styling.
  ///
  /// - Parameters:
  ///   - styleId: Cell style identifier from the cell storage.
  ///   - tableModel: Table model containing style table.
  /// - Returns: Cell styling properties, or `nil` if unavailable.
  private func parseCellStyle(
    styleId: UInt32?,
    tableModel: TST_TableModelArchive
  ) -> CellStyle? {
    guard let styleId = styleId else {
      return nil
    }

    guard tableModel.baseDataStore.hasStyleTable else {
      return nil
    }

    guard
      let styleTable: TST_TableDataList = document.dereference(
        tableModel.baseDataStore.styleTable
      )
    else {
      return nil
    }

    guard let styleEntry = styleTable.entries.first(where: { $0.key == styleId }) else {
      return nil
    }

    guard styleEntry.hasReference else {
      return nil
    }

    guard let styleRef = styleEntry.reference as TSP_Reference? else {
      return nil
    }

    guard let cellStyleArchive: TST_CellStyleArchive = document.dereference(styleRef) else {
      return nil
    }

    let chain = StyleResolver.buildCellStyleChain(cellStyleArchive, document: document)
    return StyleResolver.extractCellStyleProperties(from: chain)
  }

  /// Parses text styling for a table cell.
  ///
  /// - Parameters:
  ///   - styleId: Text style identifier from the cell storage.
  ///   - tableModel: Table model containing style table.
  /// - Returns: Character styling properties, or `nil` if unavailable.
  private func parseTextStyle(
    styleId: UInt32?,
    tableModel: TST_TableModelArchive
  ) -> CharacterStyle? {
    guard let styleId = styleId else {
      return nil
    }

    guard tableModel.baseDataStore.hasStyleTable else {
      return nil
    }

    guard
      let styleTable: TST_TableDataList = document.dereference(
        tableModel.baseDataStore.styleTable
      )
    else {
      return nil
    }

    guard let styleEntry = styleTable.entries.first(where: { $0.key == styleId }) else {
      return nil
    }

    guard styleEntry.hasReference else {
      return nil
    }

    guard let styleRef = styleEntry.reference as TSP_Reference? else {
      return nil
    }

    if let paraStyle: TSWP_ParagraphStyleArchive = document.dereference(styleRef) {
      let chain = StyleResolver.buildParagraphStyleChain(paraStyle, document: document)
      return StyleResolver.extractCharacterPropertiesFromParagraphStyle(from: chain)
    } else if let charStyle: TSWP_CharacterStyleArchive = document.dereference(styleRef) {
      let chain = StyleResolver.buildCharacterStyleChain(charStyle, document: document)
      return StyleResolver.extractCharacterPropertiesFromCharacterStyle(from: chain)
    }

    return nil
  }

  // MARK: - Decimal128 Unpacking

  /// Unpacks a 128-bit decimal value from the cell storage buffer.
  ///
  /// Uses the bias constant from IWorkConstants for accurate unpacking.
  ///
  /// - Parameters:
  ///   - buffer: Cell storage buffer.
  ///   - offset: Byte offset to the decimal value.
  /// - Returns: Unpacked floating-point value.
  private func unpackDecimal128(from buffer: Data, offset: Int) -> Double {
    guard offset + 16 <= buffer.count else {
      return 0.0
    }

    let byte15 = UInt16(buffer[offset + 15])
    let byte14 = UInt16(buffer[offset + 14])
    let expBits = ((byte15 & 0x7F) << 7) | (byte14 >> 1)
    let exp = Int(expBits) - IWorkConstants.decimal128Bias

    var mantissa: UInt64 = UInt64(byte14 & 1)
    for i in (0..<14).reversed() {
      mantissa = mantissa * 256 + UInt64(buffer[offset + i])
    }

    let sign = (byte15 & 0x80) != 0

    var value = Double(mantissa) * pow(10.0, Double(exp))
    if sign {
      value = -value
    }

    return value
  }

  // MARK: - Chart Processing

  /// Processes a chart drawable.
  ///
  /// - Parameters:
  ///   - chart: Chart archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the chart.
  /// - Throws: Errors from processing the chart.
  private func processChart(
    _ drawable: TSCH_ChartDrawableArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) async throws {
    guard drawable.hasTSCH_ChartArchive_unity else {
      return
    }
    let chart = drawable.TSCH_ChartArchive_unity

    guard var chartInfo = parseChartInfo(from: chart) else {
      return
    }

    chartInfo.title = parseCaptionData(
      from: drawable.super.title, isHidden: false, coordinateSpace: coordinateSpace)
    chartInfo.caption = parseCaptionData(
      from: drawable.super.caption, isHidden: false, coordinateSpace: coordinateSpace)

    let spatialInfo = parseSpatialInfo(
      from: drawable.super,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID
    )

    await visitor.visitChart(info: chartInfo, spatialInfo: spatialInfo)
  }

  /// Parses complete chart information from a chart archive.
  ///
  /// - Parameter chart: Chart archive.
  /// - Returns: Chart information, or nil if parsing fails.
  private func parseChartInfo(from chart: TSCH_ChartArchive) -> ChartInfo? {
    let chartType = parseChartType(from: chart)

    guard let gridData = parseChartGridData(from: chart) else {
      return nil
    }

    let valueAxis = parseChartAxisInfo(from: chart, isValueAxis: true)
    let categoryAxis = parseChartAxisInfo(from: chart, isValueAxis: false)

    let seriesCount: Int
    if chart.hasSeriesDirection && chart.seriesDirection == .byRow {
      seriesCount = gridData.rowCount - 1
    } else {
      seriesCount = gridData.columnCount - 1
    }

    let series = parseChartSeriesInfo(from: chart, seriesCount: max(0, seriesCount))
    let legend = parseChartLegendInfo(from: chart)

    var backgroundFill: ShapeFill = .none
    var plotAreaFill: ShapeFill = .none
    if chart.hasChartStyle,
      let style: TSCH_ChartStyleArchive = document.dereference(chart.chartStyle)
    {
      let props = style.TSCH_Generated_ChartStyleArchive_current

      if props.hasTschchartinfodefaultbackgroundfill {
        backgroundFill = parseShapeFill(from: props.tschchartinfodefaultbackgroundfill)
      }
      if props.hasTschchartinfodefaultgridbackgroundfill {
        plotAreaFill = parseShapeFill(from: props.tschchartinfodefaultgridbackgroundfill)
      }
    }

    return ChartInfo(
      chartType: chartType,
      gridData: gridData,
      title: nil,
      showTitle: false,
      valueAxis: valueAxis,
      categoryAxis: categoryAxis,
      series: series,
      legend: legend,
      backgroundFill: backgroundFill,
      plotAreaFill: plotAreaFill
    )
  }

  /// Parses chart type from a chart archive.
  ///
  /// - Parameter chart: Chart archive.
  /// - Returns: The chart type.
  private func parseChartType(from chart: TSCH_ChartArchive) -> ChartType {
    guard chart.hasChartType else {
      return .unknown(0)
    }

    switch chart.chartType {
    case .barChartType2D:
      return .bar2D
    case .barChartType3D:
      return .bar3D
    case .columnChartType2D:
      return .column2D
    case .columnChartType3D:
      return .column3D
    case .lineChartType2D:
      return .line2D
    case .lineChartType3D:
      return .line3D
    case .areaChartType2D:
      return .area2D
    case .areaChartType3D:
      return .area3D
    case .pieChartType2D:
      return .pie2D
    case .pieChartType3D:
      return .pie3D
    case .scatterChartType2D:
      return .scatter2D
    case .bubbleChartType2D:
      return .bubble2D
    case .mixedChartType2D:
      return .mixed2D
    case .donutChartType2D:
      return .donut2D
    default:
      return .unknown(chart.chartType.rawValue)
    }
  }

  /// Parses chart grid data from a chart model.
  ///
  /// - Parameter chart: Chart archive.
  /// - Returns: Chart grid data, or nil if parsing fails.
  private func parseChartGridData(from chart: TSCH_ChartArchive) -> ChartGridData? {
    guard chart.hasGrid else {
      return nil
    }

    let grid = chart.grid

    let direction: ChartDataDirection
    if chart.hasSeriesDirection {
      direction = chart.seriesDirection == .byRow ? .byRow : .byColumn
    } else {
      direction = .byRow
    }

    let rowNames = grid.rowName
    let columnNames = grid.columnName

    let rows = grid.gridRow.map { gridRow in
      let values = gridRow.value.map { tschValue -> ChartGridValue in
        parseChartGridValue(from: tschValue)
      }
      return ChartGridRow(values: values)
    }

    return ChartGridData(
      direction: direction,
      rowNames: rowNames,
      columnNames: columnNames,
      rows: rows
    )
  }

  /// Parses a chart grid value from a TSCH grid value.
  ///
  /// - Parameter tschValue: The TSCH grid value.
  /// - Returns: The parsed chart grid value.
  private func parseChartGridValue(from tschValue: TSCH_GridValue) -> ChartGridValue {
    if tschValue.hasNumericValue {
      return .number(tschValue.numericValue)
    }

    if tschValue.hasDateValue {
      return .date(tschValue.dateValue)
    }

    if tschValue.hasDateValue10 {
      return .date(tschValue.dateValue10)
    }

    if tschValue.hasDurationValue {
      return .duration(tschValue.durationValue)
    }

    return .empty
  }

  /// Parses axis information from a chart.
  ///
  /// - Parameters:
  ///   - chart: Chart archive.
  ///   - isValueAxis: Whether to parse the value axis (true) or category axis (false).
  /// - Returns: Chart axis information.
  private func parseChartAxisInfo(
    from chart: TSCH_ChartArchive,
    isValueAxis: Bool
  ) -> ChartAxisInfo {
    var title: String?
    var isVisible = true
    var showLabels = true
    var showMajorGridlines = false
    var showMinorGridlines = false
    var numberFormat: ChartNumberFormat?
    var minimumValue: Double?
    var maximumValue: Double?
    var scale: ChartAxisScale = .linear

    let axisNonStyles = isValueAxis ? chart.valueAxisNonstyles : chart.categoryAxisNonstyles
    let axisStyles = isValueAxis ? chart.valueAxisStyles : chart.categoryAxisStyles

    if let firstNonStyleRef = axisNonStyles.first,
      let axisNonStyle = document.dereference(firstNonStyleRef) as? TSCH_ChartAxisNonStyleArchive
    {
      let props = axisNonStyle.TSCH_Generated_ChartAxisNonStyleArchive_current

      if isValueAxis {
        if props.hasTschchartaxisvaluetitle {
          title = props.tschchartaxisvaluetitle
        }
      } else {
        if props.hasTschchartaxiscategorytitle {
          title = props.tschchartaxiscategorytitle
        }
      }

      if isValueAxis {
        if props.hasTschchartaxisvalueshowlabels {
          showLabels = props.tschchartaxisvalueshowlabels
        }
      } else {
        if props.hasTschchartaxiscategoryshowlabels {
          showLabels = props.tschchartaxiscategoryshowlabels
        }
      }

      if isValueAxis {
        if props.hasTschchartaxisdefaultusermin,
          props.tschchartaxisdefaultusermin.hasNumberArchive
        {
          minimumValue = props.tschchartaxisdefaultusermin.numberArchive
        }
        if props.hasTschchartaxisdefaultusermax,
          props.tschchartaxisdefaultusermax.hasNumberArchive
        {
          maximumValue = props.tschchartaxisdefaultusermax.numberArchive
        }

        if props.hasTschchartaxisvaluescale {
          scale = props.tschchartaxisvaluescale == 1 ? .logarithmic : .linear
        }
      }

      if props.hasTschchartaxisdefaultnumberformat {
        numberFormat = parseChartNumberFormat(from: props.tschchartaxisdefaultnumberformat)
      } else if props.hasTschchartaxisdefaultdateformat {
        numberFormat = parseChartNumberFormat(from: props.tschchartaxisdefaultdateformat)
      } else if props.hasTschchartaxisdefaultdurationformat {
        numberFormat = parseChartNumberFormat(from: props.tschchartaxisdefaultdurationformat)
      }
    }

    if let firstStyleRef = axisStyles.first,
      let axisStyle = document.dereference(firstStyleRef) as? TSCH_ChartAxisStyleArchive
    {
      let props = axisStyle.TSCH_Generated_ChartAxisStyleArchive_current

      if isValueAxis {
        if props.hasTschchartaxisvalueshowaxis {
          isVisible = props.tschchartaxisvalueshowaxis
        }
      } else {
        if props.hasTschchartaxiscategoryshowaxis {
          isVisible = props.tschchartaxiscategoryshowaxis
        }
      }

      if isValueAxis {
        if props.hasTschchartaxisvalueshowmajorgridlines {
          showMajorGridlines = props.tschchartaxisvalueshowmajorgridlines
        }
      } else {
        if props.hasTschchartaxiscategoryshowmajorgridlines {
          showMajorGridlines = props.tschchartaxiscategoryshowmajorgridlines
        }
      }

      if isValueAxis {
        if props.hasTschchartaxisvalueshowminorgridlines {
          showMinorGridlines = props.tschchartaxisvalueshowminorgridlines
        }
      } else {
        if props.hasTschchartaxiscategoryshowminorgridlines {
          showMinorGridlines = props.tschchartaxiscategoryshowminorgridlines
        }
      }
    }

    return ChartAxisInfo(
      title: title,
      isVisible: isVisible,
      showLabels: showLabels,
      showMajorGridlines: showMajorGridlines,
      showMinorGridlines: showMinorGridlines,
      numberFormat: numberFormat,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      scale: scale
    )
  }

  /// Parses number format from a chart number format archive.
  ///
  /// - Parameter format: Format struct archive.
  /// - Returns: Chart number format.
  private func parseChartNumberFormat(from format: TSK_FormatStructArchive) -> ChartNumberFormat {
    let type: ChartNumberFormatType
    if format.hasFormatType {
      switch format.formatType {
      case 0:
        type = .decimal
      case 1:
        type = .currency
      case 2:
        type = .percentage
      case 3:
        type = .scientific
      case 4:
        type = .fraction
      case 5:
        type = .base
      default:
        type = .unknown(Int(format.formatType))
      }
    } else {
      type = .decimal
    }

    let decimalPlaces = format.hasDecimalPlaces ? format.decimalPlaces : 2
    let showThousandsSeparator =
      format.hasShowThousandsSeparator ? format.showThousandsSeparator : false
    let currencyCode = format.hasCurrencyCode ? format.currencyCode : nil
    let base = format.hasBase ? format.base : nil
    let fractionAccuracy = format.hasFractionAccuracy ? format.fractionAccuracy : nil

    var formatString: String?

    if format.hasTSCH_ChartFormatStructExtensions_prefix
      || format.hasTSCH_ChartFormatStructExtensions_suffix
    {
      let prefix = format.TSCH_ChartFormatStructExtensions_prefix
      let suffix = format.TSCH_ChartFormatStructExtensions_suffix
      if !prefix.isEmpty || !suffix.isEmpty {
        formatString = "\(prefix)#\(suffix)"
      }
    }

    if formatString == nil && format.hasCustomFormatString && !format.customFormatString.isEmpty {
      formatString = format.customFormatString
    }

    if formatString == nil && format.hasDateTimeFormat && !format.dateTimeFormat.isEmpty {
      formatString = format.dateTimeFormat
    }

    return ChartNumberFormat(
      type: type,
      decimalPlaces: decimalPlaces,
      showThousandsSeparator: showThousandsSeparator,
      currencyCode: currencyCode,
      formatString: formatString,
      base: base,
      fractionAccuracy: fractionAccuracy
    )
  }

  /// Parses series information from a chart.
  ///
  /// - Parameters:
  ///   - chart: Chart archive.
  ///   - seriesCount: Number of series in the chart.
  /// - Returns: Array of chart series information.
  private func parseChartSeriesInfo(
    from chart: TSCH_ChartArchive,
    seriesCount: Int
  ) -> [ChartSeriesInfo] {
    var seriesInfo: [ChartSeriesInfo] = []

    for seriesIndex in 0..<seriesCount {
      let seriesType = parseChartType(from: chart)
      var fill: ShapeFill = .none
      var stroke: Border?
      var showValueLabels = false
      var valueLabelPosition: ChartValueLabelPosition = .automatic
      var numberFormat: ChartNumberFormat?

      var seriesStyle: TSCH_ChartSeriesStyleArchive?
      if seriesIndex < chart.seriesThemeStyles.count {
        seriesStyle = document.dereference(chart.seriesThemeStyles[seriesIndex])
      } else if chart.hasSeriesPrivateStyles {
        if let entry = chart.seriesPrivateStyles.entries.first(where: {
          $0.index == UInt32(seriesIndex)
        }) {
          seriesStyle = document.dereference(entry.reference)
        }
      }

      if let style = seriesStyle {
        let props = style.TSCH_Generated_ChartSeriesStyleArchive_current

        switch seriesType {
        case .bar2D, .bar3D:
          if props.hasTschchartseriesbarfill {
            fill = parseShapeFill(from: props.tschchartseriesbarfill)
          }
          if props.hasTschchartseriesbarstroke {
            stroke = createBorderFromStroke(props.tschchartseriesbarstroke)
          }
          if props.hasTschchartseriesbarvaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartseriesbarvaluelabelposition)
          }

        case .column2D, .column3D:
          if props.hasTschchartseriescolumnfill {
            fill = parseShapeFill(from: props.tschchartseriescolumnfill)
          }
          if props.hasTschchartseriesdefaultvaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartseriesdefaultvaluelabelposition)
          }

        case .line2D, .line3D:
          if props.hasTschchartserieslinestroke {
            stroke = createBorderFromStroke(props.tschchartserieslinestroke)
          }
          if props.hasTschchartserieslinesymbolfill {
            fill = parseShapeFill(from: props.tschchartserieslinesymbolfill)
          }
          if props.hasTschchartserieslinevaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartserieslinevaluelabelposition)
          }

        case .area2D, .area3D:
          if props.hasTschchartseriesareafill {
            fill = parseShapeFill(from: props.tschchartseriesareafill)
          }
          if props.hasTschchartseriesareastroke {
            stroke = createBorderFromStroke(props.tschchartseriesareastroke)
          }
          if props.hasTschchartseriesareavaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartseriesareavaluelabelposition)
          }

        case .pie2D, .pie3D, .donut2D:
          if props.hasTschchartseriespiefill {
            fill = parseShapeFill(from: props.tschchartseriespiefill)
          }
          if props.hasTschchartseriespiestroke {
            stroke = createBorderFromStroke(props.tschchartseriespiestroke)
          }

        case .scatter2D:
          if props.hasTschchartseriesscatterstroke {
            stroke = createBorderFromStroke(props.tschchartseriesscatterstroke)
          }
          if props.hasTschchartseriesscattersymbolfill {
            fill = parseShapeFill(from: props.tschchartseriesscattersymbolfill)
          }
          if props.hasTschchartseriesscattervaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartseriesscattervaluelabelposition)
          }

        case .bubble2D:
          if props.hasTschchartseriesbubblesymbolfill {
            fill = parseShapeFill(from: props.tschchartseriesbubblesymbolfill)
          }
          if props.hasTschchartseriesbubblestroke {
            stroke = createBorderFromStroke(props.tschchartseriesbubblestroke)
          }
          if props.hasTschchartseriesbubblevaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartseriesbubblevaluelabelposition)
          }

        default:
          if props.hasTschchartseriesdefaultfill {
            fill = parseShapeFill(from: props.tschchartseriesdefaultfill)
          }
          if props.hasTschchartseriesdefaultvaluelabelposition {
            valueLabelPosition = parseValueLabelPosition(
              props.tschchartseriesdefaultvaluelabelposition)
          }
        }
      }

      var seriesNonStyle: TSCH_ChartSeriesNonStyleArchive?
      if chart.hasSeriesNonStyles {
        if let entry = chart.seriesNonStyles.entries.first(where: {
          $0.index == UInt32(seriesIndex)
        }) {
          seriesNonStyle = document.dereference(entry.reference)
        }
      }

      if let nonStyle = seriesNonStyle {
        let props = nonStyle.TSCH_Generated_ChartSeriesNonStyleArchive_current

        switch seriesType {
        case .bar2D, .bar3D:
          if props.hasTschchartseriesbarshowvaluelabels {
            showValueLabels = props.tschchartseriesbarshowvaluelabels
          }

        case .line2D, .line3D:
          if props.hasTschchartserieslineshowvaluelabels {
            showValueLabels = props.tschchartserieslineshowvaluelabels
          }

        case .area2D, .area3D:
          if props.hasTschchartseriesareashowvaluelabels {
            showValueLabels = props.tschchartseriesareashowvaluelabels
          }

        case .pie2D, .pie3D, .donut2D:
          if props.hasTschchartseriespieshowvaluelabels {
            showValueLabels = props.tschchartseriespieshowvaluelabels
          }

        case .scatter2D:
          if props.hasTschchartseriesscattershowvaluelabels {
            showValueLabels = props.tschchartseriesscattershowvaluelabels
          }

        case .bubble2D:
          if props.hasTschchartseriesbubbleshowvaluelabels {
            showValueLabels = props.tschchartseriesbubbleshowvaluelabels
          }

        default:
          if props.hasTschchartseriesdefaultshowvaluelabels {
            showValueLabels = props.tschchartseriesdefaultshowvaluelabels
          }
        }

        if props.hasTschchartseriesdefaultnumberformat {
          numberFormat = parseChartNumberFormat(from: props.tschchartseriesdefaultnumberformat)
        } else if props.hasTschchartseriesdefaultdateformat {
          numberFormat = parseChartNumberFormat(from: props.tschchartseriesdefaultdateformat)
        } else if props.hasTschchartseriesdefaultdurationformat {
          numberFormat = parseChartNumberFormat(from: props.tschchartseriesdefaultdurationformat)
        }
      }

      let info = ChartSeriesInfo(
        seriesType: seriesType,
        fill: fill,
        stroke: stroke,
        showValueLabels: showValueLabels,
        valueLabelPosition: valueLabelPosition,
        numberFormat: numberFormat
      )

      seriesInfo.append(info)
    }

    return seriesInfo
  }

  /// Parses value label position from a raw value.
  ///
  /// - Parameter rawValue: Raw position value.
  /// - Returns: Chart value label position.
  private func parseValueLabelPosition(_ rawValue: Int32) -> ChartValueLabelPosition {
    switch rawValue {
    case 0:
      return .automatic
    case 1:
      return .center
    case 2:
      return .insideEnd
    case 3:
      return .insideBase
    case 4:
      return .outside
    case 5:
      return .outsideEnd
    default:
      return .unknown(Int(rawValue))
    }
  }

  /// Parses legend information from a chart.
  ///
  /// - Parameter chart: Chart archive.
  /// - Returns: Chart legend information.
  private func parseChartLegendInfo(from chart: TSCH_ChartArchive) -> ChartLegendInfo {
    var isVisible = true
    var fill: ShapeFill = .none
    var stroke: Border?
    var spatialInfo: SpatialInfo?

    if chart.hasChartNonStyle,
      let nonStyle: TSCH_ChartNonStyleArchive = document.dereference(chart.chartNonStyle)
    {
      let props = nonStyle.TSCH_Generated_ChartNonStyleArchive_current
      if props.hasTschchartinfodefaultshowlegend {
        isVisible = props.tschchartinfodefaultshowlegend
      }
    }

    if chart.hasLegendStyle,
      let style: TSCH_LegendStyleArchive = document.dereference(chart.legendStyle)
    {
      let props = style.TSCH_Generated_LegendStyleArchive_current

      if props.hasTschlegendmodeldefaultfill {
        fill = parseShapeFill(from: props.tschlegendmodeldefaultfill)
      }
      if props.hasTschlegendmodeldefaultstroke {
        stroke = createBorderFromStroke(props.tschlegendmodeldefaultstroke)
      }
    }

    if chart.hasLegendFrame {
      let frame = chart.legendFrame

      if frame.hasOrigin && frame.hasSize {
        let rect = CGRect(
          x: CGFloat(frame.origin.x),
          y: CGFloat(frame.origin.y),
          width: CGFloat(frame.size.width),
          height: CGFloat(frame.size.height)
        )

        spatialInfo = SpatialInfo(
          coordinateSpace: .floating,
          frame: rect,
          rotation: 0,
          zIndex: nil,
          isAnchoredToText: false,
          isFloatingAboveText: false
        )
      }
    }

    return ChartLegendInfo(
      isVisible: isVisible,
      fill: fill,
      stroke: stroke,
      spatialInfo: spatialInfo
    )
  }

  // MARK: - Spatial Info Creation

  /// Creates spatial positioning information from a drawable archive.
  ///
  /// - Parameters:
  ///   - drawable: Base drawable archive containing geometry.
  ///   - coordinateSpace: Coordinate system for positioning.
  ///   - drawableID: Unique identifier for z-index lookup.
  /// - Returns: Spatial information including frame, rotation, and layering.
  private func parseSpatialInfo(
    from drawable: TSD_DrawableArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) -> SpatialInfo {
    let frame = parseFrame(from: drawable.geometry)
    let rotation = Double(drawable.geometry.angle)
    let zIndex = drawableID.flatMap { getZIndex(for: $0) }

    let isAnchoredToText: Bool
    let isFloatingAboveText: Bool

    if drawable.hasExteriorTextWrap {
      let wrap = drawable.exteriorTextWrap
      isFloatingAboveText = wrap.type == 1
      isAnchoredToText = wrap.type == 0
    } else {
      isAnchoredToText = false
      isFloatingAboveText = false
    }

    return SpatialInfo(
      coordinateSpace: coordinateSpace,
      frame: frame,
      rotation: rotation,
      zIndex: zIndex,
      isAnchoredToText: isAnchoredToText,
      isFloatingAboveText: isFloatingAboveText
    )
  }

  /// Parses position and size from geometry.
  ///
  /// - Parameter geometry: Geometry archive.
  /// - Returns: Frame rectangle.
  private func parseFrame(from geometry: TSD_GeometryArchive?) -> CGRect {
    guard let geometry = geometry else {
      return .zero
    }

    let position = CGPoint(
      x: CGFloat(geometry.position.x),
      y: CGFloat(geometry.position.y)
    )

    let size = CGSize(
      width: CGFloat(geometry.size.width),
      height: CGFloat(geometry.size.height)
    )

    return CGRect(origin: position, size: size)
  }

  // MARK: - 3D Object Detection

  /// Checks if a movie archive contains 3D object data.
  ///
  /// - Parameter movie: Movie archive to check.
  /// - Returns: True if this is a 3D object, false if it's regular media.
  private func is3DObject(from movie: TSD_MovieArchive) -> Bool {
    return movie.hasTSA_Object3DInfo_object3DInfo
  }

  // MARK: - 3D Object Data Parsing

  /// Parses the 3D object info from a movie archive's extension data.
  ///
  /// - Parameters:
  ///   - movie: Movie archive containing 3D object extension.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  ///   - drawableID: Unique identifier of the 3D object.
  /// - Returns: Complete 3D object information, or nil if parsing fails.
  /// - Throws: Errors from reading 3D model files.
  private func parse3DObjectData(
    from movie: TSD_MovieArchive,
    coordinateSpace: CoordinateSpace,
    drawableID: UInt64?
  ) throws -> (info: Object3DInfo, spatialInfo: SpatialInfo, filepath: String)? {
    guard is3DObject(from: movie) else {
      return nil
    }

    let object3DInfo = movie.TSA_Object3DInfo_object3DInfo

    guard let dataID = parseMediaDataID(from: movie),
      let metadata: TSP_PackageMetadata = document.record(id: 2),
      let resolvedFile = resolveFile(from: metadata, dataID: dataID),
      let filename = resolvedFile.0,
      let filepath = resolvedFile.1
    else {
      print("3D object missing model file")
      return nil
    }

    print("\(filename)")

    let pose: Pose3D
    if object3DInfo.hasPose3D {
      let poseArchive = object3DInfo.pose3D
      pose = Pose3D(
        yaw: poseArchive.yaw,
        pitch: poseArchive.pitch,
        roll: poseArchive.roll
      )
    } else {
      pose = .identity
    }

    let boundingRect: CGRect
    if object3DInfo.hasBoundingRect {
      let rectArchive = object3DInfo.boundingRect
      boundingRect = CGRect(
        x: CGFloat(rectArchive.origin.x),
        y: CGFloat(rectArchive.origin.y),
        width: CGFloat(rectArchive.size.width),
        height: CGFloat(rectArchive.size.height)
      )
    } else {
      boundingRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    let playsAnimations = object3DInfo.playsAnimations
    let hasEmbeddedAnimations = object3DInfo.embeddedAnimations

    let thumbnailImage: ImageInfo?
    if object3DInfo.hasThumbnailImageData {
      thumbnailImage = try parseThumbnailImage(from: object3DInfo, coordinateSpace: coordinateSpace)
    } else {
      thumbnailImage = nil
    }

    let tracedPath: BezierPath?
    if object3DInfo.hasTracedPath {
      tracedPath = parseTracedPath(from: object3DInfo.tracedPath)
    } else {
      tracedPath = nil
    }

    let captionInfo = parseMediaCaptionInfo(from: movie, coordinateSpace: coordinateSpace)

    let hyperlink: Hyperlink?
    if movie.hasSuper && movie.super.hasHyperlinkURL {
      hyperlink = Hyperlink(text: filename, url: movie.super.hyperlinkURL, range: 0..<0)
    } else {
      hyperlink = nil
    }

    let info = Object3DInfo(
      filename: filename,
      filepath: filepath,
      pose: pose,
      boundingRect: boundingRect,
      playsAnimations: playsAnimations,
      hasEmbeddedAnimations: hasEmbeddedAnimations,
      thumbnailImage: thumbnailImage,
      tracedPath: tracedPath,
      title: captionInfo.title,
      caption: captionInfo.caption,
      hyperlink: hyperlink
    )

    let spatialInfo = parseSpatialInfo(
      from: movie.super,
      coordinateSpace: coordinateSpace,
      drawableID: drawableID
    )

    return (info: info, spatialInfo: spatialInfo, filepath: filepath)
  }

  /// Parses thumbnail image from 3D object info.
  ///
  /// - Parameters:
  ///   - object3DInfo: 3D object info archive.
  ///   - coordinateSpace: Coordinate system for spatial positioning.
  /// - Returns: Thumbnail image info, or nil if not available.
  /// - Throws: Errors from reading image files.
  private func parseThumbnailImage(
    from object3DInfo: TSA_Object3DInfo,
    coordinateSpace: CoordinateSpace
  ) throws -> ImageInfo? {
    guard object3DInfo.hasThumbnailImageData,
      object3DInfo.thumbnailImageData.hasIdentifier
    else {
      return nil
    }

    let dataID = object3DInfo.thumbnailImageData.identifier

    guard let metadata: TSP_PackageMetadata = document.record(id: 2),
      let resolvedFile = resolveFile(from: metadata, dataID: dataID),
      let filename = resolvedFile.0,
      let filepath = resolvedFile.1
    else {
      return nil
    }

    let info = ImageInfo(
      width: 0,
      height: 0,
      filename: filename,
      description: nil,
      filepath: filepath,
      title: nil,
      caption: nil
    )

    return info
  }

  /// Parses a traced path from a TSP_Path archive.
  ///
  /// - Parameter pathArchive: The path archive to parse from.
  /// - Returns: A Bézier path, or nil if parsing fails.
  private func parseTracedPath(from pathArchive: TSP_Path) -> BezierPath? {
    let elements = pathArchive.elements.map { element -> PathElement in
      let type: PathElementType
      switch element.type {
      case .moveTo:
        type = .moveTo
      case .lineTo:
        type = .lineTo
      case .quadCurveTo:
        type = .quadCurveTo
      case .curveTo:
        type = .curveTo
      case .closeSubpath:
        type = .closeSubpath
      }

      let points = element.points.map { point in
        PathPoint(x: Double(point.x), y: Double(point.y))
      }

      return PathElement(type: type, points: points)
    }

    let naturalSize = CGSize.zero

    return BezierPath(elements: elements, naturalSize: naturalSize)
  }

  // MARK: - Archive Reading

  /// Reads file data from the document archive.
  ///
  /// - Parameter path: The path to the file within the archive.
  /// - Returns: The file data.
  /// - Throws: Errors from reading the archive.
  private func readFileFromArchive(path: String) throws -> Data {
    return try document.storage.readData(from: path)
  }

  // MARK: - Sequential Content Processing

  /// Internal representation of positioned content within a paragraph.
  private enum PositionedContent {
    case inlineElement(position: Int, element: InlineElement)
    case table(position: Int, reference: TSP_Reference)
    case shape(position: Int, reference: TSP_Reference)
  }
}
