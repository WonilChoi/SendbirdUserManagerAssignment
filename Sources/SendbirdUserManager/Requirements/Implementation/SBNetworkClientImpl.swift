//
//  SBNetworkClientImpl.swift
//
//
//  Created by 최원일 on 8/4/24.
//

import Foundation
import Alamofire

class SBNetworkClientImpl: SBNetworkClient {
    // testInitApplicationWithDifferentAppIdClearsData 케이스처럼 createUser() 호출 후,
    // userStorage.getUsers() 호출하는 로직으로 동기화 처리.
    // async/await로 구현하기엔 interface까지 영향이 있으므로 semaphore로 구현.
    private let semaphore = DispatchSemaphore(value: 10)
    private let globalQueue = DispatchQueue.global(qos: .utility)
    private var headers: [String: String]
    private var appID: String
    
    init(headers: [String : String], appID: String) {
        self.headers = headers
        self.appID = appID
    }

    func setAppID(appID: String) {
        self.appID = appID
    }
    
    func setHeaders(headers: [String: String]) {
        self.headers = headers
    }
    
    func request<R>(request: R, completionHandler: @escaping (Result<R.Response, any Error>) -> Void) where R : Requestable {
        let targetURL = request.getTargetUrl(appID: self.appID)
        
        var parameters: [String: Any]?
        if case .parameters(let params) = request.task {
            parameters = params
        }
        
        let encoding: ParameterEncoding = {
            if request.method == .post || request.method == .put {
                return JSONEncoding.default
            }
            return URLEncoding.default
        }()
        
        AF.request(targetURL,
                   method: request.method,
                   parameters: parameters,
                   encoding: encoding,
                   headers: HTTPHeaders.init(self.headers))
        // 200~300 상태코드만 허용.
        .validate(statusCode: 200..<300)
        // SB 서버에서 error 데이터 형태
        //  {\"error\":true,\"message\":\"Invalid value: \\\"JSON body.\\\".\",\"code\":400403}"
        .responseDecodable(of: R.Response.self, queue: globalQueue) { response in
            switch response.result {
            case .success(let result):
                completionHandler(.success(result))
                
            case .failure(let error):
                if let underlyingError = error.underlyingError {
                    completionHandler(.failure(underlyingError))
                } else {
                    completionHandler(.failure(error))
                }
            }
            self.semaphore.signal()
        }
        self.semaphore.wait()
    }
}
