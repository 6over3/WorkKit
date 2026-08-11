import Foundation
import SwiftProtobuf

// MARK: - Style Resolution

/// Functions for resolving and extracting style properties from iWork archives.
///
/// This module handles the complex style inheritance chain resolution and property
/// extraction.
package enum StyleResolver {
  /// A child style uses this sentinel to clear an inherited outline level.
  private static let undefinedOutlineLevel = UInt32.max

  // MARK: - Style Chain Building

  /// Builds the complete inheritance chain for a paragraph style.
  ///
  /// Walks up the parent hierarchy to build a complete chain from root to leaf.
  /// The chain is ordered from most general (root) to most specific (leaf).
  ///
  /// - Parameters:
  ///   - style: The starting paragraph style (may be nil).
  ///   - document: Document for dereferencing parent references.
  /// - Returns: Array of styles from root to leaf, or empty if style is nil.
  static func buildParagraphStyleChain(
    _ style: TSWP_ParagraphStyleArchive?,
    document: IWorkDocument
  ) -> [TSWP_ParagraphStyleArchive] {
    guard let style = style else { return [] }

    var chain: [TSWP_ParagraphStyleArchive] = []
    var current: TSWP_ParagraphStyleArchive? = style

    // Build chain from leaf to root
    while let s = current {
      chain.append(s)

      if s.super.hasParent,
        let parentRef = s.super.parent as TSP_Reference?,
        let parent = document.dereference(parentRef) as? TSWP_ParagraphStyleArchive
      {
        current = parent
      } else {
        current = nil
      }
    }

    // Reverse to get root-to-leaf order
    return chain.reversed()
  }

  /// Builds the complete inheritance chain for a character style.
  static func buildCharacterStyleChain(
    _ style: TSWP_CharacterStyleArchive?,
    document: IWorkDocument
  ) -> [TSWP_CharacterStyleArchive] {
    guard let style = style else { return [] }

    var chain: [TSWP_CharacterStyleArchive] = []
    var current: TSWP_CharacterStyleArchive? = style

    while let s = current {
      chain.append(s)

      if s.super.hasParent,
        let parentRef = s.super.parent as TSP_Reference?,
        let parent = document.dereference(parentRef) as? TSWP_CharacterStyleArchive
      {
        current = parent
      } else {
        current = nil
      }
    }

    return chain.reversed()
  }

  static func buildMediaStyleChain(
    _ style: TSD_MediaStyleArchive?,
    document: IWorkDocument
  ) -> [TSD_MediaStyleArchive] {
    guard let style = style else { return [] }

    var chain: [TSD_MediaStyleArchive] = []
    var current: TSD_MediaStyleArchive? = style

    while let s = current {
      chain.append(s)

      if s.super.hasParent,
        let parentRef = s.super.parent as TSP_Reference?,
        let parent = document.dereference(parentRef) as? TSD_MediaStyleArchive
      {
        current = parent
      } else {
        current = nil
      }
    }

    return chain.reversed()
  }

  /// Builds the complete inheritance chain for a cell style.
  static func buildCellStyleChain(
    _ style: TST_CellStyleArchive?,
    document: IWorkDocument
  ) -> [TST_CellStyleArchive] {
    guard let style = style else { return [] }

    var chain: [TST_CellStyleArchive] = []
    var current: TST_CellStyleArchive? = style

    while let s = current {
      chain.append(s)

      if s.super.hasParent,
        let parentRef = s.super.parent as TSP_Reference?,
        let parent = document.dereference(parentRef) as? TST_CellStyleArchive
      {
        current = parent
      } else {
        current = nil
      }
    }

    return chain.reversed()
  }

  // MARK: - Paragraph Style Resolution

  /// Extracts complete paragraph properties from a style chain.
  ///
  /// Properties are resolved by traversing the chain from root to leaf,
  /// with later styles overriding earlier ones.
  ///
  /// - Parameters:
  ///   - chain: Complete style chain from root to leaf.
  ///   - listStyleArchive: Optional list style to extract list properties.
  ///   - listLevel: The list nesting level (from para data).
  /// - Returns: Complete paragraph style with all resolved properties.
  static func extractParagraphProperties(
    from chain: [TSWP_ParagraphStyleArchive],
    listStyleArchive: TSWP_ListStyleArchive?,
    listLevel: Int
  ) -> ParagraphStyle {
    var alignment: TextAlignment = .left
    var leftIndent: Double = 0
    var rightIndent: Double = 0
    var firstLineIndent: Double = 0
    var spaceBefore: Double = 0
    var spaceAfter: Double = 0
    var lineSpacing: LineSpacingMode? = nil
    var tabs: [TabStop]? = nil
    var defaultTabInterval: Double? = nil
    var border: ParagraphBorder? = nil
    var outlineLevel: UInt32? = nil
    var keepLinesTogether: Bool = false
    var keepWithNext: Bool = false
    var pageBreakBefore: Bool = false
    var widowControl: Bool = true
    var writingDirection: WritingDirection? = nil
    var listStyle: ListStyle = .none

    for style in chain {
      let props = style.paraProperties

      if props.hasAlignment {
        alignment = StyleConverters.convertTextAlignment(props.alignment)
      }
      if props.hasLeftIndent {
        leftIndent = Double(props.leftIndent)
      }
      if props.hasRightIndent {
        rightIndent = Double(props.rightIndent)
      }
      if props.hasFirstLineIndent {
        firstLineIndent = Double(props.firstLineIndent)
      }
      if props.hasSpaceBefore {
        spaceBefore = Double(props.spaceBefore)
      }
      if props.hasSpaceAfter {
        spaceAfter = Double(props.spaceAfter)
      }
      if props.hasLineSpacing {
        lineSpacing = StyleConverters.convertLineSpacing(props.lineSpacing)
      }
      if props.hasTabs {
        tabs = StyleConverters.convertTabs(props.tabs)
      }
      if props.hasDefaultTabStops {
        defaultTabInterval = Double(props.defaultTabStops)
      }
      if props.hasStroke {
        border = StyleConverters.convertParagraphBorder(
          stroke: props.stroke,
          positions: props.borderPositions,
          hasRoundedCorners: props.roundedCorners
        )
      }
      if props.hasOutlineLevel {
        outlineLevel =
          props.outlineLevel == undefinedOutlineLevel
          ? nil
          : props.outlineLevel
      }
      if props.hasKeepLinesTogether {
        keepLinesTogether = props.keepLinesTogether
      }
      if props.hasKeepWithNext {
        keepWithNext = props.keepWithNext
      }
      if props.hasPageBreakBefore {
        pageBreakBefore = props.pageBreakBefore
      }
      if props.hasWidowControl {
        widowControl = props.widowControl
      }
      if props.hasWritingDirection {
        writingDirection = StyleConverters.convertWritingDirection(props.writingDirection)
      }
    }

    if let listStyleArchive = listStyleArchive {
      listStyle = StyleConverters.convertListStyle(listStyleArchive, level: listLevel)
    }

    return ParagraphStyle(
      alignment: alignment,
      leftIndent: leftIndent,
      rightIndent: rightIndent,
      firstLineIndent: firstLineIndent,
      spaceBefore: spaceBefore,
      spaceAfter: spaceAfter,
      lineSpacing: lineSpacing,
      tabs: tabs,
      defaultTabInterval: defaultTabInterval,
      border: border,
      outlineLevel: outlineLevel,
      keepLinesTogether: keepLinesTogether,
      keepWithNext: keepWithNext,
      pageBreakBefore: pageBreakBefore,
      widowControl: widowControl,
      writingDirection: writingDirection,
      listStyle: listStyle,
      listLevel: listLevel,
      listItemNumber: nil
    )
  }

  // MARK: - Character Style Resolution

  /// Extracts complete character properties from a paragraph style chain.
  ///
  /// Paragraph styles can contain character-level properties that serve as defaults.
  static func extractCharacterPropertiesFromParagraphStyle(
    from chain: [TSWP_ParagraphStyleArchive]
  ) -> CharacterStyle {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
    var fontSize: Double? = nil
    var fontName: String? = nil
    var color: Color? = nil
    var backgroundColor: Color? = nil
    var baselineShift: Double? = nil
    var shadow: TextShadow? = nil
    var tracking: Double? = nil
    var writingDirection: WritingDirection? = nil

    for style in chain {
      let props = style.charProperties

      if props.hasBold {
        isBold = props.bold
      }
      if props.hasItalic {
        isItalic = props.italic
      }
      if props.hasUnderline {
        isUnderline = props.underline != .kNoUnderline
      }
      if props.hasStrikethru {
        isStrikethrough = props.strikethru != .kNoStrikethru
      }
      if props.hasFontSize {
        fontSize = Double(props.fontSize)
      }
      if props.hasFontName {
        fontName = props.fontName
      }
      if props.hasFontColor {
        color = StyleConverters.convertColor(props.fontColor)
      }
      if props.hasBackgroundColor {
        backgroundColor = StyleConverters.convertColor(props.backgroundColor)
      }
      if props.hasBaselineShift {
        baselineShift = Double(props.baselineShift)
      }
      if props.hasShadow {
        shadow = StyleConverters.convertTextShadow(props.shadow)
      }
      if props.hasTracking {
        tracking = Double(props.tracking)
      }
      if props.hasWritingDirection {
        writingDirection = StyleConverters.convertWritingDirection(props.writingDirection)
      }
    }

    return CharacterStyle(
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      fontSize: fontSize,
      fontName: fontName,
      color: color,
      backgroundColor: backgroundColor,
      baselineShift: baselineShift,
      shadow: shadow,
      tracking: tracking,
      writingDirection: writingDirection
    )
  }

  /// Extracts complete character properties from a character style chain.
  static func extractCharacterPropertiesFromCharacterStyle(
    from chain: [TSWP_CharacterStyleArchive]
  ) -> CharacterStyle {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
    var fontSize: Double? = nil
    var fontName: String? = nil
    var color: Color? = nil
    var backgroundColor: Color? = nil
    var baselineShift: Double? = nil
    var shadow: TextShadow? = nil
    var tracking: Double? = nil
    var writingDirection: WritingDirection? = nil

    for style in chain {
      let props = style.charProperties

      if props.hasBold {
        isBold = props.bold
      }
      if props.hasItalic {
        isItalic = props.italic
      }
      if props.hasUnderline {
        isUnderline = props.underline != .kNoUnderline
      }
      if props.hasStrikethru {
        isStrikethrough = props.strikethru != .kNoStrikethru
      }
      if props.hasFontSize {
        fontSize = Double(props.fontSize)
      }
      if props.hasFontName {
        fontName = props.fontName
      }
      if props.hasFontColor {
        color = StyleConverters.convertColor(props.fontColor)
      }
      if props.hasBackgroundColor {
        backgroundColor = StyleConverters.convertColor(props.backgroundColor)
      }
      if props.hasBaselineShift {
        baselineShift = Double(props.baselineShift)
      }
      if props.hasShadow {
        shadow = StyleConverters.convertTextShadow(props.shadow)
      }
      if props.hasTracking {
        tracking = Double(props.tracking)
      }
      if props.hasWritingDirection {
        writingDirection = StyleConverters.convertWritingDirection(props.writingDirection)
      }
    }

    return CharacterStyle(
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      fontSize: fontSize,
      fontName: fontName,
      color: color,
      backgroundColor: backgroundColor,
      baselineShift: baselineShift,
      shadow: shadow,
      tracking: tracking,
      writingDirection: writingDirection
    )
  }

  /// Merges a base character style with a character style overlay.
  ///
  /// Properties from the overlay take precedence, but missing properties
  /// fall back to the base style.
  static func mergeCharacterStyles(
    base: CharacterStyle,
    overlay: CharacterStyle
  ) -> CharacterStyle {
    CharacterStyle(
      isBold: overlay.isBold,
      isItalic: overlay.isItalic,
      isUnderline: overlay.isUnderline,
      isStrikethrough: overlay.isStrikethrough,
      fontSize: overlay.fontSize ?? base.fontSize,
      fontName: overlay.fontName ?? base.fontName,
      color: overlay.color ?? base.color,
      backgroundColor: overlay.backgroundColor ?? base.backgroundColor,
      baselineShift: overlay.baselineShift ?? base.baselineShift,
      shadow: overlay.shadow ?? base.shadow,
      tracking: overlay.tracking ?? base.tracking,
      writingDirection: overlay.writingDirection ?? base.writingDirection
    )
  }

  // MARK: - Cell Style Resolution

  /// Extracts complete cell style properties from a style chain.
  static func extractCellStyleProperties(
    from chain: [TST_CellStyleArchive]
  ) -> CellStyle {
    var backgroundColor: Color? = nil
    var backgroundGradient: [Color]? = nil
    var verticalAlignment: CellStyle.VerticalAlignment = .top
    var padding = CellStyle.CellPadding()
    var textWrap: Bool = true

    for style in chain {
      let props = style.cellProperties

      if props.hasCellFill {
        if props.cellFill.hasColor {
          backgroundColor = StyleConverters.convertColor(props.cellFill.color)
          backgroundGradient = nil
        } else if props.cellFill.hasGradient {
          backgroundGradient = props.cellFill.gradient.stops.map {
            StyleConverters.convertColor($0.color)
          }
          backgroundColor = nil
        }
      }

      if props.hasVerticalAlignment {
        verticalAlignment = StyleConverters.convertVerticalAlignment(
          props.verticalAlignment)
      }

      if props.hasPadding {
        padding = CellStyle.CellPadding(
          top: Double(props.padding.top),
          right: Double(props.padding.right),
          bottom: Double(props.padding.bottom),
          left: Double(props.padding.left)
        )
      }

      if props.hasTextWrap {
        textWrap = props.textWrap
      }
    }

    return CellStyle(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      verticalAlignment: verticalAlignment,
      padding: padding,
      textWrap: textWrap
    )
  }

  /// Extracts complete media style properties from a style chain.
  static func extractMediaProperties(
    from chain: [TSD_MediaStyleArchive],
    mask: Mask? = nil
  ) -> MediaStyle {
    var border: Border? = nil
    var opacity: Double = 1.0
    var shadow: Shadow? = nil
    var reflectionOpacity: Double? = nil

    for style in chain {
      let props = style.mediaProperties

      if props.hasStroke {
        border = StyleConverters.convertStroke(props.stroke)
      }
      if props.hasOpacity {
        opacity = Double(props.opacity)
      }
      if props.hasShadow {
        shadow = StyleConverters.convertShadow(props.shadow)
      }
      if props.hasReflection {
        reflectionOpacity = Double(props.reflection.opacity)
      }
    }

    return MediaStyle(
      border: border,
      opacity: opacity,
      shadow: shadow,
      reflectionOpacity: reflectionOpacity,
      mask: mask
    )
  }
}

