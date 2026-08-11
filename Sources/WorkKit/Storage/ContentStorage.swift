import Foundation

// MARK: - Content Storage Protocol
/// Abstraction for reading content from either a filesystem bundle or ZIP archive.
///
/// `ContentStorage` provides a unified interface for accessing files within an iWork document,
/// regardless of whether the document is stored as a directory bundle or a ZIP archive.
///
/// ## Topics
///
/// ### Reading Data
///
/// - ``readData(at:)``
/// - ``readEquation(of:)``
///
/// ### Querying Contents
///
/// - ``paths(with:)``
/// - ``contains(path:)``
/// - ``size(at:)``
///
/// ## Example
///
/// ```swift
/// let storage: ContentStorage = // ...
///
/// // Read a file
/// let data = try storage.readData(at: "preview.jpg")
///
/// // Check if a file exists
/// if storage.contains(path: "Metadata/Properties.plist") {
///     // File exists
/// }
///
/// // Get file size
/// let fileSize = try storage.size(at: "preview.jpg")
/// print("File size: \(fileSize) bytes")
///
/// // Find all IWA files
/// let iwaFiles = storage.paths(with: ".iwa")
/// ```
public protocol ContentStorage: Sendable {
  // MARK: - Reading Data

  /// Reads the data at the specified path.
  ///
  /// This method retrieves the raw binary content of a file within the document storage.
  ///
  /// - Parameter path: The path to the file within the storage.
  /// - Returns: The file data.
  /// - Throws: ``IWorkError/archiveReadFailed(entry:)`` if the file cannot be read.
  func readData(from path: String) throws -> Data

  /// Copies one stored file to a local URL without materializing all bytes in memory.
  func copyItem(at path: String, to destinationURL: URL) throws

  // MARK: - Querying Contents

  /// Returns all paths with the specified suffix.
  ///
  /// This method is useful for discovering files of a particular type within the document.
  ///
  /// ## Example
  ///
  /// ```swift
  /// // Find all IWA archive files
  /// let iwaFiles = storage.paths(with: ".iwa")
  ///
  /// // Find all JPEG images
  /// let images = storage.paths(with: ".jpg")
  /// ```
  ///
  /// - Parameter suffix: The file suffix to filter by (e.g., ".iwa", ".jpg").
  /// - Returns: An array of matching paths within the storage.
  func paths(with suffix: String) -> [String]

  /// Checks if a file exists at the specified path.
  ///
  /// - Parameter path: The path to check within the storage.
  /// - Returns: `true` if the file exists, `false` otherwise.
  func contains(path: String) -> Bool

  /// Returns the size of the file at the specified path.
  ///
  /// This method retrieves the uncompressed size of the file in bytes, which is useful
  /// for memory management, progress reporting, or determining whether to load a file
  /// into memory.
  ///
  /// ## Example
  ///
  /// ```swift
  /// let size = try storage.size(at: "preview.jpg")
  /// if size > 10_000_000 {
  ///     print("Large file detected: \(size) bytes")
  /// }
  /// ```
  ///
  /// - Parameter path: The path to the file within the storage.
  /// - Returns: The file size in bytes.
  /// - Throws: ``IWorkError/archiveReadFailed(entry:)`` if the file size cannot be determined.
  func size(at path: String) throws -> UInt64
}
