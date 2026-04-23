import CoreFoundation
import CoreGraphics
import Foundation

// MARK: - Inline Element
public enum InlineElement: Sendable, Codable, Equatable {
  /// Plain text with styling.
  case text(String, style: CharacterStyle, hyperlink: Hyperlink?)

  /// Footnote marker at a specific position.
  case footnoteMarker(Footnote)

  /// Inline image (uses same ImageInfo as floating images).
  case image(
    info: ImageInfo, spatialInfo: SpatialInfo, ocrResult: OCRResult?,
    hyperlink: Hyperlink?)

  /// Inline media (uses same MediaInfo as floating media).
  case media(info: MediaInfo, spatialInfo: SpatialInfo)

  /// equation (MathML or LaTeX).
  case equation(IWorkEquation)

  /// 3D object.
  case object3D(
    info: Object3DInfo,
    spatialInfo: SpatialInfo,
    hyperlink: Hyperlink?
  )

  case chart(info: ChartInfo, spatialInfo: SpatialInfo)
}

// MARK: - Equation Types

/// Represents an equation in an iWork document, either in LaTeX or MathML format.
///
/// Equations are typically stored in PDF metadata within the document package.
public enum IWorkEquation: Sendable, Codable, Equatable {
  /// LaTeX representation of the equation.
  case latex(String)

  /// MathML representation of the equation.
  case mathml(String)
}

// MARK: - Caption Types

/// Metadata for element captions (used by images, media, and shapes).
public struct CaptionData: Sendable, Codable, Equatable {
  /// The caption text.
  public let text: String

  /// Character styling applied to the caption.
  public let style: CharacterStyle?

  /// Spatial positioning information for the caption.
  public let spatialInfo: SpatialInfo

  /// Creates a new caption data instance.
  ///
  /// - Parameters:
  ///   - text: The caption text.
  ///   - style: Optional character styling for the caption.
  ///   - spatialInfo: Spatial positioning information.
  public init(text: String, style: CharacterStyle?, spatialInfo: SpatialInfo) {
    self.text = text
    self.style = style
    self.spatialInfo = spatialInfo
  }
}

// MARK: - Media Types

/// The type of media content.
public enum MediaType: Sendable, Codable, Equatable {
  /// Audio content.
  case audio

  /// Video content.
  case video

  /// Animated GIF content.
  case gif
}

/// Information about a media element in a document.
public struct MediaInfo: Sendable, Codable, Equatable {
  /// The type of media.
  public let type: MediaType

  /// Width of the media in pixels.
  public let width: Int?

  /// Height of the media in pixels.
  public let height: Int?

  /// Duration in seconds.
  public let duration: Double

  /// Original filename, if available.
  public let filename: String?

  /// File path within the document archive.
  public let filepath: String?

  /// Volume level (0.0 to 1.0).
  public let volume: Float

  /// Looping behavior.
  public let loopOption: LoopOption

  /// Poster image data and metadata for video/GIF.
  public let posterImage: ImageInfo?

  /// Caption title metadata.
  public let title: CaptionData?

  /// Caption text metadata.
  public let caption: CaptionData?

  /// Looping options for media playback.
  public enum LoopOption: Sendable, Codable, Equatable {
    /// Play once without looping.
    case none

    /// Repeat continuously.
    case `repeat`

    /// Play forward then backward continuously.
    case backAndForth
  }

  /// Media style properties (border, shadow, opacity).
  public let style: MediaStyle?

  /// Identifier of the `TSP.DataInfo` that supplied the media bytes at `filepath`.
  public let dataID: UInt64?

  /// Content-addressable hash of the media bytes (as stored in `TSP.DataInfo.digest`).
  public let digest: Data?

  /// Globally-unique identifier of the source asset in the user's Photos/Media library,
  /// populated for media inserted via Creator Studio's media picker.
  public let mediaLibraryAssetID: UUID?

  /// Creates a new media info instance.
  ///
  /// - Parameters:
  ///   - type: The type of media.
  ///   - width: Optional width in pixels.
  ///   - height: Optional height in pixels.
  ///   - duration: Duration in seconds.
  ///   - filename: Optional original filename.
  ///   - filepath: Optional file path within document.
  ///   - volume: Volume level (0.0 to 1.0).
  ///   - loopOption: Looping behavior.
  ///   - posterImage: Optional poster image.
  ///   - title: Optional title caption.
  ///   - caption: Optional caption text.
  ///   - style: Optional media style properties.
  ///   - dataID: Identifier of the backing `TSP.DataInfo` entry.
  ///   - digest: Content digest of the media bytes.
  ///   - mediaLibraryAssetID: Source asset UUID in the user's media library, if any.
  public init(
    type: MediaType,
    width: Int?,
    height: Int?,
    duration: Double,
    filename: String?,
    filepath: String?,
    volume: Float,
    loopOption: LoopOption,
    posterImage: ImageInfo?,
    title: CaptionData?,
    caption: CaptionData?,
    style: MediaStyle? = nil,
    dataID: UInt64? = nil,
    digest: Data? = nil,
    mediaLibraryAssetID: UUID? = nil
  ) {
    self.type = type
    self.width = width
    self.height = height
    self.duration = duration
    self.filename = filename
    self.filepath = filepath
    self.volume = volume
    self.loopOption = loopOption
    self.posterImage = posterImage
    self.title = title
    self.caption = caption
    self.style = style
    self.dataID = dataID
    self.digest = digest
    self.mediaLibraryAssetID = mediaLibraryAssetID
  }
}

// MARK: - Shape Path Types

/// Type of path element in a Bézier curve.
public enum PathElementType: Sendable, Codable, Equatable {
  /// Move to a point without drawing.
  case moveTo

  /// Draw a straight line to a point.
  case lineTo

  /// Draw a quadratic Bézier curve.
  case quadCurveTo

  /// Draw a cubic Bézier curve.
  case curveTo

  /// Close the current subpath.
  case closeSubpath
}

/// A point in a vector path.
public struct PathPoint: Sendable, Codable, Equatable {
  /// The x coordinate.
  public let x: Double

  /// The y coordinate.
  public let y: Double

  /// Creates a new path point.
  ///
  /// - Parameters:
  ///   - x: The x coordinate.
  ///   - y: The y coordinate.
  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}

/// A single element in a vector path.
public struct PathElement: Sendable, Codable, Equatable {
  /// The type of path element.
  public let type: PathElementType

  /// Control and end points for this element.
  ///
  /// - moveTo: 1 point (destination)
  /// - lineTo: 1 point (destination)
  /// - quadCurveTo: 2 points (control, destination)
  /// - curveTo: 3 points (control1, control2, destination)
  /// - closeSubpath: 0 points
  public let points: [PathPoint]

  /// Creates a new path element.
  ///
  /// - Parameters:
  ///   - type: The type of element.
  ///   - points: The control and end points.
  public init(type: PathElementType, points: [PathPoint]) {
    self.type = type
    self.points = points
  }
}

/// A Bézier path defining a shape's outline.
public struct BezierPath: Sendable, Codable, Equatable {
  /// The sequence of path elements.
  public let elements: [PathElement]

  /// The natural size of the path before transforms.
  public let naturalSize: CGSize

  /// Creates a new Bézier path.
  ///
  /// - Parameters:
  ///   - elements: The path elements.
  ///   - naturalSize: The natural size before transforms.
  public init(elements: [PathElement], naturalSize: CGSize) {
    self.elements = elements
    self.naturalSize = naturalSize
  }
}

// MARK: - Advanced Path Sources

/// Point-based shape path (arrows, stars, plus signs).
public struct PointPathSource: Sendable, Codable, Equatable {
  /// The type of point-based shape.
  public enum PointType: Sendable, Codable, Equatable {
    /// Left-pointing single arrow.
    case leftSingleArrow

    /// Right-pointing single arrow.
    case rightSingleArrow

    /// Double-headed arrow.
    case doubleArrow

    /// Star shape.
    case star

    /// Plus/cross shape.
    case plus
  }

  /// The type of point shape.
  public let type: PointType

  /// The defining point for the shape.
  public let point: PathPoint

  /// The natural size of the shape before transforms.
  public let naturalSize: CGSize

  /// Creates a new point path source.
  ///
  /// - Parameters:
  ///   - type: The type of point shape.
  ///   - point: The defining point.
  ///   - naturalSize: The natural size before transforms.
  public init(type: PointType, point: PathPoint, naturalSize: CGSize) {
    self.type = type
    self.point = point
    self.naturalSize = naturalSize
  }
}

/// Scalar-based shape path (rounded rectangles, polygons, chevrons).
public struct ScalarPathSource: Sendable, Codable, Equatable {
  /// The type of scalar-based shape.
  public enum ScalarType: Sendable, Codable, Equatable {
    /// Rounded rectangle.
    case roundedRectangle

    /// Regular polygon (pentagon, hexagon, etc.).
    case regularPolygon

    /// Chevron/arrow shape.
    case chevron
  }

  /// The type of scalar shape.
  public let type: ScalarType

  /// The scalar value controlling shape parameters (e.g., corner radius, number of sides).
  public let scalar: Double

  /// The natural size of the shape before transforms.
  public let naturalSize: CGSize

  /// Whether the curve is continuous (smooth corners vs. sharp corners).
  public let isCurveContinuous: Bool

  /// Creates a new scalar path source.
  ///
  /// - Parameters:
  ///   - type: The type of scalar shape.
  ///   - scalar: The scalar parameter value.
  ///   - naturalSize: The natural size before transforms.
  ///   - isCurveContinuous: Whether curves are continuous.
  public init(type: ScalarType, scalar: Double, naturalSize: CGSize, isCurveContinuous: Bool) {
    self.type = type
    self.scalar = scalar
    self.naturalSize = naturalSize
    self.isCurveContinuous = isCurveContinuous
  }
}

/// Callout/speech bubble path source.
public struct CalloutPathSource: Sendable, Codable, Equatable {
  /// The natural size of the callout before transforms.
  public let naturalSize: CGSize

  /// Position of the callout tail/pointer.
  public let tailPosition: PathPoint

  /// Size of the tail in points.
  public let tailSize: Double

  /// Corner radius for the callout bubble.
  public let cornerRadius: Double

  /// Whether the tail is centered on an edge.
  public let centerTail: Bool

  /// Creates a new callout path source.
  ///
  /// - Parameters:
  ///   - naturalSize: The natural size before transforms.
  ///   - tailPosition: Position of the tail.
  ///   - tailSize: Size of the tail in points.
  ///   - cornerRadius: Corner radius for the bubble.
  ///   - centerTail: Whether the tail is centered.
  public init(
    naturalSize: CGSize,
    tailPosition: PathPoint,
    tailSize: Double,
    cornerRadius: Double,
    centerTail: Bool
  ) {
    self.naturalSize = naturalSize
    self.tailPosition = tailPosition
    self.tailSize = tailSize
    self.cornerRadius = cornerRadius
    self.centerTail = centerTail
  }
}

/// Connection line path source (lines connecting shapes).
public struct ConnectionLinePathSource: Sendable, Codable, Equatable {
  /// The type of connection line.
  public enum ConnectionType: Sendable, Codable, Equatable {
    /// Curved quadratic connection.
    case quadratic

    /// Right-angled orthogonal connection.
    case orthogonal
  }

  /// The type of connection.
  public let type: ConnectionType

  /// The underlying Bézier path.
  public let path: BezierPath

  /// Outset distance from the source shape.
  public let outsetFrom: Double

  /// Outset distance from the destination shape.
  public let outsetTo: Double

  /// Creates a new connection line path source.
  ///
  /// - Parameters:
  ///   - type: The type of connection.
  ///   - path: The underlying Bézier path.
  ///   - outsetFrom: Outset from source.
  ///   - outsetTo: Outset to destination.
  public init(type: ConnectionType, path: BezierPath, outsetFrom: Double, outsetTo: Double) {
    self.type = type
    self.path = path
    self.outsetFrom = outsetFrom
    self.outsetTo = outsetTo
  }
}

/// Editable Bézier path with explicit node control points.
public struct EditableBezierPathSource: Sendable, Codable, Equatable {
  /// A node in an editable path.
  public struct Node: Sendable, Codable, Equatable {
    /// The type of node.
    public enum NodeType: Sendable, Codable, Equatable {
      /// Sharp corner with no curve smoothing.
      case sharp

      /// Bézier curve node with independent control points.
      case bezier

      /// Smooth curve node with symmetric control points.
      case smooth
    }

    /// Incoming control point.
    public let inControlPoint: PathPoint

    /// The node point itself.
    public let nodePoint: PathPoint

    /// Outgoing control point.
    public let outControlPoint: PathPoint

    /// The type of node.
    public let type: NodeType

    /// Creates a new editable node.
    ///
    /// - Parameters:
    ///   - inControlPoint: Incoming control point.
    ///   - nodePoint: The node point.
    ///   - outControlPoint: Outgoing control point.
    ///   - type: The node type.
    public init(
      inControlPoint: PathPoint,
      nodePoint: PathPoint,
      outControlPoint: PathPoint,
      type: NodeType
    ) {
      self.inControlPoint = inControlPoint
      self.nodePoint = nodePoint
      self.outControlPoint = outControlPoint
      self.type = type
    }
  }

