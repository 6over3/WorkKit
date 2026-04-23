import Foundation
import SwiftProtobuf

// MARK: - Document Type

/// Represents an iWork document (Pages, Numbers, or Keynote).
///
/// Provides access to the document's structure, metadata, and content.
///
/// ## Topics
///
/// ### Document Properties
///
/// - ``type``
/// - ``format``
/// - ``metadata``
/// - ``storage``
///
/// ### Working with Previews
///
/// - ``preview(_:)``
/// - ``allPreviews()``
/// - ``PreviewSize``
///
///
/// ### Supporting Types
///
/// - ``DocumentType``
/// - ``FormatVersion``
///
/// ## Example
///
/// ```swift
/// let document = try IWorkDocument(url: URL(fileURLWithPath: "/path/to/document.pages"))
///
/// // Access metadata
/// print("Document type: \(document.type)")
/// print("Format: \(document.format)")
///
/// // Get preview image
/// if let preview = document.preview(.thumbnail) {
///   let image = UIImage(data: preview)
/// }
///
/// // Traverse document content
/// struct MyVisitor: IWorkDocumentVisitor {
///   func visitText(_ text: String, style: CharacterStyle, hyperlink: Hyperlink?, footnotes: [Footnote]?) async {
///     print(text)
///   }
/// }
///
/// let visitor = MyVisitor(document: document)
/// try await visitor.accept()
/// ```
public struct IWorkDocument: @unchecked Sendable {

  // MARK: - Public Properties

  /// The type of iWork document.
  public let type: DocumentType

  /// The format version of the document.
  public let format: FormatVersion

  /// Metadata extracted from the document package.
  public let metadata: IWorkMetadata

  /// Content storage for reading files from the document.
  public let storage: DocumentStorage

  // MARK: - Internal Properties

  /// The internal record storage, indexed by identifier.
  internal let records: [UInt64: SwiftProtobuf.Message]

  /// URL to the document package root.
  package let packageURL: URL

  // MARK: - Initialization

  /// Opens and parses an iWork document.
  ///
  /// Supports both legacy (2008-2009) and modern (2013+) iWork formats.
  /// The document can be either a directory bundle or a ZIP archive.
  ///
  /// - Parameter url: File URL to the iWork document package.
  /// - Throws: ``IWorkError`` if the document cannot be opened or parsed.
  public init(url: URL) throws {
    self = try IWorkParser.open(at: url)
  }

  package init(
    type: DocumentType,
    format: FormatVersion,
    records: [UInt64: SwiftProtobuf.Message],
    metadata: IWorkMetadata,
    storage: DocumentStorage,
    packageURL: URL
  ) {
    self.type = type
    self.format = format
    self.records = records
    self.metadata = metadata
    self.storage = storage
    self.packageURL = packageURL
  }

  // MARK: - Preview Access

  /// Retrieves preview image or PDF data.
  ///
  /// The format and availability of previews varies between modern and legacy documents:
  /// - Modern documents (2013+) use JPEG images in various sizes
  /// - Legacy documents (2008-2009) use PDF for standard previews and JPEG/TIFF for thumbnails
  ///
  /// ## Example
  ///
  /// ```swift
  /// if let thumbnailData = document.preview(.thumbnail) {
  ///   let image = UIImage(data: thumbnailData)
  /// }
  /// ```
  ///
  /// - Parameter size: The preview size to retrieve.
  /// - Returns: Image or PDF data if the preview exists, otherwise `nil`.
  public func preview(_ size: PreviewSize) -> Data? {
    switch format {
    case .modern, .creatorStudio:
      let path: String
      switch size {
      case .thumbnail:
        path = "preview-micro.jpg"
      case .standard:
        path = "preview.jpg"
      case .web:
        path = "preview-web.jpg"
      case .legacyTIFF:
        return nil
      }
      return try? storage.readData(from: path)

    case .legacy:
      switch size {
      case .thumbnail:
        if let data = try? storage.readData(from: "QuickLook/Thumbnail.jpg") {
          return data
        }
        return try? storage.readData(from: "thumbs/PageCapThumbV2-1.tiff")

      case .standard:
        return try? storage.readData(from: "QuickLook/Preview.pdf")

      case .web:
        return try? storage.readData(from: "QuickLook/Thumbnail.jpg")

      case .legacyTIFF(let page):
        return try? storage.readData(from: "thumbs/PageCapThumbV2-\(page).tiff")
      }
    }
  }

