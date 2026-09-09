import CoreGraphics
import Foundation
import RegexBuilder
import Testing

@testable import WorkKit

@Test func keynoteSlideTraversalSkipsHiddenSlides() {
  var visible = KN_SlideNodeArchive()
  visible.slide = TSP_Reference()

  var skipped = visible
  skipped.isSkipped = true

  #expect(shouldVisitKeynoteSlide(visible))
  #expect(!shouldVisitKeynoteSlide(skipped))
  #expect(!shouldVisitKeynoteSlide(KN_SlideNodeArchive()))
}

@Test func shapeFrameUsesPathBoundsForMissingDimensions() {
  let pathBounds = CGRect(x: 0, y: 0, width: 600, height: 125)

  #expect(
    resolvedShapeFrame(
      CGRect(x: 40, y: 80, width: 600, height: 0),
      pathBounds: pathBounds
    ) == CGRect(x: 40, y: 80, width: 600, height: 125)
  )
  #expect(
    resolvedShapeFrame(
      CGRect(x: 40, y: 80, width: 0, height: 125),
      pathBounds: pathBounds
    ) == CGRect(x: 40, y: 80, width: 600, height: 125)
  )
  #expect(
    resolvedShapeFrame(
      CGRect(x: 40, y: 80, width: 300, height: 75),
      pathBounds: pathBounds
    ) == CGRect(x: 40, y: 80, width: 300, height: 75)
  )
}

@Test func imageMaskTransformRetainsTheVisibleSourceCrop() {
  let transform = normalizedImageToMaskTransform(
    imageFrame: CGRect(x: 0, y: 0, width: 200, height: 100),
    maskFrame: CGRect(x: 50, y: 0, width: 100, height: 100),
    maskAngle: 0
  )

  #expect(CGPoint(x: 0.25, y: 0).applying(transform) == .zero)
  #expect(CGPoint(x: 0.75, y: 1).applying(transform) == CGPoint(x: 1, y: 1))
}

@Test func imageMaskTransformUsesImageLocalMaskGeometry() {
  let transform = normalizedImageToMaskTransform(
    imageFrame: CGRect(x: 1_000, y: 700, width: 300, height: 120),
    maskFrame: CGRect(x: 0, y: 0, width: 300, height: 120),
    maskAngle: 0
  )

  let point = CGPoint(x: 0.2, y: 0.8).applying(transform)
  #expect(abs(point.x - 0.2) < 0.000_001)
  #expect(abs(point.y - 0.8) < 0.000_001)
}

@Test func visibleMaskedImageRetainsTheSourcePlacement() {
  let source = SpatialInfo(
    coordinateSpace: .slide,
    frame: CGRect(x: 1_000, y: 700, width: 600, height: 400),
    rotation: 0,
    zIndex: 3,
    isAnchoredToText: false,
    isFloatingAboveText: true,
    drawableID: 44
  )
  let mask = Mask(
    path: .bezier(
      BezierPath(elements: [], naturalSize: CGSize(width: 200, height: 100))
    ),
    position: CGPoint(x: 50, y: 75),
    size: CGSize(width: 200, height: 100),
    angle: 0,
    sourceToMaskNormalized: .identity
  )

  let visible = visibleMaskedImageSpatialInfo(source: source, mask: mask)

  #expect(visible.frame == CGRect(x: 1_050, y: 775, width: 200, height: 100))
  #expect(visible.zIndex == source.zIndex)
  #expect(visible.drawableID == source.drawableID)
}

@Test func webVideoRetainsDirectURLAndAttribution() throws {
  var attribution = TSD_Attribution()
  attribution.title = "An embedded video"
  attribution.externalURL = "https://www.youtube.com/watch?v=source"
  attribution.authorName = "Creator"

  var webVideo = TSA_WebVideoInfo()
  webVideo.url = "https://www.youtube.com/embed/source"
  webVideo.attribution = attribution

  var archive = TSD_ImageArchive()
  archive.TSA_WebVideoInfo_webVideoInfo = webVideo

  let parsed = try #require(archive.webVideoInfo)
  #expect(parsed.url == "https://www.youtube.com/embed/source")
  #expect(
    parsed.attribution?.externalURL
      == "https://www.youtube.com/watch?v=source"
  )
  #expect(parsed.attribution?.title == "An embedded video")
  #expect(parsed.attribution?.authorName == "Creator")
}

@Test func webVideoWithoutAttributionRetainsDirectURL() throws {
  var webVideo = TSA_WebVideoInfo()
  webVideo.url = "https://video.example/watch/1"

  var archive = TSD_ImageArchive()
  archive.TSA_WebVideoInfo_webVideoInfo = webVideo

  let parsed = try #require(archive.webVideoInfo)
  #expect(parsed.url == "https://video.example/watch/1")
  #expect(parsed.attribution == nil)
}

@Test func tableGeometryDecodesPackedAndExpandedCoordinates() {
  var packed = TST_CellID()
  packed.packedData = UInt32(27 << 16 | 13)

  var expandedCoordinate = TSCE_CellCoordinateArchive()
  expandedCoordinate.row = 70_000
  expandedCoordinate.column = 80_000
  var expanded = TST_CellID()
  expanded.packedData = 0
  expanded.expandedCoord = expandedCoordinate

  #expect(iWorkTableCoordinate(packed) == IWorkTableCoordinate(row: 27, column: 13))
  #expect(
    iWorkTableCoordinate(expanded)
      == IWorkTableCoordinate(row: 70_000, column: 80_000)
  )
}

@Test func tableGeometryDecodesPackedAndExpandedExtents() {
  var packed = TST_TableSize()
  packed.packedData = UInt32(4 << 16 | 3)

  var expanded = TST_TableSize()
  expanded.packedData = 0
  expanded.numRows = 70_000
  expanded.numColumns = 80_000

  #expect(iWorkTableExtent(packed) == IWorkTableExtent(rows: 4, columns: 3))
  #expect(iWorkTableExtent(expanded) == IWorkTableExtent(rows: 70_000, columns: 80_000))
}
