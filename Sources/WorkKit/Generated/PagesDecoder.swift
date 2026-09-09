import Foundation
import SwiftProtobuf

package func decodePages(type: UInt32, data: Data) throws -> SwiftProtobuf.Message {
  switch type {
  case 10160:
    return try TP_AllFootnoteSelectionArchive(serializedBytes: data)
  case 10164:
    return try TP_AllFootnoteSelectionTransformerArchive(serializedBytes: data)
  case 10132:
    return try TP_CanvasSelectionArchive(serializedBytes: data)
  case 10163:
    return try TP_CanvasSelectionTransformerArchive(serializedBytes: data)
  case 10114:
    return try TP_ChangeFootnoteFormatCommandArchive(serializedBytes: data)
  case 10115:
    return try TP_ChangeFootnoteKindCommandArchive(serializedBytes: data)
  case 10116:
    return try TP_ChangeFootnoteNumberingCommandArchive(serializedBytes: data)
  case 10118:
    return try TP_ChangeFootnoteSpacingCommandArchive(serializedBytes: data)
  case 10170:
    return try TP_ChangePageTemplateForSectionCommandArchive(serializedBytes: data)
  case 10000:
    return try TP_DocumentArchive(serializedBytes: data)
  case 10162:
    return try TP_DocumentSelectionTransformerArchive(serializedBytes: data)
  case 10015:
    return try TP_DrawablesZOrderArchive(serializedBytes: data)
  case 10010:
    return try TP_FloatingDrawablesArchive(serializedBytes: data)
  case 10101:
    return try TP_InsertDrawablesCommandArchive(serializedBytes: data)
  case 10113:
    return try TP_InsertFootnoteCommandArchive(serializedBytes: data)
  case 10152:
    return try TP_InsertSectionBreakCommandArchive(serializedBytes: data)
  case 10125:
    return try TP_InsertSectionTemplateDrawablesCommandArchive(serializedBytes: data)
  case 10131:
    return try TP_LayoutStateArchive(serializedBytes: data)
  case 10175:
    return try TP_MailMergeSettingsArchive(serializedBytes: data)
  case 10119:
    return try TP_MoveAnchoredDrawableInlineCommandArchive(serializedBytes: data)
  case 10141:
    return try TP_MoveDrawableZOrderCommandArchive(serializedBytes: data)
  case 10110:
    return try TP_MoveDrawablesAttachedCommandArchive(serializedBytes: data)
  case 10111:
    return try TP_MoveDrawablesFloatingCommandArchive(serializedBytes: data)
  case 10130:
    return try TP_MoveDrawablesPageIndexCommandArchive(serializedBytes: data)
  case 10112:
    return try TP_MoveInlineDrawableAnchoredCommandArchive(serializedBytes: data)
  case 10140:
    return try TP_MoveSectionTemplateDrawableZOrderCommandArchive(serializedBytes: data)
  case 10166:
    return try TP_NullChildHintArchive(serializedBytes: data)
  case 10017:
    return try TP_PageTemplateArchive(serializedBytes: data)
  case 10127:
    return try TP_PasteSectionTemplateDrawablesCommandArchive(serializedBytes: data)
  case 10157:
    return try TP_PauseChangeTrackingCommandArchive(serializedBytes: data)
  case 7:
    return try TP_PlaceholderArchive(serializedBytes: data)
  case 10171:
    return try TP_PrototypeForUndoChangePageTemplateForSection(serializedBytes: data)
  case 10102:
    return try TP_RemoveDrawablesCommandArchive(serializedBytes: data)
  case 10126:
    return try TP_RemoveSectionTemplateDrawablesCommandArchive(serializedBytes: data)
  case 10169:
    return try TP_ReplaceHeaderFooterStorageCommandArchive(serializedBytes: data)
  case 10011:
    return try TP_SectionArchive(serializedBytes: data)
  case 10161:
    return try TP_SectionGuideCommandArchive(serializedBytes: data)
  case 10174:
    return try TP_SectionPasteboardObjectArchive(serializedBytes: data)
  case 10135:
    return try TP_SectionSelectionArchive(serializedBytes: data)
  case 10136:
    return try TP_SectionSelectionTransformerArchive(serializedBytes: data)
  case 10143:
    return try TP_SectionTemplateArchive(serializedBytes: data)
  case 10173:
    return try TP_SectionsAppNativeObjectArchive(serializedBytes: data)
  case 10012:
    return try TP_SettingsArchive(serializedBytes: data)
  case 10001:
    return try TP_ThemeArchive(serializedBytes: data)
  case 10149:
    return try TP_TrackChangesCommandArchive(serializedBytes: data)
  case 10133:
    return try TP_UIStateArchive(serializedBytes: data)
  case 10016:
    return try TP_UserDefinedGuideMapArchive(serializedBytes: data)
  case 10147:
    return try TP_ViewStateRootArchive(serializedBytes: data)
  case 10165:
    return try TPSOS_InducedVerifyDocumentWithServerCommandArchive(serializedBytes: data)
  case 10167:
    return try TPSOS_InducedVerifyDrawableZOrdersWithServerCommandArchive(serializedBytes: data)
  case 10172:
    return try TPSOS_ReapplyPageTemplateCommandArchive(serializedBytes: data)
  default:
    return try decodeCommon(type: type, data: data)
  }
}
