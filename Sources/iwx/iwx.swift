import ArgumentParser
import Foundation
import WorkKit

@main
@available(macOS 12, iOS 15, visionOS 1, tvOS 15, watchOS 8, *)
struct IWX: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iwx",
        abstract: "Convert iWork documents to Markdown or debug text format."
    )

    @Argument(help: "Path to the iWork document (.pages, .numbers, or .key).")
    var inputPath: String

    @Option(name: [.short, .long], help: "Output format: 'markdown' or 'debug'.")
    var format: OutputFormat = .markdown

    @Option(name: [.short, .long], help: "Output directory for converted files and assets.")
    var output: String?

    @Flag(name: .long, help: "Exclude slide/sheet titles from output.")
    var noTitles = false

    @Flag(name: .long, help: "Enable OCR for text recognition in images.")
    var ocr = false

    @Option(name: .long, help: "OCR recognition languages (comma-separated, e.g., 'en-US,es-ES').")
    var ocrLanguages: String?

    enum OutputFormat: String, ExpressibleByArgument {
        case markdown
        case debug
    }

    mutating func run() async throws {
        let inputURL = URL(fileURLWithPath: inputPath)
        let document = try IWorkDocument(url: inputURL)
        let outputDir = output ?? FileManager.default.currentDirectoryPath

        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: outputDir),
            withIntermediateDirectories: true
        )

        let baseFilename = inputURL.deletingPathExtension().lastPathComponent

        if ocr {
            let languages =
                ocrLanguages?
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty } ?? []
            let provider = VisionOCRProvider(recognitionLanguages: languages)
            try await convert(document: document, ocrProvider: provider, baseFilename: baseFilename, outputDir: outputDir)
        } else {
            try await convert(document: document, baseFilename: baseFilename, outputDir: outputDir)
        }
    }

    private func convert(
        document: IWorkDocument,
        ocrProvider: VisionOCRProvider,
        baseFilename: String,
        outputDir: String
    ) async throws {
        let outputURL: URL
        switch format {
        case .markdown:
            let config = MarkdownVisitor<VisionOCRProvider>.Configuration(
                outputDirectory: outputDir,
                includeSlideSheetTitles: !noTitles
            )
            let visitor = MarkdownVisitor(
                using: document,
                configuration: config,
                with: ocrProvider
            )
            try await visitor.accept()
            outputURL = URL(fileURLWithPath: outputDir).appendingPathComponent("\(baseFilename).md")
            try visitor.markdown.write(to: outputURL, atomically: true, encoding: .utf8)

        case .debug:
            let visitor = DebugTextExtractor(using: document, with: ocrProvider)
            try await visitor.accept()
            outputURL = URL(fileURLWithPath: outputDir).appendingPathComponent("\(baseFilename).txt")
            try visitor.text.write(to: outputURL, atomically: true, encoding: .utf8)
        }
        print("Converted: \(outputURL.path)")
    }

    private func convert(
        document: IWorkDocument,
        baseFilename: String,
        outputDir: String
    ) async throws {
        let outputURL: URL
        switch format {
        case .markdown:
            let config = MarkdownVisitor<NullOCRProvider>.Configuration(
                outputDirectory: outputDir,
                includeSlideSheetTitles: !noTitles
            )
            let visitor = MarkdownVisitor<NullOCRProvider>(
                using: document,
                configuration: config
            )
            try await visitor.accept()
            outputURL = URL(fileURLWithPath: outputDir).appendingPathComponent("\(baseFilename).md")
            try visitor.markdown.write(to: outputURL, atomically: true, encoding: .utf8)

        case .debug:
            let visitor = DebugTextExtractor<NullOCRProvider>(using: document)
            try await visitor.accept()
            outputURL = URL(fileURLWithPath: outputDir).appendingPathComponent("\(baseFilename).txt")
            try visitor.text.write(to: outputURL, atomically: true, encoding: .utf8)
        }
        print("Converted: \(outputURL.path)")
    }
}