  /// A subpath (continuous sequence of nodes).
  public struct Subpath: Sendable, Codable, Equatable {
    /// The nodes in this subpath.
    public let nodes: [Node]

    /// Whether this subpath is closed.
    public let closed: Bool

    /// Creates a new subpath.
    ///
    /// - Parameters:
    ///   - nodes: The nodes in the subpath.
    ///   - closed: Whether the subpath is closed.
    public init(nodes: [Node], closed: Bool) {
      self.nodes = nodes
      self.closed = closed
    }
  }

  /// The subpaths making up this path.
  public let subpaths: [Subpath]

  /// The natural size of the path before transforms.
  public let naturalSize: CGSize

  /// Creates a new editable Bézier path source.
  ///
  /// - Parameters:
  ///   - subpaths: The subpaths making up the path.
  ///   - naturalSize: The natural size before transforms.
  public init(subpaths: [Subpath], naturalSize: CGSize) {
    self.subpaths = subpaths
    self.naturalSize = naturalSize
  }
}

/// Unified path source representing all possible shape path types.
public enum PathSource: Sendable, Codable, Equatable {
  /// Point-based shape (arrows, stars, plus signs).
  case point(PointPathSource)

  /// Scalar-based shape (rounded rectangles, polygons, chevrons).
  case scalar(ScalarPathSource)

  /// Standard Bézier path.
  case bezier(BezierPath)

  /// Callout/speech bubble.
  case callout(CalloutPathSource)

  /// Connection line between shapes.
  case connectionLine(ConnectionLinePathSource)

  /// Editable Bézier path with explicit node controls.
  case editableBezier(EditableBezierPathSource)
}

// MARK: - Shape Fill Types

/// Fill style for a shape.
public enum ShapeFill: Sendable, Codable, Equatable {
  /// No fill.
  case none

  /// Solid color fill.
  case color(Color)

  /// Gradient fill with multiple color stops.
  case gradient([Color])

  /// Image fill with data and metadata.
  case image(ImageInfo)
}

/// Shadow effect for shapes.
public struct Shadow: Sendable, Codable, Equatable {
  /// Horizontal offset in points.
  public let offsetX: Double

  /// Vertical offset in points.
  public let offsetY: Double

  /// Blur radius in points.
  public let blurRadius: Double

  /// Shadow color.
  public let color: Color

  /// Shadow opacity (0.0 to 1.0).
  public let opacity: Double

  /// Creates a new shadow.
  ///
  /// - Parameters:
  ///   - offsetX: Horizontal offset in points.
  ///   - offsetY: Vertical offset in points.
  ///   - blurRadius: Blur radius in points.
  ///   - color: Shadow color.
  ///   - opacity: Shadow opacity (0.0 to 1.0).
  public init(
    offsetX: Double,
    offsetY: Double,
    blurRadius: Double,
    color: Color,
    opacity: Double = 1.0
  ) {
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.blurRadius = blurRadius
    self.color = color
    self.opacity = opacity
  }
}

/// Style properties for a shape.
public struct ShapeStyle: Sendable, Codable, Equatable {
  /// Fill style for the shape interior.
  public let fill: ShapeFill

  /// Stroke/border for the shape outline.
  public let stroke: Border?

  /// Overall opacity of the shape (0.0 to 1.0).
  public let opacity: Double

  /// Drop shadow effect.
  public let shadow: Shadow?

  /// Vertical alignment within a text box or container.
  public let verticalAlignment: VerticalAlignment?

  /// Padding/margins around the shape.
  public let padding: Padding?

  /// Multi-column layout for text within the shape.
  public let columns: Columns?

  /// Creates a new shape style.
  ///
  /// - Parameters:
  ///   - fill: Fill style for the interior.
  ///   - verticalAlignment: Vertical alignment within container.
  ///   - stroke: Optional stroke for the outline.
  ///   - opacity: Overall opacity (0.0 to 1.0).
  ///   - shadow: Optional drop shadow.
  public init(
    fill: ShapeFill,
    verticalAlignment: VerticalAlignment? = nil,
    padding: Padding? = nil,
    columns: Columns? = nil,
    stroke: Border?,
    opacity: Double = 1.0,
    shadow: Shadow? = nil
  ) {
    self.fill = fill
    self.verticalAlignment = verticalAlignment
    self.padding = padding
    self.columns = columns
    self.stroke = stroke
    self.opacity = opacity
    self.shadow = shadow
  }

  /// Vertical alignment options.
  public enum VerticalAlignment: Sendable, Codable, Equatable {
    /// Top-aligned.
    case top

    /// Middle-aligned.
    case middle

    /// Bottom-aligned.
    case bottom

    /// Justified
    case justify
  }

  /// Represents padding or margins in points.
  public struct Padding: Sendable, Codable, Equatable {
    public let top: Double
    public let left: Double
    public let bottom: Double
    public let right: Double
  }

  /// Represents a multi-column layout for text.
  public enum Columns: Sendable, Codable, Equatable {
    /// Columns all have the same width and gap.
    case equal(count: Int, gap: Double)

    /// Each column can have a custom width and gap.
    case nonEqual([ColumnDefinition])

    /// Defines a single column's width and the gap that precedes it.
    public struct ColumnDefinition: Sendable, Codable, Equatable {
      public let width: Double
      public let gap: Double  // Gap is 0 for the first column.
    }
  }
}

// MARK: - Shape Information

/// Information about a geometric shape element.
public struct ShapeInfo: Sendable, Codable, Equatable {
  /// The path defining the shape outline (supports all path types).
  public let path: PathSource

  /// Style properties (fill, stroke, shadow).
  public let style: ShapeStyle

  /// Optional title caption.
  public let title: CaptionData?

  /// Optional caption text.
  public let caption: CaptionData?

  /// Whether the shape is horizontally flipped.
  public let isHorizontallyFlipped: Bool

  /// Whether the shape is vertically flipped.
  public let isVerticallyFlipped: Bool

  /// Optional localization key for built-in shapes.
  public let localizationKey: String?

  /// Optional user-defined name for the shape.
  public let userDefinedName: String?

  /// Optional hyperlink associated with the shape (it means the shape is clickable).
  public let hyperlink: Hyperlink?

  /// Creates a new shape info instance.
  ///
  /// - Parameters:
  ///   - path: The path source (supports all path types).
  ///   - style: Style properties.
  ///   - title: Optional title caption.
  ///   - caption: Optional caption text.
  ///   - isHorizontallyFlipped: Whether horizontally flipped.
  ///   - isVerticallyFlipped: Whether vertically flipped.
  ///   - localizationKey: Optional localization key.
  ///   - userDefinedName: Optional user-defined name.
  ///   - hyperlink: Optional hyperlink for the shape.
  public init(
    path: PathSource,
    style: ShapeStyle,
    title: CaptionData?,
    caption: CaptionData?,
    isHorizontallyFlipped: Bool = false,
    isVerticallyFlipped: Bool = false,
    localizationKey: String? = nil,
    userDefinedName: String? = nil,
    hyperlink: Hyperlink? = nil
  ) {
    self.path = path
    self.style = style
    self.title = title
    self.caption = caption
    self.isHorizontallyFlipped = isHorizontallyFlipped
    self.isVerticallyFlipped = isVerticallyFlipped
    self.localizationKey = localizationKey
    self.userDefinedName = userDefinedName
    self.hyperlink = hyperlink
  }
}

/// A footnote with its position and content.
public struct Footnote: Sendable, Codable, Equatable {
  /// The sequential number of the footnote (e.g., 1, 2, 3).
  public let number: Int

  /// The character position of the footnote marker within the paragraph.
  public let positionInTextRun: Int

  /// The inline content of the footnote (text, images, equations, shapes, etc.).
  public let content: [InlineElement]

  /// Creates a new footnote instance.
  ///
  /// - Parameters:
  ///   - number: The sequential footnote number.
  ///   - positionInTextRun: Character position of the marker in the paragraph.
  ///   - content: The footnote's inline content elements.
  public init(number: Int, positionInTextRun: Int, content: [InlineElement]) {
    self.number = number
    self.positionInTextRun = positionInTextRun
    self.content = content
  }
}

// MARK: - OCR Types

/// Provides optical character recognition capabilities for images.
public protocol OCRProvider: Sendable {
  /// Recognizes text in an image.
  ///
  /// - Parameters:
  ///   - imageData: The raw image data to analyze.
  ///   - info: Metadata about the image (dimensions, format, etc.).
  /// - Returns: Recognition result containing text and observations.
  /// - Throws: An error if text recognition fails.
  func recognizeText(
    in imageData: Data,
    info: ImageInfo
  ) async throws -> OCRResult
}

/// Placeholder used when no OCR provider is configured.
public struct NullOCRProvider: OCRProvider {
  public func recognizeText(in imageData: Data, info: ImageInfo) async throws -> OCRResult {
    fatalError("OCR not configured")
  }
}

public struct Mask: Sendable, Codable, Equatable {
  /// The geometric shape of the mask (e.g., a star, rounded rectangle, or custom path).
  public let path: PathSource

  /// The mask's absolute position on the slide's canvas.
  public let position: CGPoint

  /// The mask's absolute size on the slide's canvas.
  public let size: CGSize

  /// The mask's rotation angle in radians.
  public let angle: CGFloat

  /// The affine transform describing the image's position, scale, and rotation *relative to the mask's frame*.
  public let imageTransform: CGAffineTransform

  public init(
    path: PathSource,
    position: CGPoint,
    size: CGSize,
    angle: CGFloat,
    imageTransform: CGAffineTransform
  ) {
    self.path = path
    self.position = position
    self.size = size
    self.angle = angle
    self.imageTransform = imageTransform
  }
}

/// Style properties for media elements like images and movies.
public struct MediaStyle: Sendable, Codable, Equatable {
  /// The border/stroke around the media.
  public let border: Border?

  /// The overall opacity of the media (0.0 to 1.0).
  public let opacity: Double

  /// A shadow effect applied to the media.
  public let shadow: Shadow?

  /// The opacity of the reflection effect (0.0 to 1.0).
  public let reflectionOpacity: Double?

  /// An optional mask defining the visible area of the media.
  public let mask: Mask?

  /// Creates a new media style.
  ///
  /// - Parameters:
  ///   - border: The border/stroke.
  ///   - opacity: The overall opacity.
  ///   - shadow: The shadow effect.
  ///   - reflectionOpacity: The opacity of the reflection.
  ///   - mask: An optional mask path.
  public init(
    border: Border?,
    opacity: Double = 1.0,
    shadow: Shadow? = nil,
    reflectionOpacity: Double? = nil,
    mask: Mask? = nil
  ) {
    self.border = border
    self.opacity = opacity
    self.shadow = shadow
    self.reflectionOpacity = reflectionOpacity
    self.mask = mask
  }
}

/// Information about an image being processed.
public struct ImageInfo: Sendable, Codable, Equatable {
  /// The width of the image in pixels.
  public let width: Int

  /// The height of the image in pixels.
  public let height: Int

  /// The original filename, if available.
  public let filename: String?

  /// The file path within the document archive.
  public let filepath: String

  /// The description of the image.
  public let description: String?

  /// Caption title, if available.
  public let title: CaptionData?

  /// Caption text, if available.
  public let caption: CaptionData?

  /// Additional metadata attributes for the image.
  public let attributes: [String: String]?

  /// Media style properties applied to the image.
  public let style: MediaStyle?

  /// Identifier of the `TSP.DataInfo` that supplied the bytes at `filepath`.
  /// Unique within the document package. For Creator Studio template placeholders this
  /// is the `-small-N` derivative's identifier rather than the (unmaterialized) primary.
  public let dataID: UInt64?

  /// Content-addressable hash of the image bytes (as stored in `TSP.DataInfo.digest`).
  /// Stable across documents containing the same asset — use for dedup/comparison.
  public let digest: Data?

  /// Globally-unique identifier of the source asset in the user's Photos/Media library,
  /// populated for images inserted via Creator Studio's media picker. `nil` for images
  /// sourced from clipboard, drag-and-drop, or older (pre-Creator Studio) insertions.
  public let mediaLibraryAssetID: UUID?

