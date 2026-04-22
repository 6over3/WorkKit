import Foundation
import SwiftProtobuf

package func decodeKeynote(type: UInt32, data: Data) throws -> SwiftProtobuf.Message {
    switch type {
    case 180:
        return try KN_ActionGhostSelectionArchive(serializedBytes: data)
    case 181:
        return try KN_ActionGhostSelectionTransformerArchive(serializedBytes: data)
    case 8:
        return try KN_BuildArchive(serializedBytes: data)
    case 159:
        return try KN_BuildAttributeTupleArchive(serializedBytes: data)
    case 153:
        return try KN_BuildChunkArchive(serializedBytes: data)
    case 24:
        return try KN_CanvasSelectionArchive(serializedBytes: data)
    case 168:
        return try KN_CanvasSelectionTransformerArchive(serializedBytes: data)
    case 148:
        return try KN_ChartInfoGeometryCommandArchive(serializedBytes: data)
    case 19:
        return try KN_ClassicStylesheetRecordArchive(serializedBytes: data)
    case 20:
        return try KN_ClassicThemeRecordArchive(serializedBytes: data)
    case 138:
        return try KN_CommandBuildChunkSetValueArchive(serializedBytes: data)
    case 100:
        return try KN_CommandBuildSetValueArchive(serializedBytes: data)
    case 157:
        return try KN_CommandBuildUpdateChunkCountArchive(serializedBytes: data)
    case 158:
        return try KN_CommandBuildUpdateChunkReferentsArchive(serializedBytes: data)
    case 119:
        return try KN_CommandChangeTemplateSlideArchive(serializedBytes: data)
    case 135:
        return try KN_CommandInsertTemplateArchive(serializedBytes: data)
    case 186:
        return try KN_CommandLiveVideoInfoApplyPreset(serializedBytes: data)
    case 187:
        return try KN_CommandLiveVideoInfoSetSource(serializedBytes: data)
    case 188:
        return try KN_CommandLiveVideoInfoSetValue(serializedBytes: data)
    case 189:
        return try KN_CommandLiveVideoSourceSetValue(serializedBytes: data)
    case 190:
        return try KN_CommandLiveVideoStyleSetValue(serializedBytes: data)
    case 194:
        return try KN_CommandMotionBackgroundStyleSetValueArchive(serializedBytes: data)
    case 195:
        return try KN_CommandMotionBackgroundStyleUpdatePosterFrameDataArchive(serializedBytes: data)
    case 134:
        return try KN_CommandMoveTemplatesArchive(serializedBytes: data)
    case 176:
        return try KN_CommandPrimitiveInsertTemplateArchive(serializedBytes: data)
    case 177:
        return try KN_CommandPrimitiveRemoveTemplateArchive(serializedBytes: data)
    case 140:
        return try KN_CommandRemoveTemplateArchive(serializedBytes: data)
    case 160:
        return try KN_CommandSetThemeCustomEffectTimingCurveArchive(serializedBytes: data)
    case 161:
        return try KN_CommandShowChangeSlideSizeArchive(serializedBytes: data)
    case 143:
        return try KN_CommandShowChangeThemeArchive(serializedBytes: data)
    case 101:
        return try KN_CommandShowInsertSlideArchive(serializedBytes: data)
    case 128:
        return try KN_CommandShowMarkOutOfSyncRecordingArchive(serializedBytes: data)
    case 173:
        return try KN_CommandShowMarkOutOfSyncRecordingIfNeededArchive(serializedBytes: data)
    case 102:
        return try KN_CommandShowMoveSlideArchive(serializedBytes: data)
    case 129:
        return try KN_CommandShowRemoveRecordingArchive(serializedBytes: data)
    case 103:
        return try KN_CommandShowRemoveSlideArchive(serializedBytes: data)
    case 130:
        return try KN_CommandShowReplaceRecordingArchive(serializedBytes: data)
    case 123:
        return try KN_CommandShowSetSlideNumberVisibilityArchive(serializedBytes: data)
    case 131:
        return try KN_CommandShowSetSoundtrack(serializedBytes: data)
    case 124:
        return try KN_CommandShowSetValueArchive(serializedBytes: data)
    case 107:
        return try KN_CommandSlideInsertBuildArchive(serializedBytes: data)
    case 110:
        return try KN_CommandSlideInsertBuildChunkArchive(serializedBytes: data)
    case 104:
        return try KN_CommandSlideInsertDrawablesArchive(serializedBytes: data)
    case 111:
        return try KN_CommandSlideMoveBuildChunksArchive(serializedBytes: data)
    case 118:
        return try KN_CommandSlideMoveDrawableZOrderArchive(serializedBytes: data)
    case 106:
        return try KN_CommandSlideNodeSetPropertyArchive(serializedBytes: data)
    case 156:
        return try KN_CommandSlideNodeSetViewStatePropertyArchive(serializedBytes: data)
    case 144:
        return try KN_CommandSlidePrimitiveSetTemplateArchive(serializedBytes: data)
    case 179:
        return try KN_CommandSlidePropagateSetPlaceholderForTagArchive(serializedBytes: data)
    case 109:
        return try KN_CommandSlideRemoveBuildArchive(serializedBytes: data)
    case 112:
        return try KN_CommandSlideRemoveBuildChunkArchive(serializedBytes: data)
    case 105:
        return try KN_CommandSlideRemoveDrawableArchive(serializedBytes: data)
    case 182:
        return try KN_CommandSlideResetTemplateBackgroundObjectsArchive(serializedBytes: data)
    case 152:
        return try KN_CommandSlideSetBackgroundFillArchive(serializedBytes: data)
    case 137:
        return try KN_CommandSlideSetPlaceholdersForTagsArchive(serializedBytes: data)
    case 136:
        return try KN_CommandSlideSetStyleArchive(serializedBytes: data)
    case 150:
        return try KN_CommandSlideUpdateTemplateDrawables(serializedBytes: data)
    case 132:
        return try KN_CommandSoundtrackSetValue(serializedBytes: data)
    case 145:
        return try KN_CommandTemplateSetBodyStylesArchive(serializedBytes: data)
    case 142:
        return try KN_CommandTemplateSetThumbnailTextArchive(serializedBytes: data)
    case 178:
        return try KN_CommandTemplateSlideSetPlaceholderForTagArchive(serializedBytes: data)
    case 191:
        return try KN_CommandThemeAddLiveVideoSource(serializedBytes: data)
    case 192:
        return try KN_CommandThemeRemoveLiveVideoSource(serializedBytes: data)
    case 114:
        return try KN_CommandTransitionSetValueArchive(serializedBytes: data)
    case 23:
        return try KN_DesktopUILayoutArchive(serializedBytes: data)
    case 1:
        return try KN_DocumentArchive(serializedBytes: data)
    case 164:
        return try KN_DocumentSelectionTransformerArchive(serializedBytes: data)
    case 162:
        return try KN_InsertBuildDescriptionArchive(serializedBytes: data)
    case 184:
        return try KN_LiveVideoSource(serializedBytes: data)
    case 185:
        return try KN_LiveVideoSourceCollection(serializedBytes: data)
    case 26:
        return try KN_MotionBackgroundStyleArchive(serializedBytes: data)
    case 15:
        return try KN_NoteArchive(serializedBytes: data)
    case 167:
        return try KN_NoteCanvasSelectionTransformerArchive(serializedBytes: data)
    case 166:
        return try KN_OutlineCanvasSelectionTransformerArchive(serializedBytes: data)
    case 169:
        return try KN_OutlineSelectionTransformerArchive(serializedBytes: data)
    case 11:
        return try KN_PasteboardNativeStorageArchive(serializedBytes: data)
    case 7, 12:
        return try KN_PlaceholderArchive(serializedBytes: data)
    case 172:
        return try KN_PrototypeForUndoTemplateChangeArchive(serializedBytes: data)
    case 16:
        return try KN_RecordingArchive(serializedBytes: data)
    case 17:
        return try KN_RecordingEventTrackArchive(serializedBytes: data)
    case 18:
        return try KN_RecordingMovieTrackArchive(serializedBytes: data)
    case 163:
        return try KN_RemoveBuildDescriptionArchive(serializedBytes: data)
    case 2:
        return try KN_ShowArchive(serializedBytes: data)
    case 5, 6:
        return try KN_SlideArchive(serializedBytes: data)
    case 25:
        return try KN_SlideCollectionSelectionArchive(serializedBytes: data)
    case 165:
        return try KN_SlideCollectionSelectionTransformerArchive(serializedBytes: data)
    case 4:
        return try KN_SlideNodeArchive(serializedBytes: data)
    case 22:
        return try KN_SlideNumberAttachmentArchive(serializedBytes: data)
    case 9:
        return try KN_SlideStyleArchive(serializedBytes: data)
    case 21:
        return try KN_Soundtrack(serializedBytes: data)
    case 10:
        return try KN_ThemeArchive(serializedBytes: data)
    case 3:
        return try KN_UIStateArchive(serializedBytes: data)
    case 170:
        return try KN_UndoObjectArchive(serializedBytes: data)
    case 146:
        return try KNSOS_CommandSlideReapplyTemplateSlideArchive(serializedBytes: data)
    case 174:
        return try KNSOS_InducedVerifyDocumentWithServerCommandArchive(serializedBytes: data)
    case 175:
        return try KNSOS_InducedVerifyDrawableZOrdersWithServerCommandArchive(serializedBytes: data)
    case 10011:
        return try TSWP_SectionPlaceholderArchive(serializedBytes: data)
    case 14:
        return try TSWP_TextualAttachmentArchive(serializedBytes: data)
    default:
        return try decodeCommon(type: type, data: data)
    }
}