// MARK: - Style Converters

/// Pure conversion functions from protobuf types to public API types.
internal enum StyleConverters {

  // MARK: - Text Alignment

  static func convertTextAlignment(
    _ alignment: TSWP_ParagraphStylePropertiesArchive.TextAlignmentType
  ) -> TextAlignment {
    switch alignment {
    case .tatvalue0: return .left
    case .tatvalue1: return .right
    case .tatvalue2: return .center
    case .tatvalue3: return .justified
    case .tatvalue4: return .natural
    }
  }

  // MARK: - Line Spacing

  static func convertLineSpacing(_ lineSpacing: TSWP_LineSpacingArchive) -> LineSpacingMode {
    let amount = Double(lineSpacing.amount)

    switch lineSpacing.mode {
    case .kRelativeLineSpacing:
      return .relative(amount)
    case .kMinimumLineSpacing:
      return .minimum(amount)
    case .kExactLineSpacing:
      return .exact(amount)
    case .kMaximumLineSpacing:
      return .maximum(amount)
    case .kSpaceBetweenLineSpacing:
      return .between(amount)
    }
  }

  // MARK: - Tab Stops

  static func convertTabs(_ tabs: TSWP_TabsArchive) -> [TabStop] {
    tabs.tabs.map { tab in
      TabStop(
        position: Double(tab.position),
        alignment: convertTabAlignment(tab.alignment),
        leader: tab.hasLeader ? tab.leader : nil
      )
    }
  }

