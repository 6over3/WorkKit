import Foundation
import SwiftProtobuf

package func decodeNumbers(type: UInt32, data: Data) throws -> SwiftProtobuf.Message {
  switch type {
  case 12047:
    return try TN_CanvasSelectionTransformerArchive(serializedBytes: data)
  case 12006:
    return try TN_ChartMediatorArchive(serializedBytes: data)
  case 12036:
    return try TN_ChartSelectionArchive(serializedBytes: data)
  case 12014:
    return try TN_CommandChartMediatorSetEditingState(serializedBytes: data)
  case 12038:
    return try TN_CommandChartMediatorSetFormula(serializedBytes: data)
  case 12037:
    return try TN_CommandChartMediatorSetGridDirection(serializedBytes: data)
  case 12039:
    return try TN_CommandChartMediatorSetSeriesOrder(serializedBytes: data)
  case 12003:
    return try TN_CommandDocumentInsertSheetArchive(serializedBytes: data)
  case 12004:
    return try TN_CommandDocumentRemoveSheetArchive(serializedBytes: data)
  case 12008:
    return try TN_CommandDocumentReorderSheetArchive(serializedBytes: data)
  case 12015:
    return try TN_CommandFormChooseTargetTableArchive(serializedBytes: data)
  case 12043:
    return try TN_CommandInducedSheetChangeArchive(serializedBytes: data)
  case 12018:
    return try TN_CommandSetContentScaleArchive(serializedBytes: data)
  case 12030:
    return try TN_CommandSetDocumentPaperSize(serializedBytes: data)
  case 12032:
    return try TN_CommandSetHeaderFooterInsetsArchive(serializedBytes: data)
  case 12033:
    return try TN_CommandSetPageOrderArchive(serializedBytes: data)
  case 12017:
    return try TN_CommandSetPageOrientationArchive(serializedBytes: data)
  case 12052:
    return try TN_CommandSetPrintBackgroundsArchive(serializedBytes: data)
  case 12031:
    return try TN_CommandSetPrinterMarginsArchive(serializedBytes: data)
  case 12048:
    return try TN_CommandSetSheetDirectionArchive(serializedBytes: data)
  case 12005:
    return try TN_CommandSetSheetNameArchive(serializedBytes: data)
  case 12049:
    return try TN_CommandSetSheetShouldPrintCommentsArchive(serializedBytes: data)
  case 12035:
    return try TN_CommandSetStartPageNumberArchive(serializedBytes: data)
  case 12034:
    return try TN_CommandSetUsingStartPageNumberArchive(serializedBytes: data)
  case 12002:
    return try TN_CommandSheetInsertDrawablesArchive(serializedBytes: data)
  case 12013:
    return try TN_CommandSheetMoveDrawableZOrderArchive(serializedBytes: data)
  case 12012:
    return try TN_CommandSheetRemoveDrawablesArchive(serializedBytes: data)
  case 12051:
    return try TN_CommandSheetSetBackgroundFillArchive(serializedBytes: data)
  case 1:
    return try TN_DocumentArchive(serializedBytes: data)
  case 12041:
    return try TN_DocumentSelectionTransformerArchive(serializedBytes: data)
  case 3:
    return try TN_FormBasedSheetArchive(serializedBytes: data)
  case 12053:
    return try TN_FormBuilderSelectionArchive(serializedBytes: data)
  case 12056:
    return try TN_FormBuilderSelectionTransformerArchive(serializedBytes: data)
  case 12059:
    return try TN_FormCommandActivityBehaviorArchive(serializedBytes: data)
  case 12040:
    return try TN_FormSelectionArchive(serializedBytes: data)
  case 12058:
    return try TN_FormSheetSelectionTransformerArchive(serializedBytes: data)
  case 12054:
    return try TN_FormTableChooserSelectionArchive(serializedBytes: data)
  case 12055:
    return try TN_FormTableChooserSelectionTransformerArchive(serializedBytes: data)
  case 12057:
    return try TN_FormViewerSelectionTransformerArchive(serializedBytes: data)
  case 12046:
    return try TN_PasteboardNativeStorageArchive(serializedBytes: data)
  case 7:
    return try TN_PlaceholderArchive(serializedBytes: data)
  case 2:
    return try TN_SheetArchive(serializedBytes: data)
  case 12028:
    return try TN_SheetSelectionArchive(serializedBytes: data)
  case 12042:
    return try TN_SheetSelectionTransformerArchive(serializedBytes: data)
  case 12050:
    return try TN_SheetStyleArchive(serializedBytes: data)
  case 12009:
    return try TN_ThemeArchive(serializedBytes: data)
  case 12026:
    return try TN_UIStateArchive(serializedBytes: data)
  case 12044:
    return try TNSOS_InducedVerifyDocumentWithServerCommandArchive(serializedBytes: data)
  case 12045:
    return try TNSOS_InducedVerifyDrawableZOrdersWithServerCommandArchive(serializedBytes: data)
  case 10011:
    return try TSWP_SectionPlaceholderArchive(serializedBytes: data)
  default:
    return try decodeCommon(type: type, data: data)
  }
}
