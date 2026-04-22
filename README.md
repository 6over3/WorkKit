# WorkKit

A Swift package for parsing and extracting content from Apple iWork documents (Pages, Numbers, and Keynote). WorkKit provides a straightforward API to open iWork documents and traverse their content.

## Installation

Add WorkKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/6over3/WorkKit.git", from: "1.0.0")
]
```

## Usage

### Opening a Document

```swift
import WorkKit

let document = try IWorkDocument(url: URL(fileURLWithPath: "/path/to/document.pages"))
print("Document type: \(document.type)")
print("Format: \(document.format)")
```

### Extracting Content with a Visitor

Implement the `IWorkDocumentVisitor` protocol to process document content:

```swift
struct TextExtractor: IWorkDocumentVisitor {
    init(using document: IWorkDocument, with ocrProvider: OCRProvider?) {
        // Initialize with document
    }
    
    func accept() async throws {
        // Traverse document
    }
    
    func visitInlineElement(_ element: InlineElement) async {
        switch element {
        case .text(let text, let style, let hyperlink):
            print(text)
        case .image(let info, let spatialInfo, let ocrResult, let hyperlink):
            print("Image: \(info.filename ?? "unknown")")
        case .footnoteMarker(let footnote):
            print("Footnote #\(footnote.number)")
        default:
            break
        }
    }
    
    func willVisitTable(name: String?, rowCount: UInt32, columnCount: UInt32, spatialInfo: SpatialInfo) async {
        print("Table: \(name ?? "untitled") (\(rowCount)×\(columnCount))")
    }
    
    func visitTableCell(row: Int, column: Int, content: TableCellContent) async {
        switch content {
        case .text(let text, _):
            print("  [\(row),\(column)]: \(text)")
        case .number(let value, _):
            print("  [\(row),\(column)]: \(value)")
        default:
            break
        }
    }
}

let visitor = TextExtractor(using: document, with: nil)
try await visitor.accept()
```

### Accessing Previews

```swift
if let thumbnail = document.preview(.thumbnail) {
    let image = UIImage(data: thumbnail)
}

if let standard = document.preview(.standard) {
    let image = UIImage(data: standard)
}

// Get all available previews
let previews = document.allPreviews()
for (name, data) in previews {
    print("Preview: \(name)")
}
```

### Working with Metadata

```swift
if let properties = document.metadata.properties {
    print("Document UUID: \(properties.documentUUID ?? "unknown")")
    print("File format version: \(properties.fileFormatVersion ?? "unknown")")
}

print("Build history: \(document.metadata.buildVersionHistory)")
```

### OCR Integration

Provide an OCR provider to extract text from images:

```swift
struct MyOCRProvider: OCRProvider {
    func recognizeText(in imageData: Data, info: ImageInfo) async throws -> OCRResult {
        // Implement text recognition
    }
}

let ocrProvider = MyOCRProvider()
let visitor = MyVisitor(using: document, with: ocrProvider)
try await visitor.accept()
```

## License

GNU Affero General Public License 

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.