  static func convertTabAlignment(_ alignment: TSWP_TabArchive.TabAlignmentType)
    -> TabStop.TabAlignment
  {
    switch alignment {
    case .kTabAlignmentLeft: return .left
    case .kTabAlignmentCenter: return .center
    case .kTabAlignmentRight: return .right
    case .kTabAlignmentDecimal: return .decimal
    }
  }

  // MARK: - Paragraph Border

  static func convertParagraphBorder(
    stroke: TSD_StrokeArchive,
    positions: Int32,
    hasRoundedCorners: Bool
  ) -> ParagraphBorder? {
    let border = Border(
      width: Double(stroke.width),
      color: convertColor(stroke.color),
      style: convertBorderStyle(stroke.pattern)
    )

    var edges: ParagraphBorder.BorderEdges = []
    if positions & 1 != 0 { edges.insert(.top) }
    if positions & 2 != 0 { edges.insert(.right) }
    if positions & 4 != 0 { edges.insert(.bottom) }
    if positions & 8 != 0 { edges.insert(.left) }

    guard !edges.isEmpty else { return nil }

    return ParagraphBorder(
      stroke: border,
      edges: edges,
      hasRoundedCorners: hasRoundedCorners
    )
  }

  // MARK: - Writing Direction

  static func convertWritingDirection(_ direction: TSWP_WritingDirectionType) -> WritingDirection {
    switch direction {
    case .kWritingDirectionNatural: return .natural
    case .kWritingDirectionLeftToRight: return .leftToRight
    case .kWritingDirectionRightToLeft: return .rightToLeft
    }
  }

