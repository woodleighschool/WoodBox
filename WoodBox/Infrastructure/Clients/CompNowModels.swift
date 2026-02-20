//
//  CompNowModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: - Ticket Request/Response

struct CompNowTicket: Encodable, Sendable {
  let endUser: String
  let product: String
  let serial: String
  let firstName: String
  let lastName: String
  let address1: String
  let suburb: String
  let state: String
  let postcode: String
  let email: String
  let phone: String
  let stockCode: String?
  let extras: String?
  let fault: String?
  let condition: String?
  let reference: String?
}

struct CompNowTicketCreateResponse: Decodable, Sendable {
  let message: String
  let ticket: CompNowTicketResult
}

struct CompNowTicketResult: Decodable, Sendable {
  let ticketId: String
}
