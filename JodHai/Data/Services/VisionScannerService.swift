import Vision
import UIKit
import Foundation

// Conforms to ReceiptScannerProtocol from the Domain layer.
// Actor isolation keeps Vision callbacks off the main thread safely.
actor VisionScannerService: ReceiptScannerProtocol {

    func scan(imageData: Data) async throws -> ReceiptData {
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            throw ReceiptScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: Self.parseReceipt(from: observations))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["th-TH", "en-US"]

            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Parsing

    private static func parseReceipt(from observations: [VNRecognizedTextObservation]) -> ReceiptData {
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return ReceiptData(
            amount: extractAmount(from: lines),
            vendor: extractVendor(from: lines),
            date: nil
        )
    }

    private static func extractAmount(from lines: [String]) -> Double? {
        // Thai and English keywords that signal a total line
        let totalKeywords = [
            "total", "grand total", "amount due", "net amount",
            "ยอดรวม", "ยอดชำระ", "รวมทั้งสิ้น", "รวมเงิน", "รวม"
        ]

        // Pass 1 — look for a number on or just after a "total" keyword line
        for (idx, line) in lines.enumerated() {
            let lower = line.lowercased()
            guard totalKeywords.contains(where: { lower.contains($0) }) else { continue }
            if let amount = parseNumber(from: line) { return amount }
            if idx + 1 < lines.count, let amount = parseNumber(from: lines[idx + 1]) { return amount }
        }

        // Pass 2 — fall back to the largest number in the entire document
        return lines.compactMap { parseNumber(from: $0) }.max()
    }

    /// Returns the largest positive number found in `text`, stripping common
    /// currency symbols and thousands separators first.
    private static func parseNumber(from text: String) -> Double? {
        let stripped = text
            .replacingOccurrences(of: "฿", with: " ")
            .replacingOccurrences(of: "THB", with: " ", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: " ")
            .replacingOccurrences(of: "€", with: " ")

        // Matches "1,234.56", "1234.56", "1234"
        let pattern = #"(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let ns = stripped as NSString
        return regex
            .matches(in: stripped, range: NSRange(location: 0, length: ns.length))
            .compactMap { match -> Double? in
                guard let range = Range(match.range, in: stripped) else { return nil }
                let clean = String(stripped[range]).replacingOccurrences(of: ",", with: "")
                guard let value = Double(clean), value > 0 else { return nil }
                return value
            }
            .max()
    }

    /// Heuristic vendor name: first text line that starts with a letter and is
    /// long enough to be a business name.
    private static func extractVendor(from lines: [String]) -> String? {
        lines.first { line in
            line.count > 3 && line.first?.isLetter == true
        }
    }
}

// MARK: - Error

enum ReceiptScanError: Error, LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "Could not read the image. Please try a clearer photo."
    }
}