  static func convertStroke(_ stroke: TSD_StrokeArchive) -> Border {
    return Border(
      width: Double(stroke.width),
      color: convertColor(stroke.color),
      style: convertBorderStyle(stroke.pattern)
    )
  }

  // MARK: - Shadow

  static func convertTextShadow(_ shadow: TSD_ShadowArchive) -> TextShadow {
    let angleRadians = Double(shadow.angle) * .pi / 180.0
    let offset = Double(shadow.offset)

    let offsetX = offset * cos(angleRadians)
    let offsetY = offset * sin(angleRadians)

    return TextShadow(
      offsetX: offsetX,
      offsetY: offsetY,
      blurRadius: Double(shadow.radius),
      color: convertColor(shadow.color),
      opacity: Double(shadow.opacity)
    )
  }

  static func convertShadow(_ shadow: TSD_ShadowArchive) -> Shadow {
    let angleRadians = Double(shadow.angle) * .pi / 180.0
    let offset = Double(shadow.offset)

    let offsetX = offset * cos(angleRadians)
    let offsetY = offset * sin(angleRadians)

    return Shadow(
      offsetX: offsetX,
      offsetY: offsetY,
      blurRadius: Double(shadow.radius),
      color: convertColor(shadow.color),
      opacity: Double(shadow.opacity)
    )
  }