  /// Retrieves all available preview images.
  ///
  /// This method returns a dictionary of all preview images that exist in the document,
  /// using descriptive keys for each preview type.
  ///
  /// ## Example
  ///
  /// ```swift
  /// let previews = document.allPreviews()
  /// for (name, data) in previews {
  ///   print("Found preview: \(name)")
  /// }
  /// ```
  ///
  /// - Returns: A dictionary mapping preview descriptions to image/PDF data.
  public func allPreviews() -> [String: Data] {
    var previews: [String: Data] = [:]

    switch format {
    case .modern, .creatorStudio:
      if let thumbnail = preview(.thumbnail) {
        previews["thumbnail"] = thumbnail
      }
      if let standard = preview(.standard) {
        previews["standard"] = standard
      }
      if let web = preview(.web) {
        previews["web"] = web
      }

    case .legacy:
      if let thumbnail = preview(.thumbnail) {
        previews["thumbnail"] = thumbnail
      }
      if let standard = preview(.standard) {
        previews["preview-pdf"] = standard
      }
      if let web = preview(.web) {
        previews["web"] = web
      }

      var page = 1
      while let tiff = preview(.legacyTIFF(page: page)) {
        previews["page-\(page)-tiff"] = tiff
        page += 1
        if page > 100 { break }
      }
    }

    return previews
  }

  // MARK: - Document Traversal

  /// Traverses the document and invokes visitor methods for each element.
  ///
  /// - Parameters:
  ///   - visitor: The visitor to receive callbacks during traversal.
  ///   - ocrProvider: OCR provider for image text recognition.
  /// - Throws: ``IWorkError/legacyNotImplemented`` for legacy format documents,
  ///           or errors during traversal or visitor processing.
  public func accept<V: IWorkDocumentVisitor, O: OCRProvider>(
    visitor: V,
    ocrProvider: O
  ) async throws {
    switch format {
    case .modern, .creatorStudio:
      let context = TraversalContext(
        document: self,
        visitor: visitor,
        ocrProvider: ocrProvider
      )
      try await context.traverse()

    case .legacy:
      throw IWorkError.legacyNotImplemented
    }
  }

  /// Traverses the document and invokes visitor methods for each element.
  ///
  /// - Parameter visitor: The visitor to receive callbacks during traversal.
  /// - Throws: ``IWorkError/legacyNotImplemented`` for legacy format documents,
  ///           or errors during traversal or visitor processing.
  public func accept<V: IWorkDocumentVisitor>(
    visitor: V
  ) async throws {
    switch format {
    case .modern, .creatorStudio:
      let context = TraversalContext<V, NullOCRProvider>(
        document: self,
        visitor: visitor,
        ocrProvider: nil
      )
      try await context.traverse()

    case .legacy:
      throw IWorkError.legacyNotImplemented
    }
  }

  // MARK: - Internal Record Access

  internal func dereference<T: SwiftProtobuf.Message>(_ reference: TSP_Reference?) -> T? {
    guard let reference = reference, reference.hasIdentifier else {
      return nil
    }
    return records[reference.identifier] as? T
  }

  internal func dereference(_ reference: TSP_Reference?) -> SwiftProtobuf.Message? {
    guard let reference = reference, reference.hasIdentifier else {
      return nil
    }
    return records[reference.identifier]
  }

  package func record<T: SwiftProtobuf.Message>(id: UInt64) -> T? {
    records[id] as? T
  }

  package func firstRecord<T: SwiftProtobuf.Message>(
    ofType type: T.Type
  ) -> (id: UInt64, record: T)? {
    for (id, record) in records {
      if let typed = record as? T {
        return (id, typed)
      }
    }
    return nil
  }

  package func allRecords<T: SwiftProtobuf.Message>(
    ofType type: T.Type
  ) -> [(id: UInt64, record: T)] {
    records.compactMap { (id, record) in
      guard let typed = record as? T else { return nil }
      return (id, typed)
    }
  }
}

