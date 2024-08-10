//
//  SendbirdUserManagerTests.swift
//  SendbirdUserManagerTests
//
//  Created by Sendbird
//

import XCTest
@testable import SendbirdUserManager

final class UserManagerTests: UserManagerBaseTests {
    override func userManager() -> SBUserManager {
        let networkClient = SBNetworkClientImpl(headers: ["Api-Token": Constants.token,
                                                          "Accept": "application/json"],
                                                appID: Constants.appID)
        let storage = SBUserStorageImpl(cache: LRUCache(capacity: 10))
        return SBUserManagerImpl(networkClient: networkClient, userStorage: storage)
    }
}

final class UserStorageTests: UserStorageBaseTests {
    override func userStorage() -> SBUserStorage? {
        SBUserStorageImpl(cache: LRUCache(capacity: 10))
    }
}

//final class NetworkClientTests: NetworkClientBaseTests {
//    override func networkClient() -> SBNetworkClient? {
//        MockNetworkClient()
//    }
//}
