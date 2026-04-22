import Foundation

/// Concrete storage type for reading content from iWork document packages.
///
/// Wraps either a filesystem bundle or ZIP archive, eliminating the need
/// for protocol existentials while providing a unified read interface.
public struct DocumentStorage: ContentStorage, Sendable {
  private enum Backing: Sendable {
    case bundle(BundleStorage)
    case archive(ArchiveStorage)
  }

  private let backing: Backing

  package init(bundle: BundleStorage) {
    self.backing = .bundle(bundle)
  }

  package init(archive: ArchiveStorage) {
    self.backing = .archive(archive)
  }

  public func readData(from path: String) throws -> Data {
    switch backing {
    case .bundle(let s): try s.readData(from: path)
    case .archive(let s): try s.readData(from: path)
    }
  }

  public func paths(with suffix: String) -> [String] {
    switch backing {
    case .bundle(let s): s.paths(with: suffix)
    case .archive(let s): s.paths(with: suffix)
    }
  }

  public func contains(path: String) -> Bool {
    switch backing {
    case .bundle(let s): s.contains(path: path)
    case .archive(let s): s.contains(path: path)
    }
  }

  public func size(at path: String) throws -> UInt64 {
    switch backing {
    case .bundle(let s): try s.size(at: path)
    case .archive(let s): try s.size(at: path)
    }
  }
}