  // MARK: - Color

  static func convertColor(_ color: TSP_Color) -> Color {
    Color(
      red: Double(color.r),
      green: Double(color.g),
      blue: Double(color.b),
      alpha: Double(color.a)
    )
  }

  // MARK: - Border Style

  static func convertBorderStyle(_ pattern: TSD_StrokePatternArchive) -> BorderStyle {
    switch pattern.type {
    case .tsdsolidPattern:
      return .solid
    case .tsdpattern:
      if pattern.pattern.count > 0 && pattern.pattern[0] < 1.0 {
        return .dots
      }
      return .dashes
    case .tsdemptyPattern:
      return .none
    }
  }

  // MARK: - Vertical Alignment

  static func convertVerticalAlignment(_ alignment: Int32) -> CellStyle.VerticalAlignment {
    switch alignment {
    case 0: return .top
    case 1: return .middle
    case 2: return .bottom
    default: return .top
    }
  }

  // MARK: - List Style

  static func convertListStyle(_ listStyle: TSWP_ListStyleArchive, level: Int) -> ListStyle {
    guard level >= 0 && level < listStyle.labelTypes.count else {
      return .none
    }

    let labelType = listStyle.labelTypes[level]

    switch labelType {
    case .kString:
      if level < listStyle.strings.count {
        return .bullet(listStyle.strings[level])
      }
      return .none

    case .kNumber:
      if level < listStyle.numberTypes.count {
        return .numbered(convertListNumberStyle(listStyle.numberTypes[level]))
      }
      return .none

    case .kImage, .kNone:
      return .none
    }
  }

  static func convertListNumberStyle(_ numberType: TSWP_ListStyleArchive.NumberType)
    -> ListStyle.ListNumberStyle
  {
    switch numberType {
    case .kNumericDecimal: return .numeric
    case .kNumericRightParen: return .numericParen
    case .kNumericDoubleParen: return .numericDoubleParen
    case .kRomanUpperDecimal: return .romanUpper
    case .kRomanUpperRightParen: return .romanUpperParen
    case .kRomanUpperDoubleParen: return .romanUpperDoubleParen
    case .kRomanLowerDecimal: return .romanLower
    case .kRomanLowerRightParen: return .romanLowerParen
    case .kRomanLowerDoubleParen: return .romanLowerDoubleParen
    case .kAlphaUpperDecimal: return .alphaUpper
    case .kAlphaUpperRightParen: return .alphaUpperParen
    case .kAlphaUpperDoubleParen: return .alphaUpperDoubleParen
    case .kAlphaLowerDecimal: return .alphaLower
    case .kAlphaLowerRightParen: return .alphaLowerParen
    case .kAlphaLowerDoubleParen: return .alphaLowerDoubleParen
    default: return .numeric
    }
  }
}
