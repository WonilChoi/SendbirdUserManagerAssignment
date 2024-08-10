//
//  SBUserStorageImpl.swift
//
//
//  Created by 최원일 on 8/4/24.
//

import Foundation

class SBUserStorageImpl: SBUserStorage {
    
    private var cahce: LRUCache<String, SBUser>
    
    init(cache: LRUCache<String, SBUser>) {
        self.cahce = cache
    }
    
    func upsertUser(_ user: SBUser) {
        self.cahce.insert(user, forKey: user.userId)
    }
    
    func getUsers() -> [SBUser] {
        self.cahce.allValues
    }
    
    func getUsers(for nickname: String) -> [SBUser] {
        getUsers().filter { $0.nickname == nickname }
    }
    
    func getUser(for userId: String) -> (SBUser)? {
        guard let user = self.cahce.value(forKey: userId) else {
            return nil
        }
        return user
    }
    
    func removeAllUsers() {
        self.cahce.removeAll()
    }
}
