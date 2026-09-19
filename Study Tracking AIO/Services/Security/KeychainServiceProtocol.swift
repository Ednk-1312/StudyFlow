//
//  KeychainServiceProtocol.swift
//  StudyOS
//

import Foundation

public protocol KeychainServiceProtocol: Sendable {
    func save(key: String, data: Data) -> Bool
    func save(key: String, string: String) -> Bool
    func retrieveData(key: String) -> Data?
    func retrieveString(key: String) -> String?
    func delete(key: String) -> Bool
    func clearAll() -> Bool
}
