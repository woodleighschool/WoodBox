//
//  IntegrationError.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import Foundation

struct IntegrationError: LocalizedError, Sendable {
  // MARK: - Properties

  let action: String
  let integration: String
  let statusCode: Int?

  // MARK: - LocalizedError

  var errorDescription: String? {
    let statusText =
      if let statusCode {
        "\(Self.statusLabel(for: statusCode)) (\(statusCode))"
      } else {
        "Unknown error"
      }
    return "Failed to \(action) via \(integration): \(statusText)"
  }

  // MARK: - Private Helpers

  private static func statusLabel(for code: Int) -> String {
    switch code {
    case 400: return "Client Error (Bad Request)"
    case 401: return "Authentication Failed"
    case 403: return "Forbidden"
    case 404: return "Not Found"
    case 429: return "Rate Limited"
    case 500: return "Server Error"
    default:
      let text = HTTPURLResponse.localizedString(forStatusCode: code)
      return text.isEmpty ? "HTTP \(code)" : text.capitalized
    }
  }
}
