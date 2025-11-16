//
//  KeychainServiceTests.swift
//  MeetRecTests
//
//  Created by Kiro on 11/17/25.
//

import Testing
@testable import MeetRec

struct KeychainServiceTests {
    
    @Test func testSaveAndRetrieveAPIKey() throws {
        let keychain = KeychainService.shared
        let testKey = "test_api_key"
        let testValue = "sk-test123456789"
        
        // Clean up any existing value
        try? keychain.delete(key: testKey)
        
        // Save the API key
        try keychain.save(key: testKey, value: testValue)
        
        // Retrieve the API key
        let retrieved = try keychain.retrieve(key: testKey)
        
        // Verify
        #expect(retrieved == testValue)
        
        // Clean up
        try keychain.delete(key: testKey)
    }
    
    @Test func testKeyExists() throws {
        let keychain = KeychainService.shared
        let testKey = "test_exists_key"
        let testValue = "test_value"
        
        // Clean up any existing value
        try? keychain.delete(key: testKey)
        
        // Should not exist initially
        #expect(!keychain.exists(key: testKey))
        
        // Save the key
        try keychain.save(key: testKey, value: testValue)
        
        // Should exist now
        #expect(keychain.exists(key: testKey))
        
        // Clean up
        try keychain.delete(key: testKey)
        
        // Should not exist after deletion
        #expect(!keychain.exists(key: testKey))
    }
    
    @Test func testRetrieveNonExistentKey() throws {
        let keychain = KeychainService.shared
        let testKey = "non_existent_key"
        
        // Clean up any existing value
        try? keychain.delete(key: testKey)
        
        // Should throw itemNotFound error
        #expect(throws: KeychainError.self) {
            try keychain.retrieve(key: testKey)
        }
    }
}
