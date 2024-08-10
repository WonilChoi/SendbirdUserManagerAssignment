//
//  EndPointable.swift
//
//
//  Created by 최원일 on 2024/08/05.
//

import Foundation
import Alamofire

// Rquest를 위한 필요 protocol
public protocol EndPointable {
    var baseURL: String { get }
    var path: String { get }
    var version: String { get }
    var method: HTTPMethod { get }
    var queryParameters: [URLQueryItem] { get }
    var task: HTTPTask { get }
    var delay: Double { get }
}

extension EndPointable {
    // Request URL 생성
    func getTargetUrl(appID: String) -> String {
        let baseURLString = String(format: baseURL, appID).trimmingCharacters(in: .whitespacesAndNewlines)
        let pathString = "/\(version)/" + path
        var components = URLComponents(string: baseURLString)
        components?.path = pathString
        components?.queryItems = queryParameters
        
        guard let url = components?.url?.absoluteString, !queryParameters.isEmpty else {
            return baseURLString + pathString
        }
        
        return url.addingPercentEncoding
    }
}

public enum HTTPTask {
    /// parameter 없는 요청
    case plain
    /// parameter  request 요청
    case parameters([String: Any]?)
}
