//
//  String+NilIfEmpty.swift
//  WoodBox
//
//  Created by Alexander Hyde on 21/2/2026.
//

extension String {
  /// Returns `nil` if the string is empty, otherwise returns `self`.
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}

extension String? {
  /// Returns `nil` if the string is nil or empty, otherwise returns the wrapped value.
  var nilIfEmpty: String? {
    self?.nilIfEmpty
  }
}
