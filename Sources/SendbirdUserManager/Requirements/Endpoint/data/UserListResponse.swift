//
//  UserListResponse.swift
//
//
//  Created by 최원일 on 2024/08/05.
//

import Foundation

// API 연동 데이터
public struct UserListResponse: Decodable {
    let users: [UserResponse]?
    let next: String?
}