  /// Creates a new image info instance.
  ///
  /// - Parameters:
  ///   - width: The width in pixels.
  ///   - height: The height in pixels.
  ///   - filename: Optional original filename.
  ///   - description: Optional image description.
  ///   - filepath: File path within the document archive.
  ///   - title: Optional title caption.
  ///   - caption: Optional caption text.
  ///   - attributes: Optional additional metadata attributes.
  ///   - style: Optional media style properties.
  ///   - dataID: Identifier of the backing `TSP.DataInfo` entry.
  ///   - digest: Content digest of the image bytes.
  ///   - mediaLibraryAssetID: Source asset UUID in the user's media library, if any.
  public init(
    width: Int,
    height: Int,
    filename: String?,
    description: String?,
    filepath: String,
    title: CaptionData? = nil,
    caption: CaptionData? = nil,
    attributes: [String: String]? = nil,
    style: MediaStyle? = nil,
    dataID: UInt64? = nil,
    digest: Data? = nil,
    mediaLibraryAssetID: UUID? = nil
  ) {
    self.width = width
    self.height = height
    self.description = description
    self.filename = filename
    self.filepath = filepath
    self.title = title
    self.caption = caption
    self.attributes = attributes
    self.style = style
    self.dataID = dataID
    self.digest = digest
    self.mediaLibraryAssetID = mediaLibraryAssetID
  }
}

/// Result of OCR text recognition.
public struct OCRResult: Sendable, Codable, Equatable {
  /// The full recognized text.
  public let text: String

  /// Individual text observations with positioning and confidence.
  public let observations: [TextObservation]

  /// Creates a new OCR result instance.
  ///
  /// - Parameters:
  ///   - text: The full recognized text.
  ///   - observations: Individual text observations.
  public init(text: String, observations: [TextObservation]) {
    self.text = text
    self.observations = observations
  }
}

/// A single text observation from OCR.
public struct TextObservation: Sendable, Codable, Equatable {
  /// The recognized text for this observation.
  public let text: String

  /// Confidence level (0.0 to 1.0).
  public let confidence: Double

  /// The bounding quadrilateral for this text.
  public let boundingQuad: BoundingQuad

  /// Creates a new text observation instance.
  ///
  /// - Parameters:
  ///   - text: The recognized text.
  ///   - confidence: Confidence level (0.0 to 1.0).
  ///   - boundingQuad: The bounding quadrilateral.
  public init(text: String, confidence: Double, boundingQuad: BoundingQuad) {
    self.text = text
    self.confidence = confidence
    self.boundingQuad = boundingQuad
  }
}

/// A quadrilateral defining the bounds of detected text.
public struct BoundingQuad: Sendable, Codable, Equatable {
  /// A point in 2D space.
  public struct Point: Sendable, Codable, Equatable {
    /// The x coordinate.
    public let x: Double

    /// The y coordinate.
    public let y: Double

    /// Creates a new point.
    ///
    /// - Parameters:
    ///   - x: The x coordinate.
    ///   - y: The y coordinate.
    public init(x: Double, y: Double) {
      self.x = x
      self.y = y
    }
  }

  /// Top-left corner (normalized coordinates, 0.0 to 1.0).
  public let topLeft: Point

  /// Top-right corner (normalized coordinates, 0.0 to 1.0).
  public let topRight: Point

  /// Bottom-left corner (normalized coordinates, 0.0 to 1.0).
  public let bottomLeft: Point

  /// Bottom-right corner (normalized coordinates, 0.0 to 1.0).
  public let bottomRight: Point

  /// Creates a new bounding quadrilateral.
  ///
  /// - Parameters:
  ///   - topLeft: Top-left corner.
  ///   - topRight: Top-right corner.
  ///   - bottomLeft: Bottom-left corner.
  ///   - bottomRight: Bottom-right corner.
  public init(topLeft: Point, topRight: Point, bottomLeft: Point, bottomRight: Point) {
    self.topLeft = topLeft
    self.topRight = topRight
    self.bottomLeft = bottomLeft
    self.bottomRight = bottomRight
  }
}

// MARK: - Spatial and Layout Types

/// Coordinate space for positioning information.
public enum CoordinateSpace: Sendable, Codable, Equatable {
  /// Pages document body coordinates.
  case pageBody

  /// Keynote slide coordinates.
  case slide

  /// Numbers sheet coordinates.
  case sheet

  /// Floating elements that exist outside normal flow.
  case floating
}

/// Complete spatial information for a positioned element.
public struct SpatialInfo: Sendable, Codable, Equatable {
  /// The coordinate space this position is relative to.
  public let coordinateSpace: CoordinateSpace

  /// Frame of the element in points.
  public let frame: CGRect

  /// Rotation angle in radians.
  public let rotation: Double

  /// Z-order index (higher values are in front).
  public let zIndex: Int?

  /// Whether this element is anchored to text flow.
  public let isAnchoredToText: Bool

  /// Whether this element floats above text.
  public let isFloatingAboveText: Bool

  /// Underlying record identifier of the drawable (image/shape/table/…) this spatial info
  /// describes, unique within the document package. `nil` for synthetic elements with no
  /// backing record. Use to correlate two visitor callbacks that refer to the same object.
  public let drawableID: UInt64?

  /// Creates a new spatial info instance.
  ///
  /// - Parameters:
  ///   - coordinateSpace: The coordinate space.
  ///   - frame: Frame of the element in points.
  ///   - rotation: Rotation angle in radians.
  ///   - zIndex: Optional z-order index.
  ///   - isAnchoredToText: Whether anchored to text flow.
  ///   - isFloatingAboveText: Whether floating above text.
  ///   - drawableID: Optional document-local record identifier.
  public init(
    coordinateSpace: CoordinateSpace,
    frame: CGRect,
    rotation: Double = 0,
    zIndex: Int? = nil,
    isAnchoredToText: Bool = false,
    isFloatingAboveText: Bool = false,
    drawableID: UInt64? = nil
  ) {
    self.coordinateSpace = coordinateSpace
    self.frame = frame
    self.rotation = rotation
    self.zIndex = zIndex
    self.isAnchoredToText = isAnchoredToText
    self.isFloatingAboveText = isFloatingAboveText
    self.drawableID = drawableID
  }

  /// The center point of the element.
  public var center: CGPoint {
    CGPoint(x: frame.midX, y: frame.midY)
  }

  /// The origin point of the element.
  public var origin: CGPoint {
    frame.origin
  }

  /// The size of the element.
  public var size: CGSize {
    frame.size
  }
}

/// Represents document dimensions and layout.
public struct DocumentLayout: Sendable, Codable, Equatable {
  /// Page width in points.
  public let pageWidth: Double

  /// Page height in points.
  public let pageHeight: Double

  /// Left margin in points.
  public let leftMargin: Double

  /// Right margin in points.
  public let rightMargin: Double

  /// Top margin in points.
  public let topMargin: Double

  /// Bottom margin in points.
  public let bottomMargin: Double

  /// Header margin in points.
  public let headerMargin: Double

  /// Footer margin in points.
  public let footerMargin: Double

  /// Page orientation (0 = portrait, non-zero = landscape).
  public let orientation: UInt32

  /// Creates a new document layout instance.
  ///
  /// - Parameters:
  ///   - pageWidth: Page width in points.
  ///   - pageHeight: Page height in points.
  ///   - leftMargin: Left margin in points.
  ///   - rightMargin: Right margin in points.
  ///   - topMargin: Top margin in points.
  ///   - bottomMargin: Bottom margin in points.
  ///   - headerMargin: Header margin in points.
  ///   - footerMargin: Footer margin in points.
  ///   - orientation: Page orientation value.
  public init(
    pageWidth: Double,
    pageHeight: Double,
    leftMargin: Double,
    rightMargin: Double,
    topMargin: Double,
    bottomMargin: Double,
    headerMargin: Double,
    footerMargin: Double,
    orientation: UInt32
  ) {
    self.pageWidth = pageWidth
    self.pageHeight = pageHeight
    self.leftMargin = leftMargin
    self.rightMargin = rightMargin
    self.topMargin = topMargin
    self.bottomMargin = bottomMargin
    self.headerMargin = headerMargin
    self.footerMargin = footerMargin
    self.orientation = orientation
  }

  /// The content area after accounting for margins.
  public var contentRect: CGRect {
    CGRect(
      x: leftMargin,
      y: topMargin,
      width: pageWidth - leftMargin - rightMargin,
      height: pageHeight - topMargin - bottomMargin
    )
  }

  /// The full page bounds.
  public var pageRect: CGRect {
    CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
  }
}

/// Represents sheet dimensions and layout for Numbers documents.
public struct SheetLayout: Sendable, Codable, Equatable {
  /// Sheet page width in points.
  public let pageWidth: Double?

  /// Sheet page height in points.
  public let pageHeight: Double?

  /// Top margin in points.
  public let topMargin: Double?

  /// Left margin in points.
  public let leftMargin: Double?

  /// Bottom margin in points.
  public let bottomMargin: Double?

  /// Right margin in points.
  public let rightMargin: Double?

  /// Whether the sheet is in portrait orientation.
  public let isPortrait: Bool?

  /// Content scale factor.
  public let contentScale: Double?

  /// Header inset in points.
  public let headerInset: Double?

  /// Footer inset in points.
  public let footerInset: Double?

  /// Creates a new sheet layout instance.
  ///
  /// - Parameters:
  ///   - pageWidth: Optional page width in points.
  ///   - pageHeight: Optional page height in points.
  ///   - topMargin: Optional top margin in points.
  ///   - leftMargin: Optional left margin in points.
  ///   - bottomMargin: Optional bottom margin in points.
  ///   - rightMargin: Optional right margin in points.
  ///   - isPortrait: Optional portrait orientation flag.
  ///   - contentScale: Optional content scale factor.
  ///   - headerInset: Optional header inset in points.
  ///   - footerInset: Optional footer inset in points.
  public init(
    pageWidth: Double?,
    pageHeight: Double?,
    topMargin: Double?,
    leftMargin: Double?,
    bottomMargin: Double?,
    rightMargin: Double?,
    isPortrait: Bool?,
    contentScale: Double?,
    headerInset: Double?,
    footerInset: Double?
  ) {
    self.pageWidth = pageWidth
    self.pageHeight = pageHeight
    self.topMargin = topMargin
    self.leftMargin = leftMargin
    self.bottomMargin = bottomMargin
    self.rightMargin = rightMargin
    self.isPortrait = isPortrait
    self.contentScale = contentScale
    self.headerInset = headerInset
    self.footerInset = footerInset
  }

  /// The printable content area after accounting for margins.
  public var contentRect: CGRect? {
    guard let pageWidth = pageWidth,
      let pageHeight = pageHeight,
      let leftMargin = leftMargin,
      let rightMargin = rightMargin,
      let topMargin = topMargin,
      let bottomMargin = bottomMargin
    else {
      return nil
    }

    return CGRect(
      x: leftMargin,
      y: topMargin,
      width: pageWidth - leftMargin - rightMargin,
      height: pageHeight - topMargin - bottomMargin
    )
  }

  /// The full page bounds.
  public var pageBounds: CGRect? {
    guard let pageWidth = pageWidth,
      let pageHeight = pageHeight
    else {
      return nil
    }

    return CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
  }
}

// MARK: - Page Settings Types

/// Configuration settings for a Pages document.
public struct PageSettings: Sendable, Codable, Equatable {
  /// Whether the body content is included.
  public let body: Bool

  /// Whether headers are included.
  public let headers: Bool

  /// Whether footers are included.
  public let footers: Bool

  /// Whether preview content is included.
  public let preview: Bool

  /// Whether movies are copied into the document.
  public let copyMovies: Bool

  /// Whether assets are copied into the document.
  public let copyAssets: Bool

  /// Whether placeholder authoring is enabled.
  public let placeholderAuthoring: Bool

  /// Whether hyperlinks are enabled.
  public let linksEnabled: Bool

  /// Whether automatic hyphenation is enabled.
  public let hyphenation: Bool

  /// Whether ligatures are used in text rendering.
  public let useLigatures: Bool

  /// Whether table of contents links are enabled.
  public let tocLinksEnabled: Bool

  /// Whether change tracking markup is shown.
  public let showChangeTrackingMarkup: Bool

  /// Whether change tracking deletions are shown.
  public let showChangeTrackingDeletions: Bool

  /// Visibility level for change tracking bubbles.
  public let changeTrackingBubblesVisibility: Int

  /// Whether change bars are visible in margins.
  public let changeBarsVisible: Bool

  /// Whether format changes are visible.
  public let formatChangesVisible: Bool

  /// Whether annotations (comments) are visible.
  public let annotationsVisible: Bool

  /// Whether the document uses right-to-left layout.
  public let documentIsRightToLeft: Bool

  /// Character used for decimal tab stops.
  public let decimalTab: String

  /// Primary language code for the document (e.g., "en", "ja").
  public let language: String

  /// Language code for hyphenation rules.
  public let hyphenationLanguage: String

  /// Locale identifier used when creating the document (e.g., "en_US", "en_JP").
  public let creationLocale: String

  /// Name of the template used to create the document.
  public let templateName: String

  /// ISO 8601 date string of when the document was created.
  public let creationDate: String?

  /// The type of footnote/endnote system used.
  public let footnoteKind: FootnoteKind

  /// Number format for footnote markers.
  public let footnoteFormat: FootnoteFormat

  /// How footnote numbers are tracked across the document.
  public let footnoteNumbering: FootnoteNumbering

  /// Gap between footnotes in points.
  public let footnoteGap: Double

  /// Whether the document uses facing pages layout.
  public let facingPages: Bool

