import Foundation
import SwiftProtobuf

package func decodeCommon(type: UInt32, data: Data) throws -> SwiftProtobuf.Message {
    switch type {
    case 605:
        return try TSA_AddCustomFormatCommandArchive(serializedBytes: data)
    case 633:
        return try TSA_CaptionInfoArchive(serializedBytes: data)
    case 634:
        return try TSA_CaptionPlacementArchive(serializedBytes: data)
    case 617:
        return try TSA_ChangeDocumentLocaleCommandArchive(serializedBytes: data)
    case 600:
        return try TSA_DocumentArchive(serializedBytes: data)
    case 601:
        return try TSA_FunctionBrowserStateArchive(serializedBytes: data)
    case 636:
        return try TSA_GalleryInfoInsertItemsCommandArchive(serializedBytes: data)
    case 637:
        return try TSA_GalleryInfoRemoveItemsCommandArchive(serializedBytes: data)
    case 627:
        return try TSA_GalleryInfoSetValueCommandArchive(serializedBytes: data)
    case 623:
        return try TSA_GalleryItem(serializedBytes: data)
    case 625:
        return try TSA_GalleryItemSelection(serializedBytes: data)
    case 626:
        return try TSA_GalleryItemSelectionTransformer(serializedBytes: data)
    case 628:
        return try TSA_GalleryItemSetGeometryCommand(serializedBytes: data)
    case 629:
        return try TSA_GalleryItemSetValueCommand(serializedBytes: data)
    case 624:
        return try TSA_GallerySelectionTransformer(serializedBytes: data)
    case 612:
        return try TSA_InducedVerifyObjectsWithServerCommandArchive(serializedBytes: data)
    case 630:
        return try TSA_InducedVerifyTransformHistoryWithServerCommandArchive(serializedBytes: data)
    case 616:
        return try TSA_NeedsMediaCompatibilityUpgradeCommandArchive(serializedBytes: data)
    case 642:
        return try TSA_Object3DInfoCommandArchive(serializedBytes: data)
    case 641:
        return try TSA_Object3DInfoSetValueCommandArchive(serializedBytes: data)
    case 602:
        return try TSA_PropagatePresetCommandArchive(serializedBytes: data)
    case 619:
        return try TSA_RemoteDataChangeCommandArchive(serializedBytes: data)
    case 607:
        return try TSA_ReplaceCustomFormatCommandArchive(serializedBytes: data)
    case 604:
        return try TSA_ShortcutCommandArchive(serializedBytes: data)
    case 603:
        return try TSA_ShortcutControllerArchive(serializedBytes: data)
    case 618:
        return try TSA_StyleUpdatePropertyMapCommandArchive(serializedBytes: data)
    case 635:
        return try TSA_TitlePlacementCommandArchive(serializedBytes: data)
    case 606:
        return try TSA_UpdateCustomFormatCommandArchive(serializedBytes: data)
    case 631:
        return try TSASOS_CommandReapplyMasterArchive(serializedBytes: data)
    case 639:
        return try TSASOS_InducedVerifyActivityStreamWithServerCommandArchive(serializedBytes: data)
    case 615:
        return try TSASOS_InducedVerifyDrawableZOrdersWithServerCommandArchive(serializedBytes: data)
    case 632:
        return try TSASOS_PropagateMasterChangeCommandArchive(serializedBytes: data)
    case 638:
        return try TSASOS_VerifyActivityStreamWithServerCommandArchive(serializedBytes: data)
    case 613:
        return try TSASOS_VerifyDocumentWithServerCommandArchive(serializedBytes: data)
    case 614:
        return try TSASOS_VerifyDrawableZOrdersWithServerCommandArchive(serializedBytes: data)
    case 611:
        return try TSASOS_VerifyObjectsWithServerCommandArchive(serializedBytes: data)
    case 640:
        return try TSASOS_VerifyTransformHistoryWithServerCommandArchive(serializedBytes: data)
    case 4000:
        return try TSCE_CalculationEngineArchive(serializedBytes: data)
    case 4009:
        return try TSCE_CellRecordTileArchive(serializedBytes: data)
    case 4008:
        return try TSCE_FormulaOwnerDependenciesArchive(serializedBytes: data)
    case 4001:
        return try TSCE_FormulaRewriteCommandArchive(serializedBytes: data)
    case 4003:
        return try TSCE_NamedReferenceManagerArchive(serializedBytes: data)
    case 4010:
        return try TSCE_RangePrecedentsTileArchive(serializedBytes: data)
    case 4011:
        return try TSCE_ReferencesToDirtyArchive(serializedBytes: data)
    case 4007:
        return try TSCE_RemoteDataStoreArchive(serializedBytes: data)
    case 4005:
        return try TSCE_TrackedReferenceArchive(serializedBytes: data)
    case 4004:
        return try TSCE_TrackedReferenceStoreArchive(serializedBytes: data)
    case 5151:
        return try TSCH_CDESelectionTransformerArchive(serializedBytes: data)
    case 5027:
        return try TSCH_ChartAxisNonStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ChartAxisNonStyleArchive.Extensions.current,
        ]))
    case 5026:
        return try TSCH_ChartAxisStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ChartAxisStyleArchive.Extensions.current,
        ]))
    case 5126:
        return try TSCH_ChartCommandArchive(serializedBytes: data)
    case 5021:
        return try TSCH_ChartDrawableArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_ChartArchive.Extensions.unity,
        ]))
    case 5148:
        return try TSCH_ChartDrawableSelectionTransformerArchive(serializedBytes: data)
    case 5004:
        return try TSCH_ChartMediatorArchive(serializedBytes: data)
    case 5023:
        return try TSCH_ChartNonStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ChartNonStyleArchive.Extensions.current,
        ]))
    case 5150:
        return try TSCH_ChartRefLineSubselectionTransformerHelperArchive(serializedBytes: data)
    case 5145:
        return try TSCH_ChartSelectionArchive(serializedBytes: data)
    case 5029:
        return try TSCH_ChartSeriesNonStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ChartSeriesNonStyleArchive.Extensions.current,
        ]))
    case 5028:
        return try TSCH_ChartSeriesStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ChartSeriesStyleArchive.Extensions.current,
        ]))
    case 5022:
        return try TSCH_ChartStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ChartStyleArchive.Extensions.current,
        ]))
    case 5020:
        return try TSCH_ChartStylePreset(serializedBytes: data)
    case 5152:
        return try TSCH_ChartSubselectionIdentityTransformerHelperArchive(serializedBytes: data)
    case 5147:
        return try TSCH_ChartSubselectionTransformerArchive(serializedBytes: data)
    case 5149:
        return try TSCH_ChartSubselectionTransformerHelperArchive(serializedBytes: data)
    case 5146:
        return try TSCH_ChartTextSelectionTransformerArchive(serializedBytes: data)
    case 5116:
        return try TSCH_CommandAddGridColumnsArchive(serializedBytes: data)
    case 5115:
        return try TSCH_CommandAddGridRowsArchive(serializedBytes: data)
    case 5140:
        return try TSCH_CommandAddReferenceLineArchive(serializedBytes: data)
    case 5138:
        return try TSCH_CommandApplyFillSetArchive(serializedBytes: data)
    case 5125:
        return try TSCH_CommandChartApplyPreset(serializedBytes: data)
    case 5142:
        return try TSCH_CommandDeleteGridColumnsArchive(serializedBytes: data)
    case 5143:
        return try TSCH_CommandDeleteGridRowsArchive(serializedBytes: data)
    case 5141:
        return try TSCH_CommandDeleteReferenceLineArchive(serializedBytes: data)
    case 5157:
        return try TSCH_CommandInduced3DChartGeometry(serializedBytes: data)
    case 5155:
        return try TSCH_CommandInducedReplaceChartGrid(serializedBytes: data)
    case 5132:
        return try TSCH_CommandInvalidateWPCaches(serializedBytes: data)
    case 5119:
        return try TSCH_CommandMoveGridColumnsArchive(serializedBytes: data)
    case 5118:
        return try TSCH_CommandMoveGridRowsArchive(serializedBytes: data)
    case 5135:
        return try TSCH_CommandMutatePropertiesArchive(serializedBytes: data)
    case 5154:
        return try TSCH_CommandPasteStyleArchive(serializedBytes: data)
    case 5139:
        return try TSCH_CommandReplaceCustomFormatArchive(serializedBytes: data)
    case 5127:
        return try TSCH_CommandReplaceGridValuesArchive(serializedBytes: data)
    case 5156:
        return try TSCH_CommandReplaceImageDataArchive(serializedBytes: data)
    case 5131:
        return try TSCH_CommandReplaceThemePresetArchive(serializedBytes: data)
    case 5136:
        return try TSCH_CommandScaleAllTextArchive(serializedBytes: data)
    case 5105:
        return try TSCH_CommandSetCategoryNameArchive(serializedBytes: data)
    case 5103:
        return try TSCH_CommandSetChartTypeArchive(serializedBytes: data)
    case 5137:
        return try TSCH_CommandSetFontFamilyArchive(serializedBytes: data)
    case 5110:
        return try TSCH_CommandSetGridDirectionArchive(serializedBytes: data)
    case 5109:
        return try TSCH_CommandSetGridValueArchive(serializedBytes: data)
    case 5108:
        return try TSCH_CommandSetLegendFrameArchive(serializedBytes: data)
    case 5130:
        return try TSCH_CommandSetMultiDataSetIndexArchive(serializedBytes: data)
    case 5122:
        return try TSCH_CommandSetPieWedgeExplosion(serializedBytes: data)
    case 5107:
        return try TSCH_CommandSetScatterFormatArchive(serializedBytes: data)
    case 5104:
        return try TSCH_CommandSetSeriesNameArchive(serializedBytes: data)
    case 5123:
        return try TSCH_CommandStyleSwapArchive(serializedBytes: data)
    case 5025:
        return try TSCH_LegendNonStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_LegendNonStyleArchive.Extensions.current,
        ]))
    case 5024:
        return try TSCH_LegendStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_LegendStyleArchive.Extensions.current,
        ]))
    case 5016:
        return try TSCH_PreUFF_ChartAxisNonStyleArchive(serializedBytes: data)
    case 5012:
        return try TSCH_PreUFF_ChartAxisStyleArchive(serializedBytes: data)
    case 5002:
        return try TSCH_PreUFF_ChartGridArchive(serializedBytes: data)
    case 5000:
        return try TSCH_PreUFF_ChartInfoArchive(serializedBytes: data)
    case 5014:
        return try TSCH_PreUFF_ChartNonStyleArchive(serializedBytes: data)
    case 5015:
        return try TSCH_PreUFF_ChartSeriesNonStyleArchive(serializedBytes: data)
    case 5011:
        return try TSCH_PreUFF_ChartSeriesStyleArchive(serializedBytes: data)
    case 5010:
        return try TSCH_PreUFF_ChartStyleArchive(serializedBytes: data)
    case 5017:
        return try TSCH_PreUFF_LegendNonStyleArchive(serializedBytes: data)
    case 5013:
        return try TSCH_PreUFF_LegendStyleArchive(serializedBytes: data)
    case 5031:
        return try TSCH_ReferenceLineNonStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ReferenceLineNonStyleArchive.Extensions.current,
        ]))
    case 5030:
        return try TSCH_ReferenceLineStyleArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSCH_Generated_ReferenceLineStyleArchive.Extensions.current,
        ]))
    case 5129:
        return try TSCH_StylePasteboardDataArchive(serializedBytes: data)
    case 281:
        return try TSCK_ActivityArchive(serializedBytes: data)
    case 286:
        return try TSCK_ActivityAuthorArchive(serializedBytes: data)
    case 279:
        return try TSCK_ActivityAuthorCacheArchive(serializedBytes: data)
    case 282:
        return try TSCK_ActivityCommitCommandArchive(serializedBytes: data)
    case 289:
        return try TSCK_ActivityCursorCollectionPersistenceWrapperArchive(serializedBytes: data)
    case 273:
        return try TSCK_ActivityOnlyCommandArchive(serializedBytes: data)
    case 283:
        return try TSCK_ActivityStreamActivityArray(serializedBytes: data)
    case 284:
        return try TSCK_ActivityStreamActivityArraySegment(serializedBytes: data)
    case 280:
        return try TSCK_ActivityStreamArchive(serializedBytes: data)
    case 285:
        return try TSCK_ActivityStreamRemovedAuthorAuditorPendingStateArchive(serializedBytes: data)
    case 262:
        return try TSCK_AssetUnmaterializedOnServerCommandArchive(serializedBytes: data)
    case 261:
        return try TSCK_AssetUploadStatusCommandArchive(serializedBytes: data)
    case 248:
        return try TSCK_BlockDiffsAtCurrentRevisionCommand(serializedBytes: data)
    case 218:
        return try TSCK_CollaborationCommandHistory(serializedBytes: data)
    case 256:
        return try TSCK_CollaborationCommandHistoryArray(serializedBytes: data)
    case 257:
        return try TSCK_CollaborationCommandHistoryArraySegment(serializedBytes: data)
    case 227:
        return try TSCK_CollaborationCommandHistoryCoalescingGroup(serializedBytes: data)
    case 228:
        return try TSCK_CollaborationCommandHistoryCoalescingGroupNode(serializedBytes: data)
    case 255:
        return try TSCK_CollaborationCommandHistoryItem(serializedBytes: data)
    case 229:
        return try TSCK_CollaborationCommandHistoryOriginatingCommandAcknowledgementObserver(serializedBytes: data)
    case 226:
        return try TSCK_CollaborationDocumentSessionState(serializedBytes: data)
    case 265:
        return try TSCK_CommandActivityBehaviorArchive(serializedBytes: data)
    case 260:
        return try TSCK_CommandAssetChunkArchive(serializedBytes: data)
    case 238:
        return try TSCK_CreateLocalStorageSnapshotCommandArchive(serializedBytes: data)
    case 230:
        return try TSCK_DocumentSupportCollaborationState(serializedBytes: data)
    case 245:
        return try TSCK_OperationStorage(serializedBytes: data)
    case 246:
        return try TSCK_OperationStorageEntryArray(serializedBytes: data)
    case 247:
        return try TSCK_OperationStorageEntryArraySegment(serializedBytes: data)
    case 249:
        return try TSCK_OutgoingCommandQueue(serializedBytes: data)
    case 250:
        return try TSCK_OutgoingCommandQueueSegment(serializedBytes: data)
    case 275:
        return try TSCK_SetActivityAuthorShareParticipantIDCommandArchive(serializedBytes: data)
    case 215:
        return try TSCK_SetAnnotationAuthorColorCommandArchive(serializedBytes: data)
    case 235:
        return try TSCK_TransformerEntry(serializedBytes: data)
    case 259:
        return try TSCKSOS_FixCorruptedDataCommandArchive(serializedBytes: data)
    case 288:
        return try TSCKSOS_RemoveAuthorIdentifiersCommandArchive(serializedBytes: data)
    case 287:
        return try TSCKSOS_ResetActivityStreamCommandArchive(serializedBytes: data)
    case 3045:
        return try TSD_CanvasSelectionArchive(serializedBytes: data)
    case 3064:
        return try TSD_CommentInvalidatingCommandSelectionBehaviorArchive(serializedBytes: data)
    case 3056:
        return try TSD_CommentStorageArchive(serializedBytes: data)
    case 3009:
        return try TSD_ConnectionLineArchive(serializedBytes: data)
    case 3041:
        return try TSD_ConnectionLineConnectCommandArchive(serializedBytes: data)
    case 3003:
        return try TSD_ContainerArchive(serializedBytes: data)
    case 3053:
        return try TSD_ContainerInsertChildrenCommandArchive(serializedBytes: data)
    case 3085:
        return try TSD_ContainerInsertDrawablesCommandArchive(serializedBytes: data)
    case 3052:
        return try TSD_ContainerRemoveChildrenCommandArchive(serializedBytes: data)
    case 3084:
        return try TSD_ContainerRemoveDrawablesCommandArchive(serializedBytes: data)
    case 3054:
        return try TSD_ContainerReorderChildrenCommandArchive(serializedBytes: data)
    case 3058:
        return try TSD_DrawableAccessibilityDescriptionCommandArchive(serializedBytes: data)
    case 3002:
        return try TSD_DrawableArchive(serializedBytes: data)
    case 3051:
        return try TSD_DrawableAspectRatioLockedCommandArchive(serializedBytes: data)
    case 3083:
        return try TSD_DrawableContentDescription(serializedBytes: data)
    case 3040:
        return try TSD_DrawableHyperlinkCommandArchive(serializedBytes: data)
    case 3049:
        return try TSD_DrawableInfoCommentCommandArchive(serializedBytes: data)
    case 3043:
        return try TSD_DrawableLockCommandArchive(serializedBytes: data)
    case 3022:
        return try TSD_DrawablePathSourceCommandArchive(serializedBytes: data)
    case 3088:
        return try TSD_DrawablePencilAnnotationCommandArchive(serializedBytes: data)
    case 3061:
        return try TSD_DrawableSelectionArchive(serializedBytes: data)
    case 3071:
        return try TSD_DrawableSelectionTransformerArchive(serializedBytes: data)
    case 3036:
        return try TSD_ExteriorTextWrapCommandArchive(serializedBytes: data)
    case 3094:
        return try TSD_FreehandDrawingAnimationCommandArchive(serializedBytes: data)
    case 3090:
        return try TSD_FreehandDrawingContentDescription(serializedBytes: data)
    case 3087:
        return try TSD_FreehandDrawingOpacityCommandArchive(serializedBytes: data)
    case 3091:
        return try TSD_FreehandDrawingToolkitUIState(serializedBytes: data)
    case 3008:
        return try TSD_GroupArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSD_FreehandDrawingArchive.Extensions.freehand_drawing_archive,
        ]))
    case 3062:
        return try TSD_GroupSelectionArchive(serializedBytes: data)
    case 3072:
        return try TSD_GroupSelectionTransformerArchive(serializedBytes: data)
    case 3082:
        return try TSD_GroupUngroupInformativeCommandArchive(serializedBytes: data)
    case 3050:
        return try TSD_GuideCommandArchive(serializedBytes: data)
    case 3047:
        return try TSD_GuideStorageArchive(serializedBytes: data)
    case 3055:
        return try TSD_ImageAdjustmentsCommandArchive(serializedBytes: data)
    case 3005:
        return try TSD_ImageArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            TSA_GalleryInfo.Extensions.gallery_info,
            TSA_WebVideoInfo.Extensions.web_video_info,
            TSWP_EquationInfoArchive.Extensions.equation_depth,
            TSWP_EquationInfoArchive.Extensions.equation_source_old,
            TSWP_EquationInfoArchive.Extensions.equation_source_text,
            TSWP_EquationInfoArchive.Extensions.equation_text_properties,
        ]))
    case 3065:
        return try TSD_ImageInfoAbstractGeometryCommandArchive(serializedBytes: data)
    case 3066:
        return try TSD_ImageInfoGeometryCommandArchive(serializedBytes: data)
    case 3067:
        return try TSD_ImageInfoMaskGeometryCommandArchive(serializedBytes: data)
    case 3024:
        return try TSD_ImageMaskCommandArchive(serializedBytes: data)
    case 3025:
        return try TSD_ImageMediaCommandArchive(serializedBytes: data)
    case 3044:
        return try TSD_ImageNaturalSizeCommandArchive(serializedBytes: data)
    case 3026:
        return try TSD_ImageReplaceCommandArchive(serializedBytes: data)
    case 3021:
        return try TSD_InfoGeometryCommandArchive(serializedBytes: data)
    case 3095:
        return try TSD_InsertCaptionOrTitleCommandArchive(serializedBytes: data)
    case 3042:
        return try TSD_InstantAlphaCommandArchive(serializedBytes: data)
    case 3006:
        return try TSD_MaskArchive(serializedBytes: data)
    case 3032:
        return try TSD_MediaApplyPresetCommandArchive(serializedBytes: data)
    case 3037:
        return try TSD_MediaFlagsCommandArchive(serializedBytes: data)
    case 3080:
        return try TSD_MediaInfoGeometryCommandArchive(serializedBytes: data)
    case 3027:
        return try TSD_MediaOriginalSizeCommandArchive(serializedBytes: data)
    case 3016:
        return try TSD_MediaStyleArchive(serializedBytes: data)
    case 3030:
        return try TSD_MediaStyleSetValueCommandArchive(serializedBytes: data)
    case 3007:
        return try TSD_MovieArchive(serializedBytes: data, extensions: SwiftProtobuf.SimpleExtensionMap([
            KN_LiveVideoInfo.Extensions.live_video_info,
            TSA_Object3DInfo.Extensions.object_3D_info,
        ]))
    case 3034:
        return try TSD_MovieSetValueCommandArchive(serializedBytes: data)
    case 3059:
        return try TSD_PasteStyleCommandArchive(serializedBytes: data)
    case 3063:
        return try TSD_PathSelectionArchive(serializedBytes: data)
    case 3074:
        return try TSD_PathSelectionTransformerArchive(serializedBytes: data)
    case 3086:
        return try TSD_PencilAnnotationArchive(serializedBytes: data)
    case 3089:
        return try TSD_PencilAnnotationSelectionArchive(serializedBytes: data)
    case 3092:
        return try TSD_PencilAnnotationSelectionTransformerArchive(serializedBytes: data)
    case 242:
        return try TSD_PencilAnnotationStorageArchive(serializedBytes: data)
    case 3096:
        return try TSD_RemoveCaptionOrTitleCommandArchive(serializedBytes: data)
    case 3070:
        return try TSD_ReplaceAnnotationAuthorCommandArchive(serializedBytes: data)
    case 3098:
        return try TSD_SetCaptionOrTitleVisibilityCommandArchive(serializedBytes: data)
    case 3031:
        return try TSD_ShapeApplyPresetCommandArchive(serializedBytes: data)
    case 3004:
        return try TSD_ShapeArchive(serializedBytes: data)
    case 3073:
        return try TSD_ShapeSelectionTransformerArchive(serializedBytes: data)
    case 3015:
        return try TSD_ShapeStyleArchive(serializedBytes: data)
    case 3028:
        return try TSD_ShapeStyleSetValueCommandArchive(serializedBytes: data)
    case 3097:
        return try TSD_StandinCaptionArchive(serializedBytes: data)
    case 3048:
        return try TSD_StyledInfoSetStyleCommandArchive(serializedBytes: data)
    case 3057:
        return try TSD_ThemeReplaceFillPresetCommandArchive(serializedBytes: data)
    case 3068:
        return try TSD_UndoObjectArchive(serializedBytes: data)
    case 290:
        return try TSK_AIGeneratedContentCommandArchive(serializedBytes: data)
    case 212:
        return try TSK_AnnotationAuthorArchive(serializedBytes: data)
    case 213:
        return try TSK_AnnotationAuthorStorageArchive(serializedBytes: data)
    case 231:
        return try TSK_ChangeDocumentPackageTypeCommandArchive(serializedBytes: data)
    case 263:
        return try TSK_CommandBehaviorArchive(serializedBytes: data)
    case 264:
        return try TSK_CommandBehaviorSelectionPathStorageArchive(serializedBytes: data)
    case 203:
        return try TSK_CommandContainerArchive(serializedBytes: data)
    case 202:
        return try TSK_CommandGroupArchive(serializedBytes: data)
    case 220:
        return try TSK_CommandSelectionBehaviorArchive(serializedBytes: data)
    case 222:
        return try TSK_CustomFormatListArchive(serializedBytes: data)
    case 2061:
        return try TSK_DeprecatedChangeAuthorArchive(serializedBytes: data)
    case 200:
        return try TSK_DocumentArchive(serializedBytes: data)
    case 219:
        return try TSK_DocumentSelectionArchive(serializedBytes: data)
    case 211:
        return try TSK_DocumentSupportArchive(serializedBytes: data)
    case 233:
        return try TSK_FinalCommandPairArchive(serializedBytes: data)
    case 223:
        return try TSK_GroupCommitCommandArchive(serializedBytes: data)
    case 224:
        return try TSK_InducedCommandCollectionArchive(serializedBytes: data)
    case 225:
        return try TSK_InducedCommandCollectionCommitCommandArchive(serializedBytes: data)
    case 201:
        return try TSK_LocalCommandHistory(serializedBytes: data)
    case 253:
        return try TSK_LocalCommandHistoryArray(serializedBytes: data)
    case 254:
        return try TSK_LocalCommandHistoryArraySegment(serializedBytes: data)
    case 252:
        return try TSK_LocalCommandHistoryItem(serializedBytes: data)
    case 241:
        return try TSK_NativeContentDescription(serializedBytes: data)
    case 221:
        return try TSK_NullCommandArchive(serializedBytes: data)
    case 234:
        return try TSK_OutgoingCommandQueueItem(serializedBytes: data)
    case 258:
        return try TSK_PencilAnnotationUIState(serializedBytes: data)
    case 251:
        return try TSK_PropagatedCommandCollectionArchive(serializedBytes: data)
    case 240:
        return try TSK_SelectionPathTransformerArchive(serializedBytes: data)
    case 291:
        return try TSK_SetLastPremiumUserActivityTimestampCommandArchive(serializedBytes: data)
    case 205:
        return try TSK_TreeNode(serializedBytes: data)
    case 232:
        return try TSK_UpgradeDocPostProcessingCommandArchive(serializedBytes: data)
    case 210:
        return try TSK_ViewStateArchive(serializedBytes: data)
    case 11014:
        return try TSP_DataMetadata(serializedBytes: data)
    case 11015:
        return try TSP_DataMetadataMap(serializedBytes: data)
    case 11011:
        return try TSP_DocumentMetadata(serializedBytes: data)
    case 11021:
        return try TSP_LargeLazyObjectArray(serializedBytes: data)
    case 11018:
        return try TSP_LargeLazyObjectArraySegment(serializedBytes: data)
    case 11019:
        return try TSP_LargeNumberArray(serializedBytes: data)
    case 11016:
        return try TSP_LargeNumberArraySegment(serializedBytes: data)
    case 11027:
        return try TSP_LargeObjectArray(serializedBytes: data)
    case 11026:
        return try TSP_LargeObjectArraySegment(serializedBytes: data)
    case 11020:
        return try TSP_LargeStringArray(serializedBytes: data)
    case 11017:
        return try TSP_LargeStringArraySegment(serializedBytes: data)
    case 11025:
        return try TSP_LargeUUIDArray(serializedBytes: data)
    case 11024:
        return try TSP_LargeUUIDArraySegment(serializedBytes: data)
    case 11010:
        return try TSP_ObjectCollection(serializedBytes: data)
    case 11008:
        return try TSP_ObjectContainer(serializedBytes: data)
    case 11013:
        return try TSP_ObjectSerializationMetadata(serializedBytes: data)
    case 11006:
        return try TSP_PackageMetadata(serializedBytes: data)
    case 11007:
        return try TSP_PasteboardMetadata(serializedBytes: data)
    case 11000:
        return try TSP_PasteboardObject(serializedBytes: data)
    case 11012:
        return try TSP_SupportMetadata(serializedBytes: data)
    case 11009:
        return try TSP_ViewStateMetadata(serializedBytes: data)
    case 400:
        return try TSS_StyleArchive(serializedBytes: data)
    case 412:
        return try TSS_StyleUpdatePropertyMapCommandArchive(serializedBytes: data)
    case 401:
        return try TSS_StylesheetArchive(serializedBytes: data)
    case 414:
        return try TSS_ThemeAddStylePresetCommandArchive(serializedBytes: data)
    case 402:
        return try TSS_ThemeArchive(serializedBytes: data)
    case 417:
        return try TSS_ThemeMovePresetCommandArchive(serializedBytes: data)
    case 415:
        return try TSS_ThemeRemoveStylePresetCommandArchive(serializedBytes: data)
    case 416:
        return try TSS_ThemeReplaceColorPresetCommandArchive(serializedBytes: data)
    case 413:
        return try TSS_ThemeReplacePresetCommandArchive(serializedBytes: data)
    case 419:
        return try TSS_ThemeReplaceStylePresetAndDisconnectStylesCommandArchive(serializedBytes: data)
    case 6193:
        return try TST_ArgumentPlaceholderNodeArchive(serializedBytes: data)
    case 6186:
        return try TST_ArrayNodeArchive(serializedBytes: data)
    case 6311:
        return try TST_AutofillSelectionArchive(serializedBytes: data)
    case 6183:
        return try TST_BooleanNodeArchive(serializedBytes: data)
    case 6318:
        return try TST_CategoryOrderArchive(serializedBytes: data)
    case 6372:
        return try TST_CategoryOwnerRefArchive(serializedBytes: data)
    case 6367:
        return try TST_CellDiffArray(serializedBytes: data)
    case 6368:
        return try TST_CellDiffArraySegment(serializedBytes: data)
    case 6264:
        return try TST_CellDiffMapArchive(serializedBytes: data)
    case 6273:
        return try TST_CellListArchive(serializedBytes: data)
    case 6031:
        return try TST_CellMapArchive(serializedBytes: data)
    case 6004:
        return try TST_CellStyleArchive(serializedBytes: data)
    case 6357:
        return try TST_ChangePropagationMapWrapper(serializedBytes: data)
    case 6267:
        return try TST_ColumnRowUIDMapArchive(serializedBytes: data)
    case 6262:
        return try TST_CommandAddTableStylePresetArchive(serializedBytes: data)
    case 6244:
        return try TST_CommandApplyCellCommentArchive(serializedBytes: data)
    case 6265:
        return try TST_CommandApplyCellContentsArchive(serializedBytes: data)
    case 6275:
        return try TST_CommandApplyCellDiffMapArchive(serializedBytes: data)
    case 6282:
        return try TST_CommandApplyCellMapArchive(serializedBytes: data)
    case 6158:
        return try TST_CommandApplyConcurrentCellMapArchive(serializedBytes: data)
    case 6117:
        return try TST_CommandApplyTableStylePresetArchive(serializedBytes: data)
    case 6150:
        return try TST_CommandCategoryChangeSummaryAggregateType(serializedBytes: data)
    case 6320:
        return try TST_CommandCategoryCollapseExpandGroupArchive(serializedBytes: data)
    case 6153:
        return try TST_CommandCategoryMoveRowsArchive(serializedBytes: data)
    case 6152:
        return try TST_CommandCategoryResizeColumnOrRowArchive(serializedBytes: data)
    case 6321:
        return try TST_CommandCategorySetGroupingColumnsArchive(serializedBytes: data)
    case 6361:
        return try TST_CommandCategorySetLabelRowVisibility(serializedBytes: data)
    case 6157:
        return try TST_CommandCategoryWillChangeGroupValue(serializedBytes: data)
    case 6111:
        return try TST_CommandChangeFreezeHeaderStateArchive(serializedBytes: data)
    case 6304:
        return try TST_CommandChangeTableAreaForColumnOrRowArchive(serializedBytes: data)
    case 6307:
        return try TST_CommandChooseTableIdRemapperArchive(serializedBytes: data)
    case 6228:
        return try TST_CommandDeleteCellContentsArchive(serializedBytes: data)
    case 6101:
        return try TST_CommandDeleteCellsArchive(serializedBytes: data)
    case 6381:
        return try TST_CommandExtendTableIDHistoryArchive(serializedBytes: data)
    case 6145:
        return try TST_CommandHideShowArchive(serializedBytes: data)
    case 6102:
        return try TST_CommandInsertColumnsOrRowsArchive(serializedBytes: data)
    case 6300:
        return try TST_CommandInverseMergeArchive(serializedBytes: data)
    case 6256:
        return try TST_CommandJustForNotifyingArchive(serializedBytes: data)
    case 6280:
        return try TST_CommandMergeArchive(serializedBytes: data)
    case 6301:
        return try TST_CommandMoveCellsArchive(serializedBytes: data)
    case 6268:
        return try TST_CommandMoveColumnsOrRowsArchive(serializedBytes: data)
    case 6277:
        return try TST_CommandMutateCellFormatArchive(serializedBytes: data)
    case 6376:
        return try TST_CommandPivotHideShowGrandTotalsArchive(serializedBytes: data)
    case 6375:
        return try TST_CommandPivotSetGroupingColumnOptionsArchive(serializedBytes: data)
    case 6371:
        return try TST_CommandPivotSetPivotRulesArchive(serializedBytes: data)
    case 6377:
        return try TST_CommandPivotSortArchive(serializedBytes: data)
    case 6229:
        return try TST_CommandPostflightSetCellArchive(serializedBytes: data)
    case 6103:
        return try TST_CommandRemoveColumnsOrRowsArchive(serializedBytes: data)
    case 6266:
        return try TST_CommandRemoveTableStylePresetArchive(serializedBytes: data)
    case 6269:
        return try TST_CommandReplaceCustomFormatArchive(serializedBytes: data)
    case 6270:
        return try TST_CommandReplaceTableStylePresetArchive(serializedBytes: data)
    case 6104:
        return try TST_CommandResizeColumnOrRowArchive(serializedBytes: data)
    case 6315:
        return try TST_CommandRewriteCategoryFormulasArchive(serializedBytes: data)
    case 6292:
        return try TST_CommandRewriteConditionalStylesForRewriteSpecArchive(serializedBytes: data)
    case 6293:
        return try TST_CommandRewriteFilterFormulasForRewriteSpecArchive(serializedBytes: data)
    case 6224:
        return try TST_CommandRewriteFilterFormulasForTableResizeArchive(serializedBytes: data)
    case 6285:
        return try TST_CommandRewriteFormulasForTransposeArchive(serializedBytes: data)
    case 6323:
        return try TST_CommandRewriteHiddenStatesForGroupByChangeArchive(serializedBytes: data)
    case 6303:
        return try TST_CommandRewriteMergeFormulasArchive(serializedBytes: data)
    case 6362:
        return try TST_CommandRewritePencilAnnotationFormulasArchive(serializedBytes: data)
    case 6379:
        return try TST_CommandRewritePivotOwnerFormulasArchive(serializedBytes: data)
    case 6294:
        return try TST_CommandRewriteSortOrderForRewriteSpecArchive(serializedBytes: data)
    case 6291:
        return try TST_CommandRewriteTableFormulasForRewriteSpecArchive(serializedBytes: data)
    case 6380:
        return try TST_CommandRewriteTrackedReferencesArchive(serializedBytes: data)
    case 6205:
        return try TST_CommandSetAutomaticDurationUnitsArchive(serializedBytes: data)
    case 6146:
        return try TST_CommandSetBaseArchive(serializedBytes: data)
    case 6147:
        return try TST_CommandSetBasePlacesArchive(serializedBytes: data)
    case 6148:
        return try TST_CommandSetBaseUseMinusSignArchive(serializedBytes: data)
    case 6131:
        return try TST_CommandSetCurrencyCodeArchive(serializedBytes: data)
    case 6238:
        return try TST_CommandSetDateTimeFormatArchive(serializedBytes: data)
    case 6289:
        return try TST_CommandSetDurationStyleArchive(serializedBytes: data)
    case 6290:
        return try TST_CommandSetDurationUnitSmallestLargestArchive(serializedBytes: data)
    case 6276:
        return try TST_CommandSetFilterSetArchive(serializedBytes: data)
    case 6250:
        return try TST_CommandSetFilterSetTypeArchive(serializedBytes: data)
    case 6221:
        return try TST_CommandSetFiltersEnabledArchive(serializedBytes: data)
    case 6246:
        return try TST_CommandSetFormulaTokenizationArchive(serializedBytes: data)
    case 6129:
        return try TST_CommandSetFractionAccuracyArchive(serializedBytes: data)
    case 6159:
        return try TST_CommandSetGroupSortOrderArchive(serializedBytes: data)
    case 6128:
        return try TST_CommandSetNegativeNumberStyleArchive(serializedBytes: data)
    case 6313:
        return try TST_CommandSetNowArchive(serializedBytes: data)
    case 6126:
        return try TST_CommandSetNumberOfDecimalPlacesArchive(serializedBytes: data)
    case 6156:
        return try TST_CommandSetPencilAnnotationsArchive(serializedBytes: data)
    case 6360:
        return try TST_CommandSetRangeControlMinMaxIncArchive(serializedBytes: data)
    case 6120:
        return try TST_CommandSetRepeatingHeaderEnabledArchive(serializedBytes: data)
    case 6127:
        return try TST_CommandSetShowThousandsSeparatorArchive(serializedBytes: data)
    case 6258:
        return try TST_CommandSetSortOrderArchive(serializedBytes: data)
    case 6278:
        return try TST_CommandSetStorageLanguageArchive(serializedBytes: data)
    case 6314:
        return try TST_CommandSetStructuredTextImportRecordArchive(serializedBytes: data)
    case 6136:
        return try TST_CommandSetTableFontNameArchive(serializedBytes: data)
    case 6137:
        return try TST_CommandSetTableFontSizeArchive(serializedBytes: data)
    case 6107:
        return try TST_CommandSetTableNameArchive(serializedBytes: data)
    case 6114:
        return try TST_CommandSetTableNameEnabledArchive(serializedBytes: data)
    case 6142:
        return try TST_CommandSetTableNameHeightArchive(serializedBytes: data)
    case 6255:
        return try TST_CommandSetTextStyleArchive(serializedBytes: data)
    case 6149:
        return try TST_CommandSetTextStylePropertiesArchive(serializedBytes: data)
    case 6132:
        return try TST_CommandSetUseAccountingStyleArchive(serializedBytes: data)
    case 6310:
        return try TST_CommandSetWasCutArchive(serializedBytes: data)
    case 6123:
        return try TST_CommandSortArchive(serializedBytes: data)
    case 6125:
        return try TST_CommandStyleTableArchive(serializedBytes: data)
    case 6226:
        return try TST_CommandTextPreflightInsertCellArchive(serializedBytes: data)
    case 6287:
        return try TST_CommandTransposeTableArchive(serializedBytes: data)
    case 6281:
        return try TST_CommandUnmergeArchive(serializedBytes: data)
    case 6199:
        return try TST_CompletionTokenAttachmentArchive(serializedBytes: data)
    case 6034:
        return try TST_ConcurrentCellListArchive(serializedBytes: data)
    case 6033:
        return try TST_ConcurrentCellMapArchive(serializedBytes: data)
    case 6010:
        return try TST_ConditionalStyleSetArchive(serializedBytes: data)
    case 6283:
        return try TST_ControlCellSelectionArchive(serializedBytes: data)
    case 6355:
        return try TST_ControlCellSelectionTransformerArchive(serializedBytes: data)
    case 6190:
        return try TST_DateNodeArchive(serializedBytes: data)
    case 6032:
        return try TST_DeathhawkRdar39989167CellSelectionArchive(serializedBytes: data)
    case 6302:
        return try TST_DefaultCellStylesContainerArchive(serializedBytes: data)
    case 6192:
        return try TST_DurationNodeArchive(serializedBytes: data)
    case 6197:
        return try TST_EmptyExpressionNodeArchive(serializedBytes: data)
    case 6182:
        return try TST_ExpressionNodeArchive(serializedBytes: data)
    case 6220:
        return try TST_FilterSetArchive(serializedBytes: data)
    case 6179:
        return try TST_FormulaEqualsTokenAttachmentArchive(serializedBytes: data)
    case 6271:
        return try TST_FormulaSelectionArchive(serializedBytes: data)
    case 6196:
        return try TST_FunctionEndNodeArchive(serializedBytes: data)
    case 6189:
        return try TST_FunctionNodeArchive(serializedBytes: data)
    case 6373:
        return try TST_GroupByArchive(serializedBytes: data)
    case 6382:
        return try TST_GroupByArchive.AggregatorArchive(serializedBytes: data)
    case 6383:
        return try TST_GroupByArchive.GroupNodeArchive(serializedBytes: data)
    case 6366:
        return try TST_HeaderNameMgrArchive(serializedBytes: data)
    case 6365:
        return try TST_HeaderNameMgrTileArchive(serializedBytes: data)
    case 6006:
        return try TST_HeaderStorageBucket(serializedBytes: data)
    case 6204:
        return try TST_HiddenStateFormulaOwnerArchive(serializedBytes: data)
    case 6350:
        return try TST_IdempotentSelectionTransformerArchive(serializedBytes: data)
    case 6235:
        return try TST_IdentifierNodeArchive(serializedBytes: data)
    case 6198:
        return try TST_LayoutHintArchive(serializedBytes: data)
    case 6187:
        return try TST_ListNodeArchive(serializedBytes: data)
    case 6144:
        return try TST_MergeRegionMapArchive(serializedBytes: data)
    case 6184:
        return try TST_NumberNodeArchive(serializedBytes: data)
    case 6188:
        return try TST_OperatorNodeArchive(serializedBytes: data)
    case 6363:
        return try TST_PencilAnnotationArchive(serializedBytes: data)
    case 6374:
        return try TST_PivotGroupingColumnOptionsMapArchive(serializedBytes: data)
    case 6369:
        return try TST_PivotOrderArchive(serializedBytes: data)
    case 6370:
        return try TST_PivotOwnerArchive(serializedBytes: data)
    case 6206:
        return try TST_PopUpMenuModel(serializedBytes: data)
    case 6194:
        return try TST_PostfixOperatorNodeArchive(serializedBytes: data)
    case 6195:
        return try TST_PrefixOperatorNodeArchive(serializedBytes: data)
    case 6191:
        return try TST_ReferenceNodeArchive(serializedBytes: data)
    case 6353:
        return try TST_RegionSelectionTransformerArchive(serializedBytes: data)
    case 6218:
        return try TST_RichTextPayloadArchive(serializedBytes: data)
    case 6354:
        return try TST_RowColumnSelectionTransformerArchive(serializedBytes: data)
    case 6030:
        return try TST_SelectionArchive(serializedBytes: data)
    case 6384:
        return try TST_SpillOriginRefNodeArchive(serializedBytes: data)
    case 6312:
        return try TST_StockCellSelectionArchive(serializedBytes: data)
    case 6359:
        return try TST_StockCellSelectionTransformerArchive(serializedBytes: data)
    case 6185:
        return try TST_StringNodeArchive(serializedBytes: data)
    case 6306:
        return try TST_StrokeLayerArchive(serializedBytes: data)
    case 6295:
        return try TST_StrokeSelectionArchive(serializedBytes: data)
    case 6364:
        return try TST_StrokeSelectionTransformerArchive(serializedBytes: data)
    case 6305:
        return try TST_StrokeSidecarArchive(serializedBytes: data)
    case 6317:
        return try TST_SummaryCellVendorArchive(serializedBytes: data)
    case 6316:
        return try TST_SummaryModelArchive(serializedBytes: data)
    case 6100:
        return try TST_TableCommandArchive(serializedBytes: data)
    case 6239:
        return try TST_TableCommandSelectionBehaviorArchive(serializedBytes: data)
    case 6005, 6201:
        return try TST_TableDataList(serializedBytes: data)
    case 6011:
        return try TST_TableDataListSegment(serializedBytes: data)
    case 6000:
        return try TST_TableInfoArchive(serializedBytes: data)
    case 6001:
        return try TST_TableModelArchive(serializedBytes: data)
    case 6284:
        return try TST_TableNameSelectionArchive(serializedBytes: data)
    case 6352:
        return try TST_TableNameSelectionTransformerArchive(serializedBytes: data)
    case 6009:
        return try TST_TableStrokePresetArchive(serializedBytes: data)
    case 6003:
        return try TST_TableStyleArchive(serializedBytes: data)
    case 6247:
        return try TST_TableStyleNetworkArchive(serializedBytes: data)
    case 6008:
        return try TST_TableStylePresetArchive(serializedBytes: data)
    case 6351:
        return try TST_TableSubSelectionTransformerBaseArchive(serializedBytes: data)
    case 6002:
        return try TST_Tile(serializedBytes: data)
    case 6181:
        return try TST_TokenAttachmentArchive(serializedBytes: data)
    case 6298:
        return try TST_VariableNodeArchive(serializedBytes: data)
    case 6358:
        return try TST_WPSelectionTransformerArchive(serializedBytes: data)
    case 6007:
        return try TST_WPTableInfoArchive(serializedBytes: data)
    case 2125:
        return try TSWP_AddFlowInfoCommandArchive(serializedBytes: data)
    case 2206:
        return try TSWP_AnchorAttachmentCommandArchive(serializedBytes: data)
    case 2107:
        return try TSWP_ApplyPlaceholderTextCommandArchive(serializedBytes: data)
    case 2116:
        return try TSWP_ApplyRubyTextCommandArchive(serializedBytes: data)
    case 2040:
        return try TSWP_BibliographySmartFieldArchive(serializedBytes: data)
    case 2035:
        return try TSWP_BookmarkFieldArchive(serializedBytes: data)
    case 2060:
        return try TSWP_ChangeArchive(serializedBytes: data)
    case 2062:
        return try TSWP_ChangeSessionArchive(serializedBytes: data)
    case 2021:
        return try TSWP_CharacterStyleArchive(serializedBytes: data)
    case 2037:
        return try TSWP_CitationRecordArchive(serializedBytes: data)
    case 2038:
        return try TSWP_CitationSmartFieldArchive(serializedBytes: data)
    case 2024:
        return try TSWP_ColumnStyleArchive(serializedBytes: data)
    case 2014:
        return try TSWP_CommentInfoArchive(serializedBytes: data)
    case 2127:
        return try TSWP_ContainedObjectsCommandArchive(serializedBytes: data)
    case 2413:
        return try TSWP_DateTimeSelectionArchive(serializedBytes: data)
    case 2034:
        return try TSWP_DateTimeSmartFieldArchive(serializedBytes: data)
    case 2003:
        return try TSWP_DrawableAttachmentArchive(serializedBytes: data)
    case 10024:
        return try TSWP_DropCapStyleArchive(serializedBytes: data)
    case 2015:
        return try TSWP_EquationInfoArchive(serializedBytes: data)
    case 2128:
        return try TSWP_EquationInfoGeometryCommandArchive(serializedBytes: data)
    case 2033:
        return try TSWP_FilenameSmartFieldArchive(serializedBytes: data)
    case 2410:
        return try TSWP_FlowInfoArchive(serializedBytes: data)
    case 2411:
        return try TSWP_FlowInfoContainerArchive(serializedBytes: data)
    case 2008:
        return try TSWP_FootnoteReferenceAttachmentArchive(serializedBytes: data)
    case 2013:
        return try TSWP_HighlightArchive(serializedBytes: data)
    case 2032:
        return try TSWP_HyperlinkFieldArchive(serializedBytes: data)
    case 2409:
        return try TSWP_HyperlinkSelectionArchive(serializedBytes: data)
    case 2023:
        return try TSWP_ListStyleArchive(serializedBytes: data)
    case 2036:
        return try TSWP_MergeSmartFieldArchive(serializedBytes: data)
    case 2118:
        return try TSWP_ModifyRubyTextCommandArchive(serializedBytes: data)
    case 2120:
        return try TSWP_ModifyTOCSettingsBaseCommandArchive(serializedBytes: data)
    case 2121:
        return try TSWP_ModifyTOCSettingsForTOCInfoCommandArchive(serializedBytes: data)
    case 2043:
        return try TSWP_NumberAttachmentArchive(serializedBytes: data)
    case 2022:
        return try TSWP_ParagraphStyleArchive(serializedBytes: data)
    case 2016:
        return try TSWP_PencilAnnotationArchive(serializedBytes: data)
    case 2412:
        return try TSWP_PencilAnnotationSelectionTransformerArchive(serializedBytes: data)
    case 2031:
        return try TSWP_PlaceholderSmartFieldArchive(serializedBytes: data)
    case 2126:
        return try TSWP_RemoveFlowInfoCommandArchive(serializedBytes: data)
    case 2042:
        return try TSWP_RubyFieldArchive(serializedBytes: data)
    case 2002:
        return try TSWP_SelectionArchive(serializedBytes: data)
    case 10021:
        return try TSWP_SelectionTransformerArchive(serializedBytes: data)
    case 2123:
        return try TSWP_SetObjectPropertiesCommandArchive(serializedBytes: data)
    case 2231:
        return try TSWP_ShapeApplyPresetCommandArchive(serializedBytes: data)
    case 10022:
        return try TSWP_ShapeContentDescription(serializedBytes: data)
    case 2011:
        return try TSWP_ShapeInfoArchive(serializedBytes: data)
    case 10020:
        return try TSWP_ShapeSelectionTransformerArchive(serializedBytes: data)
    case 2025:
        return try TSWP_ShapeStyleArchive(serializedBytes: data)
    case 2408:
        return try TSWP_ShapeStyleSetValueCommandArchive(serializedBytes: data)
    case 2407:
        return try TSWP_StorageActionCommandArchive(serializedBytes: data)
    case 2001, 2005:
        return try TSWP_StorageArchive(serializedBytes: data)
    case 2400:
        return try TSWP_StyleBaseCommandArchive(serializedBytes: data)
    case 2401:
        return try TSWP_StyleCreateCommandArchive(serializedBytes: data)
    case 2404:
        return try TSWP_StyleDeleteCommandArchive(serializedBytes: data)
    case 2402:
        return try TSWP_StyleRenameCommandArchive(serializedBytes: data)
    case 2405:
        return try TSWP_StyleReorderCommandArchive(serializedBytes: data)
    case 2406:
        return try TSWP_StyleUpdatePropertyMapCommandArchive(serializedBytes: data)
    case 2241:
        return try TSWP_TOCAttachmentArchive(serializedBytes: data)
    case 2052:
        return try TSWP_TOCEntryInstanceArchive(serializedBytes: data)
    case 2026:
        return try TSWP_TOCEntryStyleArchive(serializedBytes: data)
    case 2240:
        return try TSWP_TOCInfoArchive(serializedBytes: data)
    case 2242:
        return try TSWP_TOCLayoutHintArchive(serializedBytes: data)
    case 2051:
        return try TSWP_TOCSettingsArchive(serializedBytes: data)
    case 2041:
        return try TSWP_TOCSmartFieldArchive(serializedBytes: data)
    case 2010:
        return try TSWP_TSWPTOCPageNumberAttachmentArchive(serializedBytes: data)
    case 10023:
        return try TSWP_TateChuYokoFieldArchive(serializedBytes: data)
    case 2101:
        return try TSWP_TextCommandArchive(serializedBytes: data)
    case 2217:
        return try TSWP_TextCommentReplyCommandArchive(serializedBytes: data)
    case 2050:
        return try TSWP_TextStylePresetArchive(serializedBytes: data)
    case 2004, 2007, 2009:
        return try TSWP_TextualAttachmentArchive(serializedBytes: data)
    case 2006:
        return try TSWP_UIGraphicalAttachment(serializedBytes: data)
    case 2039:
        return try TSWP_UnsupportedHyperlinkFieldArchive(serializedBytes: data)
    case 2124:
        return try TSWP_UpdateFlowInfoCommandArchive(serializedBytes: data)
    case 2053:
        return try TSWPSOS_StyleDiffArchive(serializedBytes: data)
    default:
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unknown type: \(type)"
            )
        )
    }
}
