import Foundation

struct ReceiptData: Sendable {
    let amount: Double?
    let vendor: String?
    let date: Date?
}

protocol ReceiptScannerProtocol: Sendable {
    func scan(imageData: Data) async throws -> ReceiptData
}

struct ExtractReceiptDataUseCase: Sendable {
    let scanner: any ReceiptScannerProtocol

    func execute(imageData: Data) async throws -> ReceiptData {
        try await scanner.scan(imageData: imageData)
    }
}