  /// Whether section authoring mode is enabled.
  public let sectionAuthoring: Bool

  /// Type of footnote/endnote placement.
  public enum FootnoteKind: Int, Sendable, Codable, Equatable {
    /// Footnotes at bottom of each page.
    case footnotes = 0

    /// Endnotes at end of entire document.
    case documentEndnotes = 1

    /// Endnotes at end of each section.
    case sectionEndnotes = 2
  }

  /// Formatting style for footnote markers.
  public enum FootnoteFormat: Int, Sendable, Codable, Equatable {
    /// 1, 2, 3, ...
    case numeric = 0

    /// i, ii, iii, ...
    case roman = 1

    /// *, †, ‡, ...
    case symbolic = 2

    /// 一, 二, 三, ...
    case japaneseNumeric = 3

    /// Japanese ideographic numerals.
    case japaneseIdeographic = 4

    /// Arabic numeric format.
    case arabicNumeric = 5
  }

  /// How footnote numbering restarts.
  public enum FootnoteNumbering: Int, Sendable, Codable, Equatable {
    /// Continue numbering throughout document.
    case continuous = 0

    /// Restart numbering on each page.
    case restartEachPage = 1

    /// Restart numbering in each section.
    case restartEachSection = 2
  }

  /// Creates a new page settings instance.
  ///
  /// - Parameters:
  ///   - body: Whether the body content is included.
  ///   - headers: Whether headers are included.
  ///   - footers: Whether footers are included.
  ///   - preview: Whether preview content is included.
  ///   - copyMovies: Whether movies are copied into the document.
  ///   - copyAssets: Whether assets are copied into the document.
  ///   - placeholderAuthoring: Whether placeholder authoring is enabled.
  ///   - linksEnabled: Whether hyperlinks are enabled.
  ///   - hyphenation: Whether automatic hyphenation is enabled.
  ///   - useLigatures: Whether ligatures are used.
  ///   - tocLinksEnabled: Whether table of contents links are enabled.
  ///   - showChangeTrackingMarkup: Whether change tracking markup is shown.
  ///   - showChangeTrackingDeletions: Whether change tracking deletions are shown.
  ///   - changeTrackingBubblesVisibility: Visibility level for change tracking bubbles.
  ///   - changeBarsVisible: Whether change bars are visible.
  ///   - formatChangesVisible: Whether format changes are visible.
  ///   - annotationsVisible: Whether annotations are visible.
  ///   - documentIsRightToLeft: Whether the document uses right-to-left layout.
  ///   - decimalTab: Character used for decimal tab stops.
  ///   - language: Primary language code for the document.
  ///   - hyphenationLanguage: Language code for hyphenation rules.
  ///   - creationLocale: Locale identifier used when creating the document.
  ///   - templateName: Name of the template used.
  ///   - creationDate: Optional ISO 8601 creation date string.
  ///   - footnoteKind: The type of footnote/endnote system.
  ///   - footnoteFormat: Number format for footnote markers.
  ///   - footnoteNumbering: How footnote numbers are tracked.
  ///   - footnoteGap: Gap between footnotes in points.
  ///   - facingPages: Whether the document uses facing pages layout.
  ///   - sectionAuthoring: Whether section authoring mode is enabled.
  public init(
    body: Bool = true,
    headers: Bool = true,
    footers: Bool = true,
    preview: Bool = true,
    copyMovies: Bool = true,
    copyAssets: Bool = true,
    placeholderAuthoring: Bool = false,
    linksEnabled: Bool = true,
    hyphenation: Bool = false,
    useLigatures: Bool = true,
    tocLinksEnabled: Bool = false,
    showChangeTrackingMarkup: Bool = true,
    showChangeTrackingDeletions: Bool = true,
    changeTrackingBubblesVisibility: Int = 0,
    changeBarsVisible: Bool = true,
    formatChangesVisible: Bool = true,
    annotationsVisible: Bool = true,
    documentIsRightToLeft: Bool = false,
    decimalTab: String = ".",
    language: String = "en",
    hyphenationLanguage: String = "",
    creationLocale: String = "en_US",
    templateName: String = "Blank",
    creationDate: String? = nil,
    footnoteKind: FootnoteKind = .footnotes,
    footnoteFormat: FootnoteFormat = .numeric,
    footnoteNumbering: FootnoteNumbering = .continuous,
    footnoteGap: Double = 10,
    facingPages: Bool = false,
    sectionAuthoring: Bool = false
  ) {
    self.body = body
    self.headers = headers
    self.footers = footers
    self.preview = preview
    self.copyMovies = copyMovies
    self.copyAssets = copyAssets
    self.placeholderAuthoring = placeholderAuthoring
    self.linksEnabled = linksEnabled
    self.hyphenation = hyphenation
    self.useLigatures = useLigatures
    self.tocLinksEnabled = tocLinksEnabled
    self.showChangeTrackingMarkup = showChangeTrackingMarkup
    self.showChangeTrackingDeletions = showChangeTrackingDeletions
    self.changeTrackingBubblesVisibility = changeTrackingBubblesVisibility
    self.changeBarsVisible = changeBarsVisible
    self.formatChangesVisible = formatChangesVisible
    self.annotationsVisible = annotationsVisible
    self.documentIsRightToLeft = documentIsRightToLeft
    self.decimalTab = decimalTab
    self.language = language
    self.hyphenationLanguage = hyphenationLanguage
    self.creationLocale = creationLocale
    self.templateName = templateName
    self.creationDate = creationDate
    self.footnoteKind = footnoteKind
    self.footnoteFormat = footnoteFormat
    self.footnoteNumbering = footnoteNumbering
    self.footnoteGap = footnoteGap
    self.facingPages = facingPages
    self.sectionAuthoring = sectionAuthoring
  }
}

// MARK: - Text Formatting Types

/// Text shadow effect.
public struct TextShadow: Sendable, Codable, Equatable {
  /// Horizontal offset in points.
  public let offsetX: Double

  /// Vertical offset in points.
  public let offsetY: Double

  /// Blur radius in points.
  public let blurRadius: Double

  /// Shadow color.
  public let color: Color

  /// Shadow opacity (0.0 to 1.0).
  public let opacity: Double

  /// Creates a new text shadow.
  ///
  /// - Parameters:
  ///   - offsetX: Horizontal offset in points.
  ///   - offsetY: Vertical offset in points.
  ///   - blurRadius: Blur radius in points.
  ///   - color: Shadow color.
  ///   - opacity: Shadow opacity (0.0 to 1.0).
  public init(
    offsetX: Double,
    offsetY: Double,
    blurRadius: Double,
    color: Color,
    opacity: Double = 1.0
  ) {
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.blurRadius = blurRadius
    self.color = color
    self.opacity = opacity
  }
}

/// Writing direction for text layout.
public enum WritingDirection: Sendable, Codable, Equatable {
  /// Natural direction based on system locale.
  case natural

  /// Left-to-right (e.g., English, most Latin scripts).
  case leftToRight

  /// Right-to-left (e.g., Arabic, Hebrew).
  case rightToLeft
}

/// Character-level styling information.
public struct CharacterStyle: Sendable, Codable, Equatable {
  /// Whether the text is bold.
  public let isBold: Bool

  /// Whether the text is italic.
  public let isItalic: Bool

  /// Whether the text is underlined.
  public let isUnderline: Bool

  /// Whether the text has strikethrough.
  public let isStrikethrough: Bool

  /// Font size in points.
  public let fontSize: Double?

  /// Font name.
  public let fontName: String?

  /// Text color.
  public let color: Color?

  /// Background color.
  public let backgroundColor: Color?

  /// Baseline shift in points (positive = superscript, negative = subscript).
  public let baselineShift: Double?

  /// Text shadow effect.
  public let shadow: TextShadow?

  /// Character tracking/letter spacing in points.
  public let tracking: Double?

  /// Writing direction override.
  public let writingDirection: WritingDirection?

  /// Creates a new character style.
  ///
  /// - Parameters:
  ///   - isBold: Whether the text is bold.
  ///   - isItalic: Whether the text is italic.
  ///   - isUnderline: Whether the text is underlined.
  ///   - isStrikethrough: Whether the text has strikethrough.
  ///   - fontSize: Optional font size in points.
  ///   - fontName: Optional font name.
  ///   - color: Optional text color.
  ///   - backgroundColor: Optional background color.
  ///   - baselineShift: Optional baseline shift in points.
  ///   - shadow: Optional text shadow effect.
  ///   - tracking: Optional character tracking in points.
  ///   - writingDirection: Optional writing direction override.
  public init(
    isBold: Bool = false,
    isItalic: Bool = false,
    isUnderline: Bool = false,
    isStrikethrough: Bool = false,
    fontSize: Double? = nil,
    fontName: String? = nil,
    color: Color? = nil,
    backgroundColor: Color? = nil,
    baselineShift: Double? = nil,
    shadow: TextShadow? = nil,
    tracking: Double? = nil,
    writingDirection: WritingDirection? = nil
  ) {
    self.isBold = isBold
    self.isItalic = isItalic
    self.isUnderline = isUnderline
    self.isStrikethrough = isStrikethrough
    self.fontSize = fontSize
    self.fontName = fontName
    self.color = color
    self.backgroundColor = backgroundColor
    self.baselineShift = baselineShift
    self.shadow = shadow
    self.tracking = tracking
    self.writingDirection = writingDirection
  }
}

/// Line spacing mode for paragraphs.
public enum LineSpacingMode: Sendable, Codable, Equatable {
  /// Relative line spacing (multiple of font size).
  case relative(Double)

  /// Minimum line spacing in points.
  case minimum(Double)

  /// Exact line spacing in points.
  case exact(Double)

  /// Maximum line spacing in points.
  case maximum(Double)

  /// Space between lines in points.
  case between(Double)
}

/// Tab stop definition.
public struct TabStop: Sendable, Codable, Equatable {
  /// Tab alignment type.
  public enum TabAlignment: Sendable, Codable, Equatable {
    /// Left-aligned tab.
    case left

    /// Center-aligned tab.
    case center

    /// Right-aligned tab.
    case right

    /// Decimal-aligned tab.
    case decimal
  }

  /// Position of the tab stop in points from the left margin.
  public let position: Double

  /// Tab alignment type.
  public let alignment: TabAlignment

  /// Leader character (e.g., dots for table of contents).
  public let leader: String?

  /// Creates a new tab stop.
  ///
  /// - Parameters:
  ///   - position: Position in points from left margin.
  ///   - alignment: Tab alignment type.
  ///   - leader: Optional leader character.
  public init(position: Double, alignment: TabAlignment, leader: String? = nil) {
    self.position = position
    self.alignment = alignment
    self.leader = leader
  }
}

/// Paragraph border/rule information.
public struct ParagraphBorder: Sendable, Codable, Equatable {
  /// Edges that can have borders.
  public struct BorderEdges: OptionSet, Sendable, Codable, Equatable {
    public let rawValue: Int

    /// Creates a new border edges option set.
    ///
    /// - Parameter rawValue: The raw integer value.
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Top edge.
    public static let top = BorderEdges(rawValue: 1 << 0)

    /// Right edge.
    public static let right = BorderEdges(rawValue: 1 << 1)

    /// Bottom edge.
    public static let bottom = BorderEdges(rawValue: 1 << 2)

    /// Left edge.
    public static let left = BorderEdges(rawValue: 1 << 3)

    /// All edges.
    public static let all: BorderEdges = [.top, .right, .bottom, .left]

    /// Top and bottom edges.
    public static let horizontal: BorderEdges = [.top, .bottom]

    /// Left and right edges.
    public static let vertical: BorderEdges = [.left, .right]
  }

  /// Border stroke style.
  public let stroke: Border

  /// Which edges have borders.
  public let edges: BorderEdges

  /// Whether corners are rounded.
  public let hasRoundedCorners: Bool

  /// Creates a new paragraph border.
  ///
  /// - Parameters:
  ///   - stroke: Border stroke style.
  ///   - edges: Which edges have borders.
  ///   - hasRoundedCorners: Whether corners are rounded.
  public init(stroke: Border, edges: BorderEdges, hasRoundedCorners: Bool = false) {
    self.stroke = stroke
    self.edges = edges
    self.hasRoundedCorners = hasRoundedCorners
  }
}

/// List/bullet style for paragraphs.
public enum ListStyle: Sendable, Codable, Equatable {
  /// List number formatting styles.
  public enum ListNumberStyle: Sendable, Codable, Equatable {
    /// 1. 2. 3.
    case numeric

    /// 1) 2) 3)
    case numericParen

    /// (1) (2) (3)
    case numericDoubleParen

    /// I. II. III.
    case romanUpper

    /// I) II) III)
    case romanUpperParen

    /// (I) (II) (III)
    case romanUpperDoubleParen

    /// i. ii. iii.
    case romanLower

    /// i) ii) iii)
    case romanLowerParen

    /// (i) (ii) (iii)
    case romanLowerDoubleParen

    /// A. B. C.
    case alphaUpper

