import Foundation
import ZIPFoundation

// MARK: - ZIP Archive Storage

/// Content storage backed by a ZIP archive.
///
/// `ArchiveStorage` provides access to files within a ZIP-compressed iWork document.
/// This implementation is used for single-file document packages (`.pages`, `.numbers`, `.key`)
/// rather than directory bundles.
///
/// - Note: This class uses `@unchecked Sendable` because the underlying `Archive` type
///   from ZIPFoundation may not be marked as `Sendable`, but instances are only
///   accessed for read operations which are inherently thread-safe.
package final class ArchiveStorage: ContentStorage, @unchecked Sendable {
  // MARK: - Properties

  private let archive: Archive
  private let lock = NSLock()

  // MARK: - Initialization

  /// Creates a new archive storage wrapper.
  ///
  /// - Parameter archive: The ZIP archive to read from.
  init(archive: Archive) {
    self.archive = archive
  }

  // MARK: - ContentStorage Implementation

  public func readData(from path: String) throws -> Data {
    try lock.withLock {
      guard let entry = archive[path] else {
        throw IWorkError.archiveReadFailed(entry: path)
      }
      var data = Data()
      _ = try archive.extract(entry) { chunk in
        data.append(chunk)
      }
      return data
    }
  }

  public func copyItem(at path: String, to destinationURL: URL) throws {
    try lock.withLock {
      guard let entry = archive[path] else {
        throw IWorkError.archiveReadFailed(entry: path)
      }
      do {
        _ = try archive.extract(entry, to: destinationURL)
      } catch {
        throw IWorkError.archiveReadFailed(entry: path)
      }
    }
  }

  public func paths(with suffix: String) -> [String] {
    lock.withLock {
      archive.compactMap { entry in
        entry.path.hasSuffix(suffix) ? entry.path : nil
      }
    }
  }

  public func contains(path: String) -> Bool {
    lock.withLock {
      archive[path] != nil
    }
  }

  public func size(at path: String) throws -> UInt64 {
    try lock.withLock {
      guard let entry = archive[path] else {
        throw IWorkError.archiveReadFailed(entry: path)
      }
      return entry.uncompressedSize
    }
  }
}
