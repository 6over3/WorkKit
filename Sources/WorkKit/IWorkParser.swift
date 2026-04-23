import Compression
import Foundation
import SwiftProtobuf
import ZIPFoundation

// MARK: - Document Parser

enum IWorkParser {

  // MARK: - Internal API

  static func open(at url: URL) throws -> IWorkDocument {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      throw IWorkError.fileNotFound(url: url)
    }

    let documentType = try determineDocumentType(from: url)

    if isDirectory.boolValue {
      return try openBundleFormat(at: url, documentType: documentType)
    } else {
      return try openZipFormat(at: url, documentType: documentType)
    }
  }

  // MARK: - Document Type Detection

  private static func determineDocumentType(from url: URL) throws -> IWorkDocument.DocumentType {
    let ext = url.pathExtension.lowercased()
    let cleanExt = ext.replacingOccurrences(of: "-tef", with: "")

    switch cleanExt {
    case "pages":
      return .pages
    case "numbers":
      return .numbers
    case "key":
      return .keynote
    default:
      throw IWorkError.unknownDocumentType(extension: ext)
    }
  }

  // MARK: - Bundle Format Parsing

  private static func openBundleFormat(
    at packageURL: URL,
    documentType: IWorkDocument.DocumentType
  ) throws -> IWorkDocument {
    let legacyPaths = [
      "index.xml.gz",
      "index.apxl.gz",
    ]
    let modernIndexPath = packageURL.appendingPathComponent("Index.zip")

    var legacyIndexExists = false
    for pathComponent in legacyPaths {
      let fullPath = packageURL.appendingPathComponent(pathComponent)
      if FileManager.default.fileExists(atPath: fullPath.path) {
        legacyIndexExists = true
        break
      }
    }

    if legacyIndexExists {
      return try openLegacyBundle(at: packageURL, documentType: documentType)
    } else if FileManager.default.fileExists(atPath: modernIndexPath.path) {
      return try openModernBundle(at: packageURL, documentType: documentType)
    } else {
      throw IWorkError.missingIndexArchive
    }
  }

  private static func openModernBundle(
    at packageURL: URL,
    documentType: IWorkDocument.DocumentType
  ) throws -> IWorkDocument {
    let metadataStorage = BundleStorage(rootURL: packageURL.appendingPathComponent("Metadata"))
    let metadata = try parseMetadata(from: metadataStorage)
    let indexPath = packageURL.appendingPathComponent("Index.zip").path
    guard FileManager.default.fileExists(atPath: indexPath) else {
      throw IWorkError.missingIndexArchive
    }
    let archive: Archive
    do {
      archive = try Archive(
        url: URL(fileURLWithPath: indexPath),
        accessMode: .read,
        pathEncoding: .utf8
      )
    } catch {
      throw IWorkError.missingIndexArchive
    }
    let indexStorage = ArchiveStorage(archive: archive)
    let records = try loadRecords(from: indexStorage, documentType: documentType, prefix: "")
    return IWorkDocument(
      type: documentType,
      format: try modernFormatVersion(from: metadata),
      records: records,
      metadata: metadata,
      storage: DocumentStorage(bundle: BundleStorage(rootURL: packageURL)),
      packageURL: packageURL
    )
  }

  private static func openLegacyBundle(
    at packageURL: URL,
    documentType: IWorkDocument.DocumentType
  ) throws -> IWorkDocument {
    let bundleStorage = BundleStorage(rootURL: packageURL)
    let metadata = try parseLegacyMetadata(from: bundleStorage)
    let records: [UInt64: SwiftProtobuf.Message] = [:]
    return IWorkDocument(
      type: documentType,
      format: .legacy,
      records: records,
      metadata: metadata,
      storage: DocumentStorage(bundle: bundleStorage),
      packageURL: packageURL
    )
  }

  // MARK: - ZIP Format Parsing

  private static func openZipFormat(
    at fileURL: URL,
    documentType: IWorkDocument.DocumentType
  ) throws -> IWorkDocument {
    let archive: Archive
    do {
      archive = try Archive(url: fileURL, accessMode: .read, pathEncoding: .utf8)
    } catch {
      throw IWorkError.missingIndexArchive
    }
    let storage = ArchiveStorage(archive: archive)

    if archive["Index/Document.iwa"] != nil {
      return try openModernArchive(
        storage: storage, documentType: documentType, packageURL: fileURL)
    }

    let legacyPaths = ["index.xml", "index.apxl"]
    var hasLegacyIndex = false
    for path in legacyPaths {
      if archive[path] != nil {
        hasLegacyIndex = true
        break
      }
    }

    if hasLegacyIndex {
      return try openLegacyArchive(
        storage: storage, documentType: documentType, packageURL: fileURL)
    } else {
      throw IWorkError.missingIndexArchive
    }
  }

  /// Determines the actual document type by examining decoded records.
  ///
  /// This method looks for specific archive types in the decoded records to determine
  /// the actual document type, which is more reliable than file extension.
  ///
  /// - Parameter records: The decoded IWA records.
  /// - Returns: The actual document type, or `nil` if it cannot be determined.
  private static func determineDocumentTypeFromRecords(_ records: [UInt64: SwiftProtobuf.Message])
    -> IWorkDocument.DocumentType?
  {
    // Look through all records to find document-specific archive types
    for (_, record) in records {
      if record is TP_DocumentArchive {
        return .pages
      }
      if record is KN_DocumentArchive {
        return .keynote
      }
      if record is TN_DocumentArchive {
        return .numbers
      }
    }

    return nil
  }

  private static func openModernArchive(
    storage: ArchiveStorage,
    documentType: IWorkDocument.DocumentType,
    packageURL: URL
  ) throws -> IWorkDocument {
    let metadata = try parseMetadata(from: storage, prefix: "Metadata/")
    let records = try loadRecords(from: storage, documentType: documentType, prefix: "Index/")
    if let detectedType = determineDocumentTypeFromRecords(records) {
      if detectedType != documentType {
        throw IWorkError.documentTypeMismatch(expected: documentType, found: detectedType)
      }
    }
    return IWorkDocument(
      type: documentType,
      format: try modernFormatVersion(from: metadata),
      records: records,
      metadata: metadata,
      storage: DocumentStorage(archive: storage),
      packageURL: packageURL
    )
  }

  private static func openLegacyArchive(
    storage: ArchiveStorage,
    documentType: IWorkDocument.DocumentType,
    packageURL: URL
  ) throws -> IWorkDocument {
    let metadata = try parseLegacyMetadata(from: storage)
    let records: [UInt64: SwiftProtobuf.Message] = [:]

    return IWorkDocument(
      type: documentType,
      format: .legacy,
      records: records,
      metadata: metadata,
      storage: DocumentStorage(archive: storage),
      packageURL: packageURL
    )
  }

  // MARK: - Format Version Classification

  /// File-format major version at which Apple introduced the Creator Studio apps.
  /// Documents produced by Pages/Numbers/Keynote 15+ are tagged 26.x; older apps stay at 14.x.
  private static let creatorStudioFormatMajor = 26

  private static func modernFormatVersion(
    from metadata: IWorkMetadata
  ) throws -> IWorkDocument.FormatVersion {
    let raw = metadata.properties?.fileFormatVersion
    guard let raw, !raw.isEmpty else {
      throw IWorkError.invalidFileFormatVersion(raw: raw)
    }
    guard let semver = IWorkDocument.Semver(raw) else {
      throw IWorkError.invalidFileFormatVersion(raw: raw)
    }
    return semver.major >= creatorStudioFormatMajor
      ? .creatorStudio(semver)
      : .modern(semver)
  }

  // MARK: - Metadata Parsing

  private static func parseMetadata<S: ContentStorage>(
    from storage: S,
    prefix: String = ""
  ) throws -> IWorkMetadata {
    let properties: IWorkMetadata.DocumentProperties? = {
      guard let plistData = try? storage.readData(from: prefix + "Properties.plist"),
        let plist = try? PropertyListSerialization.propertyList(
          from: plistData,
          format: nil
        ) as? [String: Any]
      else {
        return nil
      }
      return IWorkMetadata.DocumentProperties(from: plist)
    }()

    let documentIdentifier: String? = {
      guard let data = try? storage.readData(from: prefix + "DocumentIdentifier"),
        let identifier = String(data: data, encoding: .utf8)
      else {
        return nil
      }
      return identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    let buildVersionHistory: [String] = {
      guard let plistData = try? storage.readData(from: prefix + "BuildVersionHistory.plist"),
        let history = try? PropertyListSerialization.propertyList(
          from: plistData,
          format: nil
        ) as? [String]
      else {
        return []
      }
      return history
    }()

    return IWorkMetadata(
      properties: properties,
      documentIdentifier: documentIdentifier,
      buildVersionHistory: buildVersionHistory
    )
  }

  private static func parseLegacyMetadata<S: ContentStorage>(from storage: S) throws -> IWorkMetadata {
    let buildVersionHistory: [String] = {
      guard let plistData = try? storage.readData(from: "buildVersionHistory.plist"),
        let history = try? PropertyListSerialization.propertyList(
          from: plistData,
          format: nil
        ) as? [String]
      else {
        return []
      }
      return history
    }()

    return IWorkMetadata(
      properties: nil,
      documentIdentifier: nil,
      buildVersionHistory: buildVersionHistory
    )
  }

  // MARK: - Record Loading

  private static func loadRecords<S: ContentStorage>(
    from storage: S,
    documentType: IWorkDocument.DocumentType,
    prefix: String
  ) throws -> [UInt64: SwiftProtobuf.Message] {
    var records: [UInt64: SwiftProtobuf.Message] = [:]
    let iwaPaths = storage.paths(with: ".iwa").filter { $0.hasPrefix(prefix) }

    for path in iwaPaths {
      let data = try storage.readData(from: path)
      guard !data.isEmpty else {
        throw IWorkError.archiveReadFailed(entry: path)
      }
      try loadIWA(data, into: &records, documentType: documentType, mergingOnly: false)
    }

    for path in iwaPaths {
      let data = try storage.readData(from: path)
      guard !data.isEmpty else {
        throw IWorkError.archiveReadFailed(entry: path)
      }
      try loadIWA(data, into: &records, documentType: documentType, mergingOnly: true)
    }

    return records
  }

  private static func loadIWA(
    _ data: Data,
    into records: inout [UInt64: SwiftProtobuf.Message],
    documentType: IWorkDocument.DocumentType,
    mergingOnly: Bool = false
  ) throws {
    let decompressed = try decompressIWA(data)

    var offset = 0
    while offset < decompressed.count {
      guard let (length, bytesRead) = readVarint(from: decompressed, at: offset) else {
        break
      }
      offset += bytesRead

      guard offset + length <= decompressed.count else {
        throw IWorkError.invalidArchiveStructure(
          reason: "ArchiveInfo chunk length exceeds data bounds.")
      }

      let chunk = decompressed.subdata(in: offset..<offset + length)
      offset += length

      let archiveInfo = try TSP_ArchiveInfo(serializedBytes: chunk)

      if mergingOnly != archiveInfo.shouldMerge {
        for messageInfo in archiveInfo.messageInfos {
          guard messageInfo.hasLength else { continue }
          let payloadLength = Int(messageInfo.length)
          guard offset + payloadLength <= decompressed.count else {
            throw IWorkError.invalidArchiveStructure(
              reason: "Message payload length exceeds data bounds.")
          }
          offset += payloadLength
        }
        continue
      }

      for messageInfo in archiveInfo.messageInfos {
        guard messageInfo.hasLength else { continue }

        let payloadLength = Int(messageInfo.length)
        guard offset + payloadLength <= decompressed.count else {
          throw IWorkError.invalidArchiveStructure(
            reason: "Message payload length exceeds data bounds.")
        }

        let payload = decompressed.subdata(in: offset..<offset + payloadLength)
        offset += payloadLength

        guard archiveInfo.hasIdentifier, messageInfo.hasType else { continue }

        let identifier = archiveInfo.identifier

        if archiveInfo.shouldMerge {
          if var existingMessage = records[identifier] {
            do {
              try existingMessage.merge(serializedBytes: payload)
              records[identifier] = existingMessage
            } catch {
              print("Failed to merge payload for id \(identifier): \(error)")
            }
          } else {
            if let decoded = decodePayload(
              payload,
              identifier: identifier,
              type: messageInfo.type,
              documentType: documentType
            ) {
              records[identifier] = decoded
            } else {
              print(
                "Failed to decode (should merge) payload for id \(identifier) of type \(messageInfo.type)"
              )
            }
          }
        } else {
          if let decoded = decodePayload(
            payload,
            identifier: identifier,
            type: messageInfo.type,
            documentType: documentType
          ) {
            records[identifier] = decoded
          } else {
            print("Failed to decode payload for id \(identifier) of type \(messageInfo.type)")
          }
        }
      }
    }
  }

  // MARK: - IWA Decompression

  /// LZFSE block magics. Apple's LZFSE framing uses these little-endian 4-byte markers;
  /// `bvxn` is the LZVN compressed-block header and `bvx$` closes the stream.
  /// Creator Studio–era writers emit some IWAs (e.g. `OperationStorage.iwa`) in this framing
  /// instead of the classic `0x00 | len24 | snappy-chunk` repeating structure.
  private static let lzfseMagicBvxn: [UInt8] = [0x62, 0x76, 0x78, 0x6E]

  private static func decompressIWA(_ data: Data) throws -> Data {
    guard data.count >= 4 else {
      throw IWorkError.invalidArchiveStructure(reason: "IWA file too small to contain a header.")
    }

    if data.starts(with: Self.lzfseMagicBvxn) {
      return try decompressLZFSE(data)
    }

    return try decompressSnappyChunks(data)
  }

  /// Decompresses a full LZFSE-framed IWA stream via the OS `Compression` framework.
  /// The framework consumes the entire stream (all `bvxn`/`bvx-`/… blocks and the `bvx$`
  /// terminator); we only need to size the scratch buffer from the first block's
  /// `n_raw_bytes` field, which matches the total uncompressed size in practice.
  private static func decompressLZFSE(_ data: Data) throws -> Data {
    let rawSize = data.withUnsafeBytes { ptr -> Int in
      Int(ptr.loadUnaligned(fromByteOffset: 4, as: UInt32.self))
    }
    guard rawSize > 0 else {
      throw IWorkError.invalidArchiveStructure(reason: "LZFSE header reports zero raw bytes.")
    }

    var dst = [UInt8](repeating: 0, count: rawSize)
    let written = data.withUnsafeBytes { srcPtr -> Int in
      guard let srcBase = srcPtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
      return compression_decode_buffer(
        &dst, rawSize,
        srcBase, data.count,
        nil, COMPRESSION_LZFSE
      )
    }

    guard written > 0 else {
      throw IWorkError.snappyDecompressionFailed
    }
    return Data(bytes: dst, count: written)
  }

  private static func decompressSnappyChunks(_ data: Data) throws -> Data {
    var result = Data()
    var offset = 0

    while offset < data.count {
      guard offset < data.count else { break }
      let headerType = data[offset]
      guard headerType == 0 else {
        throw IWorkError.invalidIWAHeader(expected: 0, found: headerType)
      }
      offset += 1

      guard offset + 3 <= data.count else {
        throw IWorkError.invalidArchiveStructure(reason: "Insufficient data for chunk length.")
      }

      let length =
        Int(data[offset])
        | (Int(data[offset + 1]) << 8)
        | (Int(data[offset + 2]) << 16)
      offset += 3

      guard offset + length <= data.count else {
        throw IWorkError.invalidArchiveStructure(reason: "Insufficient data for compressed chunk.")
      }

      let compressedChunk = data.subdata(in: offset..<offset + length)
      offset += length

      let decompressed = try decompressSnappy(type: headerType, data: compressedChunk)
      result.append(decompressed)
    }

    return result
  }

  private static func decompressSnappy(type: UInt8, data: Data) throws -> Data {
    if type != 0 {
      throw IWorkError.snappyDecompressionFailed
    }

    var offset = 0

    guard let (uncompressedSize, bytesRead) = readVarint(from: data, at: offset) else {
      throw IWorkError.snappyDecompressionFailed
    }
    offset = bytesRead

    var chunks: [Data] = []

    while offset < data.count {
      let tag = data[offset] & 0x3

      if tag == 0 {
        var len = Int(data[offset] >> 2)
        offset += 1

        if len < 60 {
          len += 1
        } else {
          let c = len - 59
          len = Int(data[offset])
          if c > 1 { len |= Int(data[offset + 1]) << 8 }
          if c > 2 { len |= Int(data[offset + 2]) << 16 }
          if c > 3 { len |= Int(data[offset + 3]) << 24 }
          len += 1
          offset += c
        }

        guard offset + len <= data.count else {
          throw IWorkError.snappyDecompressionFailed
        }

        chunks.append(data.subdata(in: offset..<offset + len))
        offset += len
      } else {
        var copyOffset = 0
        var length = 0

        if tag == 1 {
          length = Int((data[offset] >> 2) & 0x7) + 4
          copyOffset = Int(data[offset] & 0xE0) << 3
          offset += 1
          guard offset < data.count else {
            throw IWorkError.snappyDecompressionFailed
          }
          copyOffset |= Int(data[offset])
          offset += 1
        } else {
          length = Int(data[offset] >> 2) + 1
          offset += 1
          if tag == 2 {
            guard offset + 2 <= data.count else {
              throw IWorkError.snappyDecompressionFailed
            }
            copyOffset = Int(data[offset]) | (Int(data[offset + 1]) << 8)
            offset += 2
          } else {
            guard offset + 4 <= data.count else {
              throw IWorkError.snappyDecompressionFailed
            }
            copyOffset =
              Int(data[offset]) | (Int(data[offset + 1]) << 8) | (Int(data[offset + 2]) << 16)
              | (Int(data[offset + 3]) << 24)
            offset += 4
          }
        }

        if copyOffset == 0 {
          throw IWorkError.snappyDecompressionFailed
        }

        var j = chunks.count - 1
        var off = copyOffset

        while j >= 0 && off >= chunks[j].count {
          off -= chunks[j].count
          j -= 1
        }

        if j < 0 {
          if off == 0 {
            off = chunks[0].count
            j = 0
          } else {
            throw IWorkError.snappyDecompressionFailed
          }
        }

        if length < off {
          let start = chunks[j].count - off
          chunks.append(chunks[j].subdata(in: start..<start + length))
        } else {
          if off > 0 {
            let start = chunks[j].count - off
            chunks.append(chunks[j].subdata(in: start..<chunks[j].count))
            length -= off
          }
          j += 1

          while j < chunks.count && length >= chunks[j].count {
            chunks.append(chunks[j])
            length -= chunks[j].count
            j += 1
          }

          if length > 0 && j < chunks.count {
            chunks.append(chunks[j].subdata(in: 0..<length))
          }
        }

        if chunks.count > 25 {
          var merged = Data()
          for chunk in chunks {
            merged.append(chunk)
          }
          chunks = [merged]
        }
      }
    }

    var result = Data()
    for chunk in chunks {
      result.append(chunk)
    }

    if result.count != uncompressedSize {
      throw IWorkError.snappyDecompressionFailed
    }

    return result
  }

  // MARK: - Utility Methods

  private static func readVarint(from data: Data, at offset: Int) -> (value: Int, bytesRead: Int)? {
    var value = 0
    var shift = 0
    var bytesRead = 0

    while offset + bytesRead < data.count {
      let byte = data[offset + bytesRead]
      bytesRead += 1

      value |= Int(byte & 0x7F) << shift

      if (byte & 0x80) == 0 {
        return (value, bytesRead)
      }

      shift += 7

      guard bytesRead <= 10 else { return nil }
    }

    return nil
  }

  private static func decodePayload(
    _ payload: Data,
    identifier: UInt64,
    type: UInt32,
    documentType: IWorkDocument.DocumentType
  ) -> SwiftProtobuf.Message? {
    do {
      switch documentType {
      case .pages:
        return try decodePages(type: type, data: payload)
      case .numbers:
        return try decodeNumbers(type: type, data: payload)
      case .keynote:
        return try decodeKeynote(type: type, data: payload)
      }
    } catch {
      return nil
    }
  }
}