    /// A) B) C)
    case alphaUpperParen

    /// (A) (B) (C)
    case alphaUpperDoubleParen

    /// a. b. c.
    case alphaLower

    /// a) b) c)
    case alphaLowerParen

    /// (a) (b) (c)
    case alphaLowerDoubleParen
  }

  /// No list formatting.
  case none

  /// Bulleted list with a specific bullet character.
  case bullet(String)

  /// Numbered list with formatting information.
  case numbered(ListNumberStyle)
}

/// Paragraph-level styling information.
public struct ParagraphStyle: Sendable, Codable, Equatable {
  /// Text alignment.
  public let alignment: TextAlignment

  /// Left indent in points.
  public let leftIndent: Double

  /// Right indent in points.
  public let rightIndent: Double

  /// First line indent in points.
  public let firstLineIndent: Double

  /// Space before paragraph in points.
  public let spaceBefore: Double

  /// Space after paragraph in points.
  public let spaceAfter: Double

  /// Line spacing mode and amount.
  public let lineSpacing: LineSpacingMode?

  /// Tab stops for this paragraph.
  public let tabs: [TabStop]?

  /// Default tab stop interval if no explicit tabs are set.
  public let defaultTabInterval: Double?

  /// Paragraph border/rule.
  public let border: ParagraphBorder?

  /// Outline/heading level (nil for normal paragraphs).
  public let outlineLevel: UInt32?

  /// Whether to keep lines of this paragraph together on the same page.
  public let keepLinesTogether: Bool

  /// Whether to keep this paragraph with the next paragraph.
  public let keepWithNext: Bool

  /// Whether to start a new page before this paragraph.
  public let pageBreakBefore: Bool

  /// Whether to enable widow/orphan control.
  public let widowControl: Bool

  /// Writing direction for this paragraph.
  public let writingDirection: WritingDirection?

  /// List style information.
  public let listStyle: ListStyle

  /// List nesting level (0 = top level).
  public let listLevel: Int

  /// Item number at this level (for numbered lists).
  public var listItemNumber: Int?

  /// Creates a new paragraph style.
  ///
  /// - Parameters:
  ///   - alignment: Text alignment.
  ///   - leftIndent: Left indent in points.
  ///   - rightIndent: Right indent in points.
  ///   - firstLineIndent: First line indent in points.
  ///   - spaceBefore: Space before paragraph in points.
  ///   - spaceAfter: Space after paragraph in points.
  ///   - lineSpacing: Optional line spacing mode.
  ///   - tabs: Optional tab stops.
  ///   - defaultTabInterval: Optional default tab interval.
  ///   - border: Optional paragraph border.
  ///   - outlineLevel: Optional outline/heading level.
  ///   - keepLinesTogether: Whether to keep lines together.
  ///   - keepWithNext: Whether to keep with next paragraph.
  ///   - pageBreakBefore: Whether to break page before.
  ///   - widowControl: Whether to enable widow/orphan control.
  ///   - writingDirection: Optional writing direction.
  ///   - listStyle: List style.
  ///   - listLevel: List nesting level.
  ///   - listItemNumber: Optional item number for numbered lists.
  public init(
    alignment: TextAlignment = .left,
    leftIndent: Double = 0,
    rightIndent: Double = 0,
    firstLineIndent: Double = 0,
    spaceBefore: Double = 0,
    spaceAfter: Double = 0,
    lineSpacing: LineSpacingMode? = nil,
    tabs: [TabStop]? = nil,
    defaultTabInterval: Double? = nil,
    border: ParagraphBorder? = nil,
    outlineLevel: UInt32? = nil,
    keepLinesTogether: Bool = false,
    keepWithNext: Bool = false,
    pageBreakBefore: Bool = false,
    widowControl: Bool = true,
    writingDirection: WritingDirection? = nil,
    listStyle: ListStyle = .none,
    listLevel: Int = 0,
    listItemNumber: Int? = nil
  ) {
    self.alignment = alignment
    self.leftIndent = leftIndent
    self.rightIndent = rightIndent
    self.firstLineIndent = firstLineIndent
    self.spaceBefore = spaceBefore
    self.spaceAfter = spaceAfter
    self.lineSpacing = lineSpacing
    self.tabs = tabs
    self.defaultTabInterval = defaultTabInterval
    self.border = border
    self.outlineLevel = outlineLevel
    self.keepLinesTogether = keepLinesTogether
    self.keepWithNext = keepWithNext
    self.pageBreakBefore = pageBreakBefore
    self.widowControl = widowControl
    self.writingDirection = writingDirection
    self.listStyle = listStyle
    self.listLevel = listLevel
    self.listItemNumber = listItemNumber
  }
}

/// Text alignment options.
public enum TextAlignment: Sendable, Codable, Equatable {
  /// Left-aligned text.
  case left

  /// Center-aligned text.
  case center

  /// Right-aligned text.
  case right

  /// Justified text (aligned to both margins).
  case justified

  /// Natural alignment based on writing direction.
  case natural
}

/// RGB color representation.
public struct Color: Sendable, Codable, Equatable {
  /// Red component (0.0 to 1.0).
  public let red: Double

  /// Green component (0.0 to 1.0).
  public let green: Double

  /// Blue component (0.0 to 1.0).
  public let blue: Double

  /// Alpha/opacity component (0.0 to 1.0).
  public let alpha: Double

  /// Creates a new color.
  ///
  /// - Parameters:
  ///   - red: Red component (0.0 to 1.0).
  ///   - green: Green component (0.0 to 1.0).
  ///   - blue: Blue component (0.0 to 1.0).
  ///   - alpha: Alpha/opacity component (0.0 to 1.0).
  public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}

// MARK: - Hyperlink Types

/// A hyperlink within text.
public struct Hyperlink: Sendable, Codable, Equatable {
  /// The visible text of the hyperlink.
  public let text: String

  /// The URL target.
  public let url: String

  /// The range within the paragraph where this hyperlink appears.
  public let range: Range<Int>

  /// Creates a new hyperlink.
  ///
  /// - Parameters:
  ///   - text: The visible text.
  ///   - url: The URL target.
  ///   - range: The range within the paragraph.
  public init(text: String, url: String, range: Range<Int>) {
    self.text = text
    self.url = url
    self.range = range
  }
}

// MARK: - Table Types

/// Border style for cell borders.
public enum BorderStyle: Sendable, Codable, Equatable {
  /// Solid line.
  case solid

  /// Dashed line.
  case dashes

  /// Dotted line.
  case dots

  /// No border.
  case none
}

/// A single border edge with style, color, and width.
public struct Border: Sendable, Codable, Equatable {
  /// Border width in points.
  public let width: Double

  /// Border color.
  public let color: Color

  /// Border style.
  public let style: BorderStyle

  /// Creates a new border.
  ///
  /// - Parameters:
  ///   - width: Border width in points.
  ///   - color: Border color.
  ///   - style: Border style.
  public init(width: Double, color: Color, style: BorderStyle) {
    self.width = width
    self.color = color
    self.style = style
  }
}

/// Complete border information for a cell.
public struct CellBorder: Sendable, Codable, Equatable {
  /// Top border.
  public let top: Border?

  /// Right border.
  public let right: Border?

  /// Bottom border.
  public let bottom: Border?

  /// Left border.
  public let left: Border?

  /// Creates a new cell border.
  ///
  /// - Parameters:
  ///   - top: Optional top border.
  ///   - right: Optional right border.
  ///   - bottom: Optional bottom border.
  ///   - left: Optional left border.
  public init(top: Border? = nil, right: Border? = nil, bottom: Border? = nil, left: Border? = nil)
  {
    self.top = top
    self.right = right
    self.bottom = bottom
    self.left = left
  }

  /// Whether this cell has any borders defined.
  public var hasBorders: Bool {
    top != nil || right != nil || bottom != nil || left != nil
  }
}

/// Cell-level styling information (background, alignment, padding).
public struct CellStyle: Sendable, Codable, Equatable {
  /// Vertical alignment options.
  public enum VerticalAlignment: Sendable, Codable, Equatable {
    /// Top-aligned.
    case top

    /// Middle-aligned.
    case middle

    /// Bottom-aligned.
    case bottom
  }

  /// Cell padding.
  public struct CellPadding: Sendable, Codable, Equatable {
    /// Top padding in points.
    public let top: Double

    /// Right padding in points.
    public let right: Double

    /// Bottom padding in points.
    public let bottom: Double

    /// Left padding in points.
    public let left: Double

    /// Creates new cell padding.
    ///
    /// - Parameters:
    ///   - top: Top padding in points.
    ///   - right: Right padding in points.
    ///   - bottom: Bottom padding in points.
    ///   - left: Left padding in points.
    public init(top: Double = 2.0, right: Double = 2.0, bottom: Double = 2.0, left: Double = 2.0) {
      self.top = top
      self.right = right
      self.bottom = bottom
      self.left = left
    }
  }

  /// Background color.
  public let backgroundColor: Color?

  /// Background gradient colors.
  public let backgroundGradient: [Color]?

  /// Vertical alignment.
  public let verticalAlignment: VerticalAlignment

  /// Cell padding.
  public let padding: CellPadding

  /// Whether text wraps within the cell.
  public let textWrap: Bool

  /// Creates a new cell style.
  ///
  /// - Parameters:
  ///   - backgroundColor: Optional background color.
  ///   - backgroundGradient: Optional gradient colors.
  ///   - verticalAlignment: Vertical alignment.
  ///   - padding: Cell padding.
  ///   - textWrap: Whether text wraps.
  public init(
    backgroundColor: Color? = nil,
    backgroundGradient: [Color]? = nil,
    verticalAlignment: VerticalAlignment = .top,
    padding: CellPadding = CellPadding(),
    textWrap: Bool = true
  ) {
    self.backgroundColor = backgroundColor
    self.backgroundGradient = backgroundGradient
    self.verticalAlignment = verticalAlignment
    self.padding = padding
    self.textWrap = textWrap
  }
}

// MARK: - Currency Types

/// Currency formatting information for cells.
public struct CurrencyFormat: Sendable, Codable, Equatable {
  /// The ISO 4217 currency code (e.g., "USD", "EUR", "JPY").
  ///
  /// Must be one of the recognized currency codes defined in `IWorkConstants.currencies`.
  public let code: String

  /// The number of decimal places to display.
  ///
  /// Use `IWorkConstants.decimalPlacesAuto` (253) for automatic decimal places.
  public let decimalPlaces: UInt8

  /// Whether to show the currency symbol.
  public let showSymbol: Bool

  /// Whether to use accounting-style formatting (e.g., parentheses for negatives).
  public let useAccountingStyle: Bool

  /// Creates a new currency format.
  ///
  /// - Parameters:
  ///   - code: The ISO 4217 currency code. Must be valid according to `IWorkConstants.isValidCurrency()`.
  ///   - decimalPlaces: Number of decimal places (use 253 for automatic).
  ///   - showSymbol: Whether to show the currency symbol.
  ///   - useAccountingStyle: Whether to use accounting-style formatting.
  public init(
    code: String,
    decimalPlaces: UInt8 = 2,
    showSymbol: Bool = true,
    useAccountingStyle: Bool = false
  ) {
    self.code = code
    self.decimalPlaces = decimalPlaces
    self.showSymbol = showSymbol
    self.useAccountingStyle = useAccountingStyle
  }

  /// Whether this currency format uses automatic decimal places.
  public var usesAutomaticDecimalPlaces: Bool {
    decimalPlaces == IWorkConstants.decimalPlacesAuto
  }

  /// The display symbol for this currency.
  ///
  /// Returns the localized currency symbol if available, otherwise the currency code.
  public var displaySymbol: String {
    IWorkConstants.symbol(forCurrency: code)
  }

  /// Whether the currency code is valid.
  public var isValidCurrency: Bool {
    IWorkConstants.isValidCurrency(code)
  }
}

// MARK: - Chart Types

/// The type of chart visualization.
public enum ChartType: Sendable, Codable, Equatable {
  /// 2D bar chart with horizontal bars.
  case bar2D

  /// 3D bar chart with horizontal bars.
  case bar3D

  /// 2D column chart with vertical bars.
  case column2D

  /// 3D column chart with vertical bars.
  case column3D

  /// 2D line chart.
  case line2D

  /// 3D line chart.
  case line3D

  /// 2D area chart.
  case area2D

  /// 3D area chart.
  case area3D

  /// 2D pie chart.
  case pie2D

  /// 3D pie chart.
  case pie3D

  /// 2D scatter plot.
  case scatter2D

  /// 2D bubble chart (scatter with sized bubbles).
  case bubble2D

  /// Mixed chart combining multiple series types.
  case mixed2D

  /// Donut chart (pie with center removed).
  case donut2D

  /// Unknown or unsupported chart type.
  case unknown(Int)
}

/// Direction for reading chart data (by row or by column).
public enum ChartDataDirection: Sendable, Codable, Equatable {
  /// Data is organized in rows (series in rows, categories in columns).
  case byRow

