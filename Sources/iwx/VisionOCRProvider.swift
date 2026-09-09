import CoreGraphics
import Foundation
import Vision
import WorkKit

#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

/// Provides optical character recognition using Apple's Vision framework.
public struct VisionOCRProvider: OCRProvider {

  private let recognitionLanguages: [String]
  private let usesLanguageCorrection: Bool

  /// Creates a new Vision OCR provider.
  ///
  /// - Parameters:
  ///   - recognitionLanguages: Languages to use for text recognition. If empty,
  ///     uses all supported languages.
  ///   - usesLanguageCorrection: Whether to apply language correction during
  ///     recognition.
  public init(
    recognitionLanguages: [String] = [],
    usesLanguageCorrection: Bool = true
  ) {
    self.recognitionLanguages = recognitionLanguages
    self.usesLanguageCorrection = usesLanguageCorrection
  }

  public func recognizeText(
    in imageData: Data,
    info: ImageInfo
  ) async throws -> OCRResult {
    guard let cgImage = createCGImage(from: imageData) else {
      print(" Failed to create CGImage from image data.")
      throw OCRProviderError.imageConversionFailed
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = usesLanguageCorrection
    request.minimumTextHeight = 0.01

    if !recognitionLanguages.isEmpty {
      request.recognitionLanguages = recognitionLanguages
    }

    if #available(macOS 13, iOS 16, *) {
      request.revision = VNRecognizeTextRequestRevision3
    } else if #available(iOS 14, *) {
      request.revision = VNRecognizeTextRequestRevision2
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])

    guard let observations = request.results else {
      return OCRResult(text: "", observations: [])
    }

    let textObservations = observations.compactMap { observation -> WorkKit.TextObservation? in
      guard let candidate = observation.topCandidates(1).first else {
        return nil
      }

      let boundingQuad = BoundingQuad(
        topLeft: normalizePoint(observation.topLeft),
        topRight: normalizePoint(observation.topRight),
        bottomLeft: normalizePoint(observation.bottomLeft),
        bottomRight: normalizePoint(observation.bottomRight)
      )

      return TextObservation(
        text: candidate.string,
        confidence: Double(observation.confidence),
        boundingQuad: boundingQuad
      )
    }

    let fullText = textObservations.map { $0.text }.joined(separator: "\n")

    return OCRResult(text: fullText, observations: textObservations)
  }

  private func createCGImage(from data: Data) -> CGImage? {
    #if canImport(AppKit)
      guard let nsImage = NSImage(data: data) else {
        return nil
      }
      var proposedRect = CGRect.zero
      guard
        let cgImage = nsImage.cgImage(
          forProposedRect: &proposedRect,
          context: nil,
          hints: nil
        )
      else {
        return nil
      }
      return cgImage
    #elseif canImport(UIKit)
      guard let uiImage = UIImage(data: data),
        let cgImage = uiImage.cgImage
      else {
        return nil
      }
      return cgImage
    #else
      return nil
    #endif
  }

  private func normalizePoint(_ point: CGPoint) -> BoundingQuad.Point {
    BoundingQuad.Point(
      x: max(0, min(1, Double(point.x))),
      y: max(0, min(1, Double(1 - point.y)))
    )
  }
}

/// Errors that can occur during OCR processing.
public enum OCRProviderError: Error {
  case imageConversionFailed
}
