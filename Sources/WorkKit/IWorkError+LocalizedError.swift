import Foundation

// MARK: - Localized Error

extension IWorkError: LocalizedError {
  /// A localized message describing what error occurred.
  ///
  /// This property provides user-friendly error descriptions suitable for display
  /// in user interfaces or error messages.
  public var errorDescription: String? {
    switch self {
    case .fileNotFound(let url):
      return "File not found at path: \(url.path)"

    case .unknownDocumentType(let ext):
      return "Unknown document type for extension: \(ext)"

    case .missingIndexArchive:
      return "Index.zip file is missing from the document package."

    case .archiveReadFailed(let entry):
      return "Failed to read archive entry: \(entry)"

    case .snappyDecompressionFailed:
      return "Snappy decompression failed for IWA data."

    case .invalidIWAHeader(let expected, let found):
      return "Invalid IWA header: expected \(expected), found \(found)"

    case .protobufDecodingFailed(let id, let type):
      return "Failed to decode protobuf message (id: \(id), type: \(type))"

    case .invalidArchiveStructure(let reason):
      return "The archive structure is invalid or corrupted: \(reason)"

    case .metadataParsingFailed(let file):
      return "Failed to parse metadata file: \(file)"

    case .xmlParsingFailed(let reason):
      return "Failed to parse XML: \(reason)"

    case .legacyNotImplemented:
      return "This feature is not implemented for legacy formats at this time."

    case .equationReadFailed(let id, let reason):
      return "Failed to read equation with ID \(id): \(reason)"

    case .documentTypeMismatch(let expected, let found):
      return "Document type mismatch: expected \(expected), found \(found)"

    case .invalidFileFormatVersion(let raw):
      if let raw, !raw.isEmpty {
        return "Properties.plist has an unparseable fileFormatVersion: \(raw)"
      }
      return "Properties.plist is missing a fileFormatVersion entry."
    }
  }
}