  /// Data is organized in columns (series in columns, categories in rows).
  case byColumn
}

public enum ChartGridValue: Sendable, Codable, Equatable {
  case number(Double)
  case date(Double)
  case duration(Double)
  case empty

  /// Returns the numeric value if this is a number, nil otherwise.
  public var numericValue: Double? {
    switch self {
    case .number(let value), .date(let value), .duration(let value):
      return value
    case .empty:
      return nil
    }
  }
}

/// A single row of values in a chart's data grid.
public struct ChartGridRow: Sendable, Codable, Equatable {
  /// The values in this row.
  public let values: [ChartGridValue]

  /// Creates a new chart grid row.
  ///
  /// - Parameter values: The values in this row.
  public init(values: [ChartGridValue]) {
    self.values = values
  }
}

/// The data grid backing a chart, containing all data points.
public struct ChartGridData: Sendable, Codable, Equatable {
  /// Direction indicating how to interpret the data (by row or by column).
  public let direction: ChartDataDirection

  /// Labels for rows (typically series names or category names depending on direction).
  public let rowNames: [String]

  /// Labels for columns (typically category names or series names depending on direction).
  public let columnNames: [String]

  /// The data values organized as rows.
  public let rows: [ChartGridRow]

  /// Creates a new chart grid data instance.
  ///
  /// - Parameters:
  ///   - direction: Direction for interpreting the data.
  ///   - rowNames: Labels for each row.
  ///   - columnNames: Labels for each column.
  ///   - rows: The data values organized as rows.
  public init(
    direction: ChartDataDirection,
    rowNames: [String],
    columnNames: [String],
    rows: [ChartGridRow]
  ) {
    self.direction = direction
    self.rowNames = rowNames
    self.columnNames = columnNames
    self.rows = rows
  }

  /// Number of rows in the grid.
  public var rowCount: Int {
    rows.count
  }

  /// Number of columns in the grid.
  public var columnCount: Int {
    rows.first?.values.count ?? 0
  }
}

/// Scale type for chart axes.
public enum ChartAxisScale: Sendable, Codable, Equatable {
  /// Linear scale.
  case linear

  /// Logarithmic scale.
  case logarithmic

  /// Unknown scale type.
  case unknown(Int)
}

/// Position for value labels on chart series.
public enum ChartValueLabelPosition: Sendable, Codable, Equatable {
  /// Labels positioned automatically.
  case automatic

  /// Labels positioned at the center of data points/bars.
  case center

  /// Labels positioned inside at the top/right.
  case insideEnd

  /// Labels positioned inside at the bottom/left.
  case insideBase

  /// Labels positioned outside above/right of data points.
  case outside

  /// Labels positioned at the end outside.
  case outsideEnd

  /// Unknown position.
  case unknown(Int)
}

/// Axis information for a chart.
public struct ChartAxisInfo: Sendable, Codable, Equatable {
  /// The axis title, if present.
  public let title: String?

  /// Whether the axis is visible.
  public let isVisible: Bool

  /// Whether axis labels are shown.
  public let showLabels: Bool

  /// Whether major gridlines are shown.
  public let showMajorGridlines: Bool

  /// Whether minor gridlines are shown.
  public let showMinorGridlines: Bool

  /// Number format for axis values.
  public let numberFormat: ChartNumberFormat?

  /// Minimum value on the axis (if set manually).
  public let minimumValue: Double?

  /// Maximum value on the axis (if set manually).
  public let maximumValue: Double?

  /// Scale type for this axis.
  public let scale: ChartAxisScale

  /// Creates a new chart axis info instance.
  ///
  /// - Parameters:
  ///   - title: Optional axis title.
  ///   - isVisible: Whether the axis is visible.
  ///   - showLabels: Whether labels are shown.
  ///   - showMajorGridlines: Whether major gridlines are shown.
  ///   - showMinorGridlines: Whether minor gridlines are shown.
  ///   - numberFormat: Optional number format for values.
  ///   - minimumValue: Optional minimum value.
  ///   - maximumValue: Optional maximum value.
  ///   - scale: Scale type for the axis.
  public init(
    title: String? = nil,
    isVisible: Bool = true,
    showLabels: Bool = true,
    showMajorGridlines: Bool = false,
    showMinorGridlines: Bool = false,
    numberFormat: ChartNumberFormat? = nil,
    minimumValue: Double? = nil,
    maximumValue: Double? = nil,
    scale: ChartAxisScale = .linear
  ) {
    self.title = title
    self.isVisible = isVisible
    self.showLabels = showLabels
    self.showMajorGridlines = showMajorGridlines
    self.showMinorGridlines = showMinorGridlines
    self.numberFormat = numberFormat
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
    self.scale = scale
  }
}

/// Number format type for charts.
public enum ChartNumberFormatType: Sendable, Codable, Equatable {
  /// Decimal format.
  case decimal
  /// Currency format.
  case currency
  /// Percentage format.
  case percentage
  /// Scientific notation format.
  case scientific
  /// Fraction format.
  case fraction
  /// Base format (binary, octal, hex, etc.).
  case base
  /// Date/time format.
  case dateTime
  /// Duration format.
  case duration
  /// Custom format string.
  case custom
  /// Unknown format.
  case unknown(Int)
}

/// Number formatting configuration for chart values.
public struct ChartNumberFormat: Sendable, Codable, Equatable {
  /// The type of number format.
  public let type: ChartNumberFormatType

  /// Number of decimal places to display.
  public let decimalPlaces: UInt32

  /// Whether to show thousands separator.
  public let showThousandsSeparator: Bool

  /// Currency code for currency format (e.g., "USD", "EUR").
  public let currencyCode: String?

  /// Custom format string, if using custom format.
  ///
  /// Can represent:
  /// - Prefix/suffix patterns (e.g., "$#%" for currency with percentage)
  /// - Date/time format patterns
  /// - Custom number format patterns
  public let formatString: String?

  /// Base for base format (2 for binary, 8 for octal, 16 for hex, etc.).
  public let base: UInt32?

  /// Fraction accuracy for fraction format.
  public let fractionAccuracy: UInt32?

  /// Creates a new chart number format.
  ///
  /// - Parameters:
  ///   - type: The type of format.
  ///   - decimalPlaces: Number of decimal places.
  ///   - showThousandsSeparator: Whether to show thousands separator.
  ///   - currencyCode: Optional currency code.
  ///   - formatString: Optional custom format string.
  ///   - base: Optional base for base format.
  ///   - fractionAccuracy: Optional fraction accuracy for fraction format.
  public init(
    type: ChartNumberFormatType,
    decimalPlaces: UInt32 = 2,
    showThousandsSeparator: Bool = false,
    currencyCode: String? = nil,
    formatString: String? = nil,
    base: UInt32? = nil,
    fractionAccuracy: UInt32? = nil
  ) {
    self.type = type
    self.decimalPlaces = decimalPlaces
    self.showThousandsSeparator = showThousandsSeparator
    self.currencyCode = currencyCode
    self.formatString = formatString
    self.base = base
    self.fractionAccuracy = fractionAccuracy
  }
}

/// Configuration for a data series in a chart.
public struct ChartSeriesInfo: Sendable, Codable, Equatable {
  /// The series type (may differ from overall chart type in mixed charts).
  public let seriesType: ChartType

  /// Fill color/gradient for this series.
  public let fill: ShapeFill

  /// Stroke/border for this series elements.
  public let stroke: Border?

  /// Whether value labels are shown for this series.
  public let showValueLabels: Bool

  /// Position of value labels.
  public let valueLabelPosition: ChartValueLabelPosition

  /// Number format for values in this series.
  public let numberFormat: ChartNumberFormat?

  /// Creates a new chart series info instance.
  ///
  /// - Parameters:
  ///   - seriesType: The series type.
  ///   - fill: Fill color/gradient.
  ///   - stroke: Optional stroke.
  ///   - showValueLabels: Whether to show value labels.
  ///   - valueLabelPosition: Position for value labels.
  ///   - numberFormat: Optional number format.
  public init(
    seriesType: ChartType,
    fill: ShapeFill = .none,
    stroke: Border? = nil,
    showValueLabels: Bool = false,
    valueLabelPosition: ChartValueLabelPosition = .automatic,
    numberFormat: ChartNumberFormat? = nil
  ) {
    self.seriesType = seriesType
    self.fill = fill
    self.stroke = stroke
    self.showValueLabels = showValueLabels
    self.valueLabelPosition = valueLabelPosition
    self.numberFormat = numberFormat
  }
}

/// Legend configuration for a chart.
public struct ChartLegendInfo: Sendable, Codable, Equatable {
  /// Whether the legend is visible.
  public let isVisible: Bool

  /// Background fill for the legend.
  public let fill: ShapeFill

  /// Border stroke for the legend.
  public let stroke: Border?

  /// Spatial information for the legend position.
  public let spatialInfo: SpatialInfo?

  /// Creates a new chart legend info instance.
  ///
  /// - Parameters:
  ///   - isVisible: Whether the legend is visible.
  ///   - fill: Background fill.
  ///   - stroke: Optional border stroke.
  ///   - spatialInfo: Optional spatial positioning.
  public init(
    isVisible: Bool = true,
    fill: ShapeFill = .none,
    stroke: Border? = nil,
    spatialInfo: SpatialInfo? = nil
  ) {
    self.isVisible = isVisible
    self.fill = fill
    self.stroke = stroke
    self.spatialInfo = spatialInfo
  }
}

/// Complete information about a chart element.
public struct ChartInfo: Sendable, Codable, Equatable {
  /// The type of chart.
  public let chartType: ChartType

  /// The data grid containing all chart values.
  public let gridData: ChartGridData

  /// The chart title, if present.
  public var title: CaptionData?

  /// The chart caption, if present.
  public var caption: CaptionData?

  /// Whether the chart title is shown.
  public let showTitle: Bool

  /// Configuration for the value (Y) axis.
  public let valueAxis: ChartAxisInfo

  /// Configuration for the category (X) axis.
  public let categoryAxis: ChartAxisInfo

  /// Configuration for each data series.
  public let series: [ChartSeriesInfo]

  /// Legend configuration.
  public let legend: ChartLegendInfo

  /// Background fill for the entire chart area.
  public let backgroundFill: ShapeFill

  /// Background fill for the plot area (where data is drawn).
  public let plotAreaFill: ShapeFill

  /// Creates a new chart info instance.
  ///
  /// - Parameters:
  ///   - chartType: The type of chart.
  ///   - gridData: The data grid.
  ///   - title: Optional chart title.
  ///   - showTitle: Whether to show the title.
  ///   - valueAxis: Value axis configuration.
  ///   - categoryAxis: Category axis configuration.
  ///   - series: Series configurations.
  ///   - legend: Legend configuration.
  ///   - backgroundFill: Background fill for chart area.
  ///   - plotAreaFill: Background fill for plot area.
  public init(
    chartType: ChartType,
    gridData: ChartGridData,
    title: CaptionData?,
    caption: CaptionData? = nil,
    showTitle: Bool = false,
    valueAxis: ChartAxisInfo = ChartAxisInfo(),
    categoryAxis: ChartAxisInfo = ChartAxisInfo(),
    series: [ChartSeriesInfo] = [],
    legend: ChartLegendInfo = ChartLegendInfo(),
    backgroundFill: ShapeFill = .none,
    plotAreaFill: ShapeFill = .none
  ) {
    self.chartType = chartType
    self.gridData = gridData
    self.title = title
    self.showTitle = showTitle
    self.valueAxis = valueAxis
    self.categoryAxis = categoryAxis
    self.series = series
    self.legend = legend
    self.backgroundFill = backgroundFill
    self.plotAreaFill = plotAreaFill
  }
}

// MARK: - Complete Cell Storage Metadata

/// Complete storage metadata for a table cell.
public struct CellStorageMetadata: Sendable, Codable, Equatable {
  /// Cell type identifier (matches `CellType` enum values from `IWorkConstants`).
  public let cellType: UInt8

  /// Storage format version.
  public let version: UInt8

  /// Raw flags bitfield (see `CellStorageFlags` in `IWorkConstants`).
  public let flags: UInt32

  /// Extras bitfield (bytes 6-7).
  public let extras: UInt16

  /// Decimal128 value (unpacked using `IWorkConstants.decimal128Bias`).
  public let decimal128: Double?

  /// Double-precision floating point value.
  public let double: Double?

  /// Seconds value (for durations, dates).
  ///
  /// For date values, convert using `IWorkConstants.date(fromAppleTimestamp:)`.
  public let seconds: Double?

  /// String ID reference.
  public let stringId: UInt32?

  /// Rich text ID reference.
  public let richTextId: UInt32?

  /// Cell style ID reference.
  public let cellStyleId: UInt32?

  /// Text style ID reference.
  public let textStyleId: UInt32?

  /// Formula ID reference.
  public let formulaId: UInt32?

  /// Control ID reference.
  public let controlId: UInt32?

  /// Suggestion ID reference.
  public let suggestId: UInt32?

