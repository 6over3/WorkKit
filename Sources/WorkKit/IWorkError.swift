import Foundation

// MARK: - Errors

/// Errors that can occur while parsing or processing iWork documents.
///
/// `IWorkError` represents various failure conditions that may be encountered
/// when opening, parsing, or traversing iWork documents.
///
/// ## Topics
///
/// ### File and Document Errors
///
/// - ``fileNotFound(url:)``
/// - ``unknownDocumentType(extension:)``
/// - ``missingIndexArchive```
/// - ``documentTypeMismatch(expected:found:)```
///
/// ### Archive and Compression Errors
///
/// - ``archiveReadFailed(entry:)``
/// - ``snappyDecompressionFailed``
/// - ``invalidIWAHeader(expected:found:)``
/// - ``invalidArchiveStructure(reason:)``
///
/// ### Parsing Errors
///
/// - ``protobufDecodingFailed(identifier:type:)``
/// - ``metadataParsingFailed(file:)``
/// - ``xmlParsingFailed(reason:)``
///
/// ### Feature Support Errors
///
/// - ``legacyNotImplemented``
/// - ``equationReadFailed(id:reason:)``
public enum IWorkError: Error, Sendable, Equatable {

  // MARK: - File and Document Errors

  /// The specified file path does not exist.
  ///
  /// This error is thrown when attempting to open a document at a path that
  /// does not exist on the filesystem.
  ///
  /// - Parameter url: The file URL that was not found.
  case fileNotFound(url: URL)

  /// The document type could not be determined from the file extension.
  ///
  /// This error is thrown when the file extension is not recognized as a valid
  /// iWork document type (`.pages`, `.numbers`, or `.key`).
  ///
  /// - Parameter extension: The unrecognized file extension.
  case unknownDocumentType(extension: String)

  /// The Index.zip file is missing or could not be opened.
  ///
  /// This error is thrown when the required Index.zip archive (in modern format documents)
  /// or index files (in legacy format documents) cannot be found or accessed.
  case missingIndexArchive

  // MARK: - Archive and Compression Errors

  /// Failed to read data from an archive entry.
  ///
  /// This error is thrown when a specific file within the document package
  /// cannot be read or extracted.
  ///
  /// - Parameter entry: The path of the archive entry that could not be read.
  case archiveReadFailed(entry: String)

  /// Snappy decompression failed for an IWA chunk.
  ///
  /// This error is thrown when the Snappy decompression algorithm fails to
  /// decompress data from an IWA (iWork Archive) file.
  case snappyDecompressionFailed

  /// Invalid IWA format - expected header byte was not found.
  ///
  /// This error is thrown when an IWA file contains an unexpected header byte,
  /// indicating file corruption or an unsupported format variant.
  ///
  /// - Parameters:
  ///   - expected: The header byte value that was expected.
  ///   - found: The header byte value that was actually found.
  case invalidIWAHeader(expected: UInt8, found: UInt8)

  /// The archive structure is invalid or corrupted.
  ///
  /// This error is thrown when the internal structure of the document archive
  /// does not conform to the expected format.
  ///
  /// - Parameter reason: A description of the structural problem.
  case invalidArchiveStructure(reason: String)

  // MARK: - Parsing Errors

  /// Protobuf decoding failed for a specific record.
  ///
  /// This error is thrown when a Protocol Buffer message cannot be decoded
  /// from the raw data in an IWA file.
  ///
  /// - Parameters:
  ///   - identifier: The unique identifier of the record that failed to decode.
  ///   - type: The protobuf message type identifier.
  case protobufDecodingFailed(identifier: UInt64, type: UInt32)

  /// Failed to parse a metadata plist file.
  ///
  /// This error is thrown when a property list file in the document's metadata
  /// cannot be parsed.
  ///
  /// - Parameter file: The name of the metadata file that failed to parse.
  case metadataParsingFailed(file: String)

  /// Failed to parse legacy XML format content.
  ///
  /// This error is thrown when XML content in a legacy format document
  /// cannot be parsed.
  ///
  /// - Parameter reason: A description of the XML parsing failure.
  case xmlParsingFailed(reason: String)

  // MARK: - Feature Support Errors

  /// Legacy format documents are not yet fully implemented.
  ///
  /// This error is thrown when attempting to perform operations on legacy
  /// format documents (2008-2009) that are not yet supported by the parser.
  case legacyNotImplemented

  /// Failed to read or extract an equation from PDF metadata.
  ///
  /// This error is thrown when an equation stored in PDF metadata cannot
  /// be accessed or parsed.
  ///
  /// - Parameters:
  ///   - id: The identifier of the equation record.
  ///   - reason: A description of why the equation could not be read.
  case equationReadFailed(id: UInt64, reason: String)

  /// The document type does not match the expected type.
  ///
  /// This error is thrown when the actual document type differs from
  /// what was anticipated, indicating a possible misidentification.
  /// - Parameters:
  ///   - expected: The expected document type.
  ///   - found: The actual document type found.
  case documentTypeMismatch(expected: IWorkDocument.DocumentType, found: IWorkDocument.DocumentType)
}
