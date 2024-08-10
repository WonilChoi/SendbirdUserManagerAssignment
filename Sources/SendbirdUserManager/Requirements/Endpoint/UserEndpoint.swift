//
//  UserEndpoint.swift
//  
//
//  Created by 최원일 on 8/4/24.
//

import Foundation
import Alamofire

enum UserEndpoint<T: Decodable>: Requestable {
    typealias Response = T
    
    case createUser(params: UserCreationParams)
    case updateUser(params: UserUpdateParams)
    case getUser(userId: String)
    case getUsers(nicknameMatches: String, limit: String)
}

extension UserEndpoint: EndPointable {
  
    var baseURL: String {
        "https://api-%@.sendbird.com"
    }
    
    var path: String {
        switch self {
        case .getUser(let userId):
            "users/\(userId)"
        case .updateUser(let params):
            "users/\(params.userId)"
        default:
            "users"
        }
    }
    
    var version: String {
        "v3"
    }
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .createUser(_):
            .post
        case .updateUser(_):
            .put
        default:
            .get
        }
    }
    
    var queryParameters: [URLQueryItem] {
        switch self {
        case .getUser(let userId):
            var queryItems = [URLQueryItem]()
            queryItems.append(.init(name: "userId", value: userId))
            return queryItems
        case .getUsers(let nickname, let limit):
            var queryItems = [URLQueryItem]()
            queryItems.append(.init(name: "limit", value: limit))
            queryItems.append(.init(name: "nickname", value: nickname))
            return queryItems
        case .updateUser(let params):
            var queryItems = [URLQueryItem]()
            queryItems.append(.init(name: "userId", value: params.userId))
            return queryItems
        default:
            return []
        }
    }

    var task: HTTPTask {
        switch self {
        case .createUser(let user):
            let params: [String: Any] = [
                "user_id": user.userId,
                "nickname": user.nickname,
                "profile_url": user.profileURL ?? ""
            ]
            return .parameters(params)
        case .updateUser(let params):
            let params: [String: Any] = [
                "nickname": params.nickname ?? "",
                "profile_url": params.profileURL ?? ""
            ]
            return .parameters(params)
        default:
            return .plain
        }
    }
    
    var delay: Double {
        switch self {
        case .createUser(_):
            return 1.0
        default:
            return 0.0
        }
    }
}