  /// Number format ID reference.
  public let numFormatId: UInt32?

  /// Currency format ID reference.
  public let currencyFormatId: UInt32?

  /// Date format ID reference.
  public let dateFormatId: UInt32?

  /// Duration format ID reference.
  public let durationFormatId: UInt32?

  /// Text format ID reference.
  public let textFormatId: UInt32?

  /// Boolean format ID reference.
  public let boolFormatId: UInt32?

  /// Border information.
  public let border: CellBorder?

  /// Cell style information.
  public let cellStyle: CellStyle?

  /// Text style information.
  public let textStyle: CharacterStyle?

  /// Currency format information (if this is a currency cell).
  public let currencyFormat: CurrencyFormat?

  /// Creates new cell storage metadata.
  ///
  /// - Parameters:
  ///   - cellType: Cell type identifier.
  ///   - version: Storage format version.
  ///   - flags: Raw flags bitfield.
  ///   - extras: Extras bitfield.
  ///   - decimal128: Optional decimal128 value.
  ///   - double: Optional double value.
  ///   - seconds: Optional seconds value.
  ///   - stringId: Optional string ID.
  ///   - richTextId: Optional rich text ID.
  ///   - cellStyleId: Optional cell style ID.
  ///   - textStyleId: Optional text style ID.
  ///   - formulaId: Optional formula ID.
  ///   - controlId: Optional control ID.
  ///   - suggestId: Optional suggestion ID.
  ///   - numFormatId: Optional number format ID.
  ///   - currencyFormatId: Optional currency format ID.
  ///   - dateFormatId: Optional date format ID.
  ///   - durationFormatId: Optional duration format ID.
  ///   - textFormatId: Optional text format ID.
  ///   - boolFormatId: Optional boolean format ID.
  ///   - border: Optional cell border.
  ///   - cellStyle: Optional cell style.
  ///   - textStyle: Optional text style.
  ///   - currencyFormat: Optional currency format.
  public init(
    cellType: UInt8,
    version: UInt8,
    flags: UInt32,
    extras: UInt16,
    decimal128: Double?,
    double: Double?,
    seconds: Double?,
    stringId: UInt32?,
    richTextId: UInt32?,
    cellStyleId: UInt32?,
    textStyleId: UInt32?,
    formulaId: UInt32?,
    controlId: UInt32?,
    suggestId: UInt32?,
    numFormatId: UInt32?,
    currencyFormatId: UInt32?,
    dateFormatId: UInt32?,
    durationFormatId: UInt32?,
    textFormatId: UInt32?,
    boolFormatId: UInt32?,
    border: CellBorder?,
    cellStyle: CellStyle?,
    textStyle: CharacterStyle?,
    currencyFormat: CurrencyFormat? = nil
  ) {
    self.cellType = cellType
    self.version = version
    self.flags = flags
    self.extras = extras
    self.decimal128 = decimal128
    self.double = double
    self.seconds = seconds
    self.stringId = stringId
    self.richTextId = richTextId
    self.cellStyleId = cellStyleId
    self.textStyleId = textStyleId
    self.formulaId = formulaId
    self.controlId = controlId
    self.suggestId = suggestId
    self.numFormatId = numFormatId
    self.currencyFormatId = currencyFormatId
    self.dateFormatId = dateFormatId
    self.durationFormatId = durationFormatId
    self.textFormatId = textFormatId
    self.boolFormatId = boolFormatId
    self.border = border
    self.cellStyle = cellStyle
    self.textStyle = textStyle
    self.currencyFormat = currencyFormat
  }

  /// Whether this cell contains a formula.
  public var hasFormula: Bool {
    formulaId != nil
  }

  /// Whether this cell has custom number formatting.
  public var hasCustomFormatting: Bool {
    numFormatId != nil || currencyFormatId != nil || dateFormatId != nil || durationFormatId != nil
      || textFormatId != nil || boolFormatId != nil
  }

  /// Whether this cell has interactive controls (checkbox, slider, etc.).
  public var hasControl: Bool {
    controlId != nil
  }

  /// Whether this cell has borders.
  public var hasBorders: Bool {
    border?.hasBorders ?? false
  }

  /// Whether this is a currency cell (cellType matches `IWorkConstants.currencyCellType`).
  public var isCurrencyCell: Bool {
    cellType == IWorkConstants.currencyCellType
  }

  /// Converts the seconds value to a Date using Apple's epoch.
  ///
  /// - Returns: The date value, or nil if seconds is not set.
  public var dateValue: Date? {
    guard let seconds = seconds else { return nil }
    return IWorkConstants.date(fromAppleTimestamp: seconds)
  }

  /// Converts the seconds value to a duration in various units.
  ///
  /// - Parameter unit: The time unit to convert to (hours, days, weeks).
  /// - Returns: The duration in the specified unit, or nil if seconds is not set.
  public func duration(in unit: DurationUnit) -> Double? {
    guard let seconds = seconds else { return nil }
    switch unit {
    case .seconds: return seconds
    case .hours: return seconds / IWorkConstants.secondsInHour
    case .days: return seconds / IWorkConstants.secondsInDay
    case .weeks: return seconds / IWorkConstants.secondsInWeek
    }
  }

  /// Time units for duration conversion.
  public enum DurationUnit {
    case seconds, hours, days, weeks
  }
}

/// Represents the content and type of a table cell.
public enum TableCellContent: Sendable, Codable, Equatable {
  /// Empty cell.
  case empty

  /// Numeric value with optional metadata.
  case number(Double, metadata: CellStorageMetadata? = nil)

  /// Date value with optional metadata.
  ///
  /// For raw timestamp values, convert using `IWorkConstants.date(fromAppleTimestamp:)`.
  case date(Date, metadata: CellStorageMetadata? = nil)

  /// Boolean value with optional metadata.
  case boolean(Bool, metadata: CellStorageMetadata? = nil)

  /// Plain text string with optional metadata.
  case text(String, metadata: CellStorageMetadata? = nil)

  /// Rich text with formatting (paragraphs will be visited separately).
  case richText([InlineElement], metadata: CellStorageMetadata? = nil)

  /// Duration value in seconds with optional metadata.
  ///
  /// Convert to hours/days/weeks using `IWorkConstants.secondsInHour`, etc.
  case duration(Double, metadata: CellStorageMetadata? = nil)

  /// Currency value with amount and format information.
  case currency(Double, format: CurrencyFormat, metadata: CellStorageMetadata? = nil)

  /// Formula error (#ERROR!, #DIV/0!, etc.)
  case formulaError(metadata: CellStorageMetadata? = nil)

  /// Get the storage metadata if available.
  public var metadata: CellStorageMetadata? {
    switch self {
    case .empty:
      return nil
    case .number(_, let metadata):
      return metadata
    case .date(_, let metadata):
      return metadata
    case .boolean(_, let metadata):
      return metadata
    case .text(_, let metadata):
      return metadata
    case .richText(_, let metadata):
      return metadata
    case .duration(_, let metadata):
      return metadata
    case .currency(_, _, let metadata):
      return metadata
    case .formulaError(let metadata):
      return metadata
    }
  }

  /// Whether this cell contains a formula.
  public var hasFormula: Bool {
    metadata?.hasFormula ?? false
  }

  /// Whether this cell has custom formatting.
  public var hasCustomFormatting: Bool {
    metadata?.hasCustomFormatting ?? false
  }

  /// Whether this cell has interactive controls.
  public var hasControl: Bool {
    metadata?.hasControl ?? false
  }

  /// Whether this cell has borders.
  public var hasBorders: Bool {
    metadata?.hasBorders ?? false
  }

  /// Get the cell borders if available.
  public var borders: CellBorder? {
    metadata?.border
  }

  /// Get the cell style if available.
  public var cellStyle: CellStyle? {
    metadata?.cellStyle
  }

  /// Get the text style if available.
  public var textStyle: CharacterStyle? {
    metadata?.textStyle
  }

  /// Whether this is a currency cell.
  public var isCurrency: Bool {
    if case .currency = self { return true }
    return metadata?.isCurrencyCell ?? false
  }
}

// MARK: - 3D Object Types

/// 3D orientation using Euler angles.
public struct Pose3D: Sendable, Codable, Equatable {
  /// Rotation around the vertical axis (left/right rotation) in radians.
  public let yaw: Float

  /// Rotation around the horizontal axis (up/down tilt) in radians.
  public let pitch: Float

  /// Rotation around the depth axis (barrel roll) in radians.
  public let roll: Float

  /// Creates a new 3D pose.
  ///
  /// - Parameters:
  ///   - yaw: Rotation around vertical axis in radians.
  ///   - pitch: Rotation around horizontal axis in radians.
  ///   - roll: Rotation around depth axis in radians.
  public init(yaw: Float, pitch: Float, roll: Float) {
    self.yaw = yaw
    self.pitch = pitch
    self.roll = roll
  }

  /// Identity pose (no rotation).
  public static let identity = Pose3D(yaw: 0, pitch: 0, roll: 0)
}

/// Information about a 3D object element in a document.
public struct Object3DInfo: Sendable, Codable, Equatable {
  /// Original filename of the 3D model, if available.
  public let filename: String?

  /// File path within the document archive.
  public let filepath: String

  /// 3D orientation of the object.
  public let pose: Pose3D

  /// 2D bounding rectangle for the object's projection (normalized coordinates 0.0 to 1.0).
  public let boundingRect: CGRect

  /// Whether animations embedded in the 3D model should automatically play.
  public let playsAnimations: Bool

  /// Whether the 3D model file contains built-in animations.
  public let hasEmbeddedAnimations: Bool

  /// Optional thumbnail/preview image of the 3D object.
  public let thumbnailImage: ImageInfo?

  /// 2D outline path for text wrapping around the 3D object.
  public let tracedPath: BezierPath?

  /// Caption title metadata.
  public let title: CaptionData?

  /// Caption text metadata.
  public let caption: CaptionData?

  /// Optional hyperlink if the 3D object is clickable.
  public let hyperlink: Hyperlink?

  /// Creates a new 3D object info instance.
  ///
  /// - Parameters:
  ///   - filename: Optional original filename.
  ///   - filepath: File path within document.
  ///   - pose: 3D orientation.
  ///   - boundingRect: 2D bounding rectangle (normalized coordinates).
  ///   - playsAnimations: Whether to play animations.
  ///   - hasEmbeddedAnimations: Whether model has animations.
  ///   - thumbnailImage: Optional thumbnail image.
  ///   - tracedPath: Optional outline path for text wrapping.
  ///   - title: Optional title caption.
  ///   - caption: Optional caption text.
  ///   - hyperlink: Optional hyperlink.
  public init(
    filename: String?,
    filepath: String,
    pose: Pose3D,
    boundingRect: CGRect,
    playsAnimations: Bool = false,
    hasEmbeddedAnimations: Bool = false,
    thumbnailImage: ImageInfo? = nil,
    tracedPath: BezierPath? = nil,
    title: CaptionData? = nil,
    caption: CaptionData? = nil,
    hyperlink: Hyperlink? = nil
  ) {
    self.filename = filename
    self.filepath = filepath
    self.pose = pose
    self.boundingRect = boundingRect
    self.playsAnimations = playsAnimations
    self.hasEmbeddedAnimations = hasEmbeddedAnimations
    self.thumbnailImage = thumbnailImage
    self.tracedPath = tracedPath
    self.title = title
    self.caption = caption
    self.hyperlink = hyperlink
  }

  /// The origin of the bounding rectangle.
  public var boundingOrigin: CGPoint {
    boundingRect.origin
  }

  /// The size of the bounding rectangle.
  public var boundingSize: CGSize {
    boundingRect.size
  }
}

// MARK: - Document Visitor Protocol

/// Visitor for traversing and processing iWork document content.
///
/// Implement this protocol to extract, render, or transform iWork documents.
/// The visitor pattern allows reactive processing as the document structure
/// is traversed, rather than requiring manual navigation of the record tree.
///
/// Methods are called in document order. Inline elements (text, images, shapes,
/// tables, footnotes) within paragraphs are visited via `visitInlineElement` in
/// their exact sequential order. Floating elements use dedicated visit methods.
///
/// All positioned elements include complete spatial information, allowing
/// visitors to recreate the exact layout of the original document.
///
/// ## Example
///
/// ```swift
/// struct MyVisitor: IWorkDocumentVisitor {
///   func willVisitDocument(type: IWorkDocument.DocumentType, layout: DocumentLayout?, pageSettings: PageSettings?) async {
///     print("Starting document: \(type)")
///   }
///
///   func visitInlineElement(_ element: InlineElement) async {
///     switch element {
///     case .text(let text, let style, let hyperlink):
///       print("Text: \(text)")
///     case .shape(let info, let spatialInfo):
///       print("Inline shape at \(spatialInfo.frame)")
///     case .image(let data, let info, _, _, _):
///       print("Inline image: \(info.filename ?? "unknown")")
///     case .footnoteMarker(let footnote):
///       print("Footnote #\(footnote.number)")
///     case .table(let name, let rowCount, let columnCount, _):
///       print("Inline table: \(name ?? "untitled") (\(rowCount)×\(columnCount))")
///     case .media(_, let info, _):
///       print("Inline media: \(info.type)")
///     }
///   }
/// }
/// ```
public protocol IWorkDocumentVisitor: Sendable {

