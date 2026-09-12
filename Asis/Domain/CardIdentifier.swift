import Foundation

/// Formats the identifier bytes returned by Core NFC, without interpreting a balance.
///
/// Identifiers have variable lengths and each byte must retain its leading zero.
/// Example: `CardIdentifier.hex(Data([0, 1, 255]))` returns `"0001FF"`.
enum CardIdentifier {
    /// Returns hexadecimal identifier text for display and storage.
    /// - Parameter data: Raw tag identifier bytes, in the order supplied by Core NFC.
    /// - Returns: An empty string for empty input. This operation does not throw.
    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined()
    }
}
