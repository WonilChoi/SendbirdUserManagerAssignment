//
//  UserResponse.swift
//  
//
//  Created by 최원일 on 2024/08/05.
//

import Foundation

// API 연동 데이터
public struct UserResponse: Decodable {
    public var userId: String?
    public var nickname: String?
    public var profileURL: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname = "nickname"
        case profileURL = "profile_url"
    }
}
