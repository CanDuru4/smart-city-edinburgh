import Foundation

/// Names of the local NOVUS-RT configuration entries. These constants contain no credentials.
/// Example: `JourneoConfigurationKey.apiKey` identifies a value in Keys.plist.
public enum JourneoConfigurationKey {
    public static let baseURL = "JourneoAPIBaseURL"
    public static let headerName = "JourneoAPIKeyHeaderName"
    public static let apiKey = "JourneoAPIKey"
    public static let secondaryKey = "JourneoAPIKeySecondary"
}

/// Fail-closed configuration errors that never carry credential values.
/// Example: `JourneoConfigurationError.missingValue(JourneoConfigurationKey.apiKey)`.
public enum JourneoConfigurationError: Error, Equatable {
    case fileMissing
    case unreadable
    case missingValue(String)
    case emptyValue(String)
    case insecureBaseURL
    case invalidHeaderName
}

/// Validated, immutable NOVUS-RT configuration, independent of TransitAPIBaseURL.
/// Construction is restricted to the resolver so request builders cannot receive partial configuration.
/// Descriptions omit all configured values, including potentially sensitive URL paths.
/// Example: `try JourneoConfiguration.resolve()`.
public struct JourneoConfiguration: CustomStringConvertible, CustomDebugStringConvertible {
    public let baseURL: URL
    public let headerName: String
    public let apiKey: String
    public let secondaryKey: String?

    public var description: String { "JourneoConfiguration(<redacted>)" }
    public var debugDescription: String { description }

    private init(baseURL: URL, headerName: String, apiKey: String, secondaryKey: String?) {
        self.baseURL = baseURL
        self.headerName = headerName
        self.apiKey = apiKey
        self.secondaryKey = secondaryKey
    }

    /// Resolves a plist with no default endpoint, header, or credentials.
    /// Blank optional keys fail if present; omit the secondary entry when it is unused.
    /// URL credentials, queries, and fragments are rejected to keep authentication in the header.
    /// Header values containing control characters are rejected before any request can be made.
    /// - Parameters:
    ///   - plistData: Contents of Keys.plist, or nil if the file is absent.
    /// - Returns: Complete, trimmed configuration.
    /// - Throws: JourneoConfigurationError for missing, unreadable, or invalid configuration.
    /// Example: `try JourneoConfiguration.resolve(plistData: data)`.
    public static func resolve(plistData: Data?) throws -> JourneoConfiguration {
        guard let plistData else { throw JourneoConfigurationError.fileMissing }
        let values: [String: Any]
        do {
            guard let dictionary = try PropertyListSerialization.propertyList(
                from: plistData, options: [], format: nil
            ) as? [String: Any] else { throw JourneoConfigurationError.unreadable }
            values = dictionary
        } catch {
            throw JourneoConfigurationError.unreadable
        }

        func value(_ key: String) throws -> String {
            guard let raw = values[key] else { throw JourneoConfigurationError.missingValue(key) }
            guard let string = raw as? String else { throw JourneoConfigurationError.unreadable }
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw JourneoConfigurationError.emptyValue(key) }
            return trimmed
        }

        let base = try value(JourneoConfigurationKey.baseURL)
        guard let components = URLComponents(string: base),
              components.scheme == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              components.port.map({ (1...65535).contains($0) }) ?? true,
              let baseURL = components.url else {
            throw JourneoConfigurationError.insecureBaseURL
        }
        let header = try value(JourneoConfigurationKey.headerName)
        let token = CharacterSet(charactersIn: "!#$%&'*+-.^_`|~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        let rawHeader = values[JourneoConfigurationKey.headerName] as? String ?? ""
        let reserved = ["accept", "host", "content-length", "content-type", "connection", "transfer-encoding"]
        guard header.unicodeScalars.allSatisfy(token.contains),
              !rawHeader.contains("\r"), !rawHeader.contains("\n"),
              !reserved.contains(header.lowercased()) else {
            throw JourneoConfigurationError.invalidHeaderName
        }
        let key = try value(JourneoConfigurationKey.apiKey)
        let secondary = try values[JourneoConfigurationKey.secondaryKey].map { _ in
            try value(JourneoConfigurationKey.secondaryKey)
        }
        guard [key, secondary].compactMap({ $0 }).allSatisfy({ value in
            value.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
        }) else { throw JourneoConfigurationError.unreadable }
        return JourneoConfiguration(baseURL: baseURL, headerName: header, apiKey: key, secondaryKey: secondary)
    }

    /// Reads the optional Keys.plist resource without consulting Info.plist or environment defaults.
    /// - Parameters:
    ///   - bundle: Bundle containing Keys.plist.
    /// - Returns: Validated configuration.
    /// - Throws: JourneoConfigurationError; file read errors are sanitized.
    /// Example: `try JourneoConfiguration.resolve(bundle: .main)`.
    public static func resolve(bundle: Bundle = .main) throws -> JourneoConfiguration {
        guard let url = bundle.url(forResource: "Keys", withExtension: "plist") else {
            throw JourneoConfigurationError.fileMissing
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JourneoConfigurationError.unreadable
        }
        return try resolve(plistData: data)
    }
}
