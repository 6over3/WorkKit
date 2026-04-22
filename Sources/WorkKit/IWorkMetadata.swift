import Foundation

// MARK: - Document Metadata

/// Metadata extracted from an iWork document.
///
/// `IWorkMetadata` contains information parsed from various metadata files within
/// the document package, including document properties, identifiers, and build history.
///
/// ## Topics
///
/// ### Properties
///
/// - ``properties``
/// - ``documentIdentifier``
/// - ``buildVersionHistory``
///
/// ### Nested Types
///
/// - ``DocumentProperties``
///
/// ## Example
///
/// ```swift
/// let document = try IWorkDocument(url: URL(fileURLWithPath: "/path/to/document.pages"))
/// let metadata = document.metadata
///
/// if let uuid = metadata.properties?.documentUUID {
///   print("Document UUID: \(uuid)")
/// }
///
/// print("Build history: \(metadata.buildVersionHistory)")
/// ```
public struct IWorkMetadata: Sendable, Codable, Equatable {

  // MARK: - Properties

  /// Parsed contents of Properties.plist.
  ///
  /// Contains various document properties including UUIDs, version information,
  /// and document settings. This property is `nil` for legacy format documents
  /// that do not contain a Properties.plist file.
  public let properties: DocumentProperties?

  /// Raw document identifier from the DocumentIdentifier file.
  ///
  /// A unique identifier for the document. This property is `nil` if the
  /// DocumentIdentifier file is not present in the document package.
  public let documentIdentifier: String?

  /// Build version history entries from BuildVersionHistory.plist.
  ///
  /// An array of build version strings indicating which versions of iWork
  /// have been used to edit this document. The array is empty if no build
  /// history is available.
  public let buildVersionHistory: [String]

  // MARK: - Initialization

  internal init(
    properties: DocumentProperties? = nil,
    documentIdentifier: String? = nil,
    buildVersionHistory: [String] = []
  ) {
    self.properties = properties
    self.documentIdentifier = documentIdentifier
    self.buildVersionHistory = buildVersionHistory
  }
}

// MARK: - Document Properties

extension IWorkMetadata {
  /// Properties from the Properties.plist file.
  ///
  /// Contains detailed metadata about the document including various UUID identifiers,
  /// version information, and document configuration settings.
  public struct DocumentProperties: Sendable, Codable, Equatable {

    // MARK: - Properties

    /// The primary document UUID.
    public let documentUUID: String?

    /// The file format version string.
    ///
    /// Indicates the specific version of the iWork file format used by this document.
    public let fileFormatVersion: String?

    /// Whether the document is configured for multi-page layout.
    ///
    /// Only applicable to certain document types (e.g., Pages documents).
    public let isMultiPage: Bool?

    /// A private UUID for internal use.
    public let privateUUID: String?

    /// The document revision identifier.
    public let revision: String?

    /// UUID used for document sharing.
    public let shareUUID: String?

    /// A stable UUID that persists across document modifications.
    public let stableDocumentUUID: String?

    /// UUID identifying the current version of the document.
    public let versionUUID: String?

    // MARK: - Initialization

    internal init(from plist: [String: Any]) {
      self.documentUUID = plist["documentUUID"] as? String
      self.fileFormatVersion = plist["fileFormatVersion"] as? String
      self.isMultiPage = plist["isMultiPage"] as? Bool
      self.privateUUID = plist["privateUUID"] as? String
      self.revision = plist["revision"] as? String
      self.shareUUID = plist["shareUUID"] as? String
      self.stableDocumentUUID = plist["stableDocumentUUID"] as? String
      self.versionUUID = plist["versionUUID"] as? String
    }
  }
}