// MARK: - Document Type

extension IWorkDocument {
  /// The type of iWork document.
  public enum DocumentType: String, Sendable, Codable, Equatable {
    /// A Pages word processing document.
    case pages

    /// A Numbers spreadsheet document.
    case numbers

    /// A Keynote presentation document.
    case keynote

    /// The file extension associated with this document type.
    ///
    /// - Returns: The file extension without the leading dot.
    public var fileExtension: String {
      switch self {
      case .pages:
        return "pages"
      case .numbers:
        return "numbers"
      case .keynote:
        return "key"
      }
    }
  }
}

// MARK: - Format Version

extension IWorkDocument {
  /// The format version of the iWork document.
  public enum FormatVersion: Sendable, Codable, Equatable {
    /// Legacy XML-based format (2008-2009).
    case legacy

    /// Classic modern protobuf-based format (Pages/Numbers/Keynote 5–14, file format major < 26).
    case modern(Semver)

    /// Creator Studio format (Pages/Numbers/Keynote 15+, file format major ≥ 26).
    ///
    /// Apple bumped `fileFormatVersion` from the 14.x line directly to 26.x when shipping
    /// the Creator Studio apps; documents produced by those apps are tagged with this case.
    case creatorStudio(Semver)

    /// The parsed file-format version for modern documents, or `nil` for legacy.
    public var semver: Semver? {
      switch self {
      case .legacy: return nil
      case .modern(let v), .creatorStudio(let v): return v
      }
    }

    /// Whether the document uses the legacy XML format.
    public var isLegacy: Bool {
      if case .legacy = self { return true }
      return false
    }

    /// Whether the document uses either modern protobuf format (classic or Creator Studio).
    public var isModern: Bool {
      switch self {
      case .legacy: return false
      case .modern, .creatorStudio: return true
      }
    }

    /// Whether the document was produced by a Creator Studio app.
    public var isCreatorStudio: Bool {
      if case .creatorStudio = self { return true }
      return false
    }
  }

  /// Semantic version parsed from a dotted version string.
  public struct Semver: Sendable, Codable, Equatable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int = 0, patch: Int = 0) {
      self.major = major
      self.minor = minor
      self.patch = patch
    }

    /// Parses a dotted version string like `"14.4.1"` or `"26.1.0"`. Trailing components
    /// default to `0`; non-numeric components cause a `nil` result.
    public init?(_ raw: String) {
      let parts = raw.split(separator: ".")
      guard !parts.isEmpty, let major = Int(parts[0]) else { return nil }
      let minor = parts.count > 1 ? Int(parts[1]) : 0
      let patch = parts.count > 2 ? Int(parts[2]) : 0
      guard let minor, let patch else { return nil }
      self.major = major
      self.minor = minor
      self.patch = patch
    }

    public static func < (lhs: Semver, rhs: Semver) -> Bool {
      if lhs.major != rhs.major { return lhs.major < rhs.major }
      if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
      return lhs.patch < rhs.patch
    }

    public var description: String { "\(major).\(minor).\(patch)" }
  }
}

// MARK: - Preview Size

extension IWorkDocument {
  /// Preview image size and format options.
  public enum PreviewSize: Sendable, Equatable {
    /// Small thumbnail image.
    ///
    /// - Modern format: `preview-micro.jpg`
    /// - Legacy format: `QuickLook/Thumbnail.jpg` or `thumbs/PageCapThumbV2-1.tiff`
    case thumbnail

    /// Standard preview image or PDF.
    ///
    /// - Modern format: `preview.jpg`
    /// - Legacy format: `QuickLook/Preview.pdf`
    case standard

    /// Web-optimized preview image.
    ///
    /// - Modern format: `preview-web.jpg`
    /// - Legacy format: `QuickLook/Thumbnail.jpg`
    case web

    /// Legacy TIFF thumbnail for a specific page (legacy format only).
    ///
    /// Available only in legacy format documents. Returns `nil` for modern format documents.
    ///
    /// - Parameter page: The page number (1-based).
    case legacyTIFF(page: Int)
  }
}