  associatedtype OCR: OCRProvider = NullOCRProvider

  // MARK: - Document-Level

  init(using document: IWorkDocument, with ocrProvider: OCR?)

  func accept() async throws

  /// Called before processing begins.
  ///
  /// - Parameters:
  ///   - type: The type of iWork document (Pages, Numbers, or Keynote).
  ///   - layout: Document layout information (margins, page size, etc.).
  ///   - pageSettings: Page settings such as footnote format and creation locale.
  func willVisitDocument(
    type: IWorkDocument.DocumentType,
    layout: DocumentLayout?,
    pageSettings: PageSettings?
  ) async

  /// Called after all processing is complete.
  ///
  /// - Parameter type: The type of iWork document.
  func didVisitDocument(type: IWorkDocument.DocumentType) async

  // MARK: - Pages-Specific

  /// Called before visiting the main body storage in a Pages document.
  ///
  /// The body contains the primary text flow and inline elements. Floating
  /// elements (shapes, images) positioned outside the text flow are visited
  /// separately after the body.
  ///
  /// - Parameter contentRect: The content area within page margins.
  func willVisitPagesBody(contentRect: CGRect) async

  /// Called after visiting the main body storage in a Pages document.
  func didVisitPagesBody() async

  // MARK: - Numbers-Specific

  /// Called before visiting a sheet in a Numbers document.
  ///
  /// Each sheet contains tables and other drawable elements.
  ///
  /// - Parameters:
  ///   - name: The name of the sheet.
  ///   - layout: Sheet layout information (page size, margins, orientation).
  func willVisitSheet(name: String, layout: SheetLayout?) async

  /// Called after visiting a sheet in a Numbers document.
  ///
  /// - Parameter name: The name of the sheet.
  func didVisitSheet(name: String) async

  // MARK: - Keynote-Specific

  /// Called before visiting a slide in a Keynote presentation.
  ///
  /// Master slide elements are visited before the slide's own elements,
  /// establishing the background and template.
  ///
  /// - Parameters:
  ///   - index: The zero-based index of the slide.
  ///   - bounds: The bounds of the slide canvas.
  func willVisitSlide(index: Int, bounds: CGRect?) async

  /// Called after visiting a slide in a Keynote presentation.
  ///
  /// - Parameter index: The zero-based index of the slide.
  func didVisitSlide(index: Int) async

  // MARK: - Paragraphs and Inline Content

  /// Called before visiting a paragraph.
  ///
  /// All inline content (text, images, shapes, tables, media, footnotes) within
  /// this paragraph will be visited via `visitInlineElement` in their exact
  /// document order between this call and `didVisitParagraph`.
  ///
  /// - Parameters:
  ///   - style: The paragraph's styling information (alignment, spacing, lists, etc.).
  ///   - spatialInfo: Position information if paragraph is in a positioned container (e.g., text box).
  func willVisitParagraph(style: ParagraphStyle, spatialInfo: SpatialInfo?) async

  /// Called before visiting a list.
  ///
  /// A list is a sequence of consecutive paragraphs with the same list style.
  /// List items (including their inline content) will be visited between
  /// `willVisitList` and `didVisitList`.
  ///
  /// - Parameter style: The list style (bullet or numbered).
  func willVisitList(style: ListStyle) async

  /// Called before visiting a list item and its content.
  ///
  /// This is called INSTEAD of `willVisitParagraph` for paragraphs that are
  /// part of a list. The inline content is still visited via `visitInlineElement`.
  ///
  /// - Parameters:
  ///   - number: The item number (for numbered lists) or nil (for bullets).
  ///   - level: Nesting level (0 = top level, 1 = first indent, etc.).
  ///   - style: The paragraph style for this list item.
  ///   - spatialInfo: Position information if list is in a positioned container.
  func willVisitListItem(
    number: Int?,
    level: Int,
    style: ParagraphStyle,
    spatialInfo: SpatialInfo?
  ) async

  /// Called for each inline element within a paragraph, in document order.
  ///
  /// This method is called for every element that appears inline in the text flow:
  /// - `.text`: Text runs with character styling and optional hyperlinks
  /// - `.footnoteMarker`: Footnote reference markers
  /// - `.shape`: Inline shapes (including text boxes)
  /// - `.image`: Inline images
  /// - `.table`: Inline tables
  /// - `.media`: Inline media (video, audio, GIF)
  ///
  /// Elements appear in the exact order they occur in the document, preserving
  /// the visual flow. For example, if text wraps around an inline shape, you'll
  /// receive: text before → shape → text after.
  ///
  /// - Parameter element: The inline element to process.
  func visitInlineElement(_ element: InlineElement) async

  /// Called after visiting a paragraph and all its inline content.
  func didVisitParagraph() async

  /// Called after visiting a list item and all its inline content.
  func didVisitListItem() async

  /// Called after visiting all items in a list.
  func didVisitList() async

  // MARK: - Floating Tables

  /// Called before visiting a floating table (positioned outside text flow).
  ///
  /// For inline tables within paragraphs, use `visitInlineElement(.table(...))`
  /// instead. This method is only called for tables with absolute positioning.
  ///
  /// Rows and cells are visited between `willVisitTable` and `didVisitTable`
  /// using `willVisitTableRow`, `visitTableCell`, and `didVisitTableRow`.
  ///
  /// - Parameters:
  ///   - name: The table's name, if available.
  ///   - rowCount: Number of rows in the table (max: `IWorkConstants.maxRowCount`).
  ///   - columnCount: Number of columns in the table (max: `IWorkConstants.maxColCount`).
  ///   - spatialInfo: Complete spatial information for the table (position, rotation, z-order).
  func willVisitTable(
    name: String?,
    rowCount: UInt32,
    columnCount: UInt32,
    spatialInfo: SpatialInfo
  ) async

  /// Called before visiting a table row.
  ///
  /// All cells in this row will be visited via `visitTableCell` before
  /// `didVisitTableRow` is called.
  ///
  /// - Parameter index: The zero-based row index.
  func willVisitTableRow(index: Int) async

  /// Called for each cell in a table row.
  ///
  /// Cells are visited in column order (0, 1, 2, ...). For rich text cells
  /// (`.richText`), paragraphs will be visited separately using the standard
  /// paragraph/inline element callbacks.
  ///
  /// Currency cells include format information with validated currency codes
  /// from `IWorkConstants.currencies`.
  ///
  /// - Parameters:
  ///   - row: The cell's zero-based row index.
  ///   - column: The cell's zero-based column index.
  ///   - content: The cell's content type and value (text, number, date, currency, etc.).
  func visitTableCell(row: Int, column: Int, content: TableCellContent) async

  /// Called after visiting a table row and all its cells.
  ///
  /// - Parameter index: The zero-based row index.
  func didVisitTableRow(index: Int) async

  /// Called after visiting a floating table, all its rows, and all its cells.
  func didVisitTable() async

  // MARK: - Floating Images

  /// Called when visiting a floating image (positioned outside text flow).
  ///
  /// For inline images within paragraphs, use `visitInlineElement(.image(...))`
  /// instead. This method is only called for images with absolute positioning.
  ///
  /// - Parameters:
  ///   - info: Image metadata (dimensions, filename, captions, description).
  ///   - spatialInfo: Complete spatial information for the image (position, rotation, z-order).
  ///   - ocrResult: OCR text recognition result, if an OCR provider was configured.
  ///   - hyperlink: Optional hyperlink if the image is clickable.
  func visitImage(
    info: ImageInfo,
    spatialInfo: SpatialInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?
  ) async

  // MARK: - Floating Media

  /// Called when visiting floating media (positioned outside text flow).
  ///
  /// For inline media within paragraphs, use `visitInlineElement(.media(...))`
  /// instead. This method is only called for media with absolute positioning.
  ///
  /// - Parameters:
  ///   - info: Media metadata (type, dimensions, duration, volume, captions).
  ///   - spatialInfo: Complete spatial information for the media (position, rotation, z-order).
  func visitMedia(
    info: MediaInfo,
    spatialInfo: SpatialInfo
  ) async

  // MARK: - Floating Shapes

  /// Called before visiting a floating shape (positioned outside text flow).
  ///
  /// For inline shapes within paragraphs, use `visitInlineElement(.shape(...))`
  /// instead. This method is only called for shapes with absolute positioning.
  ///
  /// Text content within the shape (if any) will be visited between
  /// `willVisitShape` and `didVisitShape` using the standard paragraph
  /// and inline element callbacks.
  ///
  /// - Parameters:
  ///   - info: Shape information (path geometry, style, fill, stroke, captions).
  ///   - spatialInfo: Complete spatial information for the shape (position, rotation, z-order).
  func willVisitShape(
    info: ShapeInfo,
    spatialInfo: SpatialInfo
  ) async

  /// Called after visiting a floating shape and its text content (if any).
  func didVisitShape() async

  // MARK: - Groups

  /// Called before visiting a group of drawable elements.
  ///
  /// Groups are containers that hold multiple shapes, images, or other elements
  /// and treat them as a single unit for positioning and manipulation.
  ///
  /// All child elements will be visited between `willVisitGroup` and
  /// `didVisitGroup` using their appropriate visit methods.
  ///
  /// - Parameter spatialInfo: Complete spatial information for the group container.
  func willVisitGroup(spatialInfo: SpatialInfo) async

  /// Called after visiting a group and all its child elements.
  func didVisitGroup() async

  // MARK: - Charts

  /// Called to provide the complete chart information and data for a floating chart.
  ///
  /// Charts are complex elements with their own data, axes, series, and styling.
  /// This method provides all relevant information to recreate or analyze the chart.
  ///
  /// - Parameter info: Complete chart information including type, data, axes, series, and styling.
  /// - Parameter spatialInfo: Complete spatial information for the chart (position, rotation, z-order).
  func visitChart(info: ChartInfo, spatialInfo: SpatialInfo) async

  // MARK: - Floating 3D Objects

  /// Called when visiting a floating 3D object (positioned outside text flow).
  ///
  /// For inline 3D objects within paragraphs, use `visitInlineElement(.object3D(...))`
  /// instead. This method is only called for 3D objects with absolute positioning.
  ///
  /// - Parameters:
  ///   - info: 3D object metadata (pose, animations, thumbnail, captions).
  ///   - spatialInfo: Complete spatial information for the object (position, rotation, z-order).
  func visitObject3D(
    info: Object3DInfo,
    spatialInfo: SpatialInfo
  ) async
}

// MARK: - Default Implementations

extension IWorkDocumentVisitor {
  public func willVisitDocument(
    type: IWorkDocument.DocumentType,
    layout: DocumentLayout?,
    pageSettings: PageSettings?
  ) async {}

  public func didVisitDocument(type: IWorkDocument.DocumentType) async {}

  public func willVisitPagesBody(contentRect: CGRect) async {}
  public func didVisitPagesBody() async {}

  public func willVisitSheet(name: String, layout: SheetLayout?) async {}
  public func didVisitSheet(name: String) async {}

  public func willVisitSlide(index: Int, bounds: CGRect?) async {}
  public func didVisitSlide(index: Int) async {}

  public func willVisitParagraph(style: ParagraphStyle, spatialInfo: SpatialInfo?) async {}
  public func visitInlineElement(_ element: InlineElement) async {}
  public func didVisitParagraph() async {}

  public func willVisitList(style: ListStyle) async {}
  public func willVisitListItem(
    number: Int?,
    level: Int,
    style: ParagraphStyle,
    spatialInfo: SpatialInfo?
  ) async {}
  public func didVisitListItem() async {}
  public func didVisitList() async {}

  public func willVisitTable(
    name: String?,
    rowCount: UInt32,
    columnCount: UInt32,
    spatialInfo: SpatialInfo
  ) async {}
  public func willVisitTableRow(index: Int) async {}
  public func visitTableCell(row: Int, column: Int, content: TableCellContent) async {}
  public func didVisitTableRow(index: Int) async {}
  public func didVisitTable() async {}

  public func visitImage(
    info: ImageInfo,
    spatialInfo: SpatialInfo,
    ocrResult: OCRResult?,
    hyperlink: Hyperlink?
  ) async {}

  public func visitMedia(
    info: MediaInfo,
    spatialInfo: SpatialInfo
  ) async {}

  public func willVisitShape(
    info: ShapeInfo,
    spatialInfo: SpatialInfo
  ) async {}

  public func didVisitShape() async {}

  public func willVisitGroup(spatialInfo: SpatialInfo) async {}
  public func didVisitGroup() async {}

  public func visitChart(info: ChartInfo, spatialInfo: SpatialInfo) async {}

  public func visitObject3D(
    info: Object3DInfo,
    spatialInfo: SpatialInfo
  ) async {}
}
