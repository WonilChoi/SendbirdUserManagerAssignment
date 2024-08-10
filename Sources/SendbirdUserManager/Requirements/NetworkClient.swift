//
//  NetworkClient.swift
//  
//
//  Created by Sendbird
//

import Foundation

public protocol Request {
    associatedtype Response: Decodable
}

// 기존 Request Protocol과 EndPoin Protocol을 결합
public protocol Requestable: Request, EndPointable { }

public protocol SBNetworkClient {
    /// 동적으로 appID, Header의 token이 변경되는 케이스를 위한 메소드입니다.
    func setAppID(appID: String)
    func setHeaders(headers: [String: String])
    /// 리퀘스트를 요청하고 리퀘스트에 대한 응답을 받아서 전달합니다
    func request<R: Requestable>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void)
}
