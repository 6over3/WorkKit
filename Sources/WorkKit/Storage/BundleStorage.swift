import Foundation

// MARK: - Filesystem Bundle Storage

/// Content storage backed by a filesystem directory.
///
/// `BundleStorage` provides access to files within a directory-based iWork document bundle.
/// This implementation is used for documents stored as packages on the filesystem
/// (e.g., `.pages` bundles on macOS).
package final class BundleStorage: ContentStorage, @unchecked Sendable {
  // MARK: - Properties

  private let rootURL: URL
  private let fileManager = FileManager.default
  private let lock = NSLock()

  // MARK: - Initialization

  /// Creates a new bundle storage wrapper.
  ///
  /// - Parameter rootURL: The root directory URL of the document bundle.
  init(rootURL: URL) {
    self.rootURL = rootURL
  }

  // MARK: - ContentStorage Implementation

  public func readData(from path: String) throws -> Data {
    try lock.withLock {
      let fileURL = rootURL.appendingPathComponent(path)
      guard fileManager.fileExists(atPath: fileURL.path) else {
        throw IWorkError.archiveReadFailed(entry: path)
      }

      do {
        return try Data(contentsOf: fileURL)
      } catch {
        throw IWorkError.archiveReadFailed(entry: path)
      }
    }
  }

  public func copyItem(at path: String, to destinationURL: URL) throws {
    try lock.withLock {
      let sourceURL = rootURL.appendingPathComponent(path)
      guard fileManager.fileExists(atPath: sourceURL.path) else {
        throw IWorkError.archiveReadFailed(entry: path)
      }
      do {
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
      } catch {
        throw IWorkError.archiveReadFailed(entry: path)
      }
    }
  }

  public func paths(with suffix: String) -> [String] {
    lock.withLock {
      guard
        let enumerator = fileManager.enumerator(
          at: rootURL,
          includingPropertiesForKeys: [.isRegularFileKey],
          options: [.skipsHiddenFiles]
        )
      else {
        return []
      }

      var result: [String] = []
      for case let fileURL as URL in enumerator {
        guard fileURL.path.hasSuffix(suffix) else { continue }
        if let relativePath = fileURL.path.components(separatedBy: rootURL.path + "/").last {
          result.append(relativePath)
        }
      }
      return result
    }
  }

  public func contains(path: String) -> Bool {
    lock.withLock {
      let fileURL = rootURL.appendingPathComponent(path)
      return fileManager.fileExists(atPath: fileURL.path)
    }
  }

  public func size(at path: String) throws -> UInt64 {
    try lock.withLock {
      let fileURL = rootURL.appendingPathComponent(path)

      guard fileManager.fileExists(atPath: fileURL.path) else {
        throw IWorkError.archiveReadFailed(entry: path)
      }

      do {
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        guard let fileSize = attributes[.size] as? UInt64 else {
          throw IWorkError.archiveReadFailed(entry: path)
        }
        return fileSize
      } catch {
        throw IWorkError.archiveReadFailed(entry: path)
      }
    }
  }
}
