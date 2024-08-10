//
//  SBUserManagerImpl.swift
//
//
//  Created by 최원일 on 8/4/24.
//

import Foundation

enum UserManageError: Error {
    case outOfRange(String)
    case failedCreateUser(userId: String, error: Error)
    case failedCreateUsers
    case notFoundUserID
    case failedUpdate(userId: String, error: Error)
    case failedGet(userId: String, error: Error)
    case failedGetList(error: Error)
    case emptyNickname
    case emptyUserID
}

class SBUserManagerImpl: SBUserManager {
    
    var networkClient: SBNetworkClient
    var userStorage: SBUserStorage
    private var applicationId: String = ""
    private var apiToken: String = ""
    private var throttleQueue = DispatchQueue(label: "Throttle", attributes: [])
    
    init(networkClient: SBNetworkClient, userStorage: SBUserStorage) {
        self.networkClient = networkClient
        self.userStorage = userStorage
    }
    
    func initApplication(applicationId: String, apiToken: String) {
        if self.applicationId != applicationId {
            self.userStorage.removeAllUsers()
        }
        self.applicationId = applicationId
        self.apiToken = apiToken
        
        self.networkClient.setAppID(appID: applicationId)
        self.networkClient.setHeaders(headers: ["Api-Token": apiToken, 
                                                "Accept": "application/json"])
    }
    
    func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
        let endPoint = UserEndpoint<UserResponse>.createUser(params: params)
        
        // create 1.0 delay 설정
        self.throttleQueue.asyncAfter(deadline: .now() + endPoint.delay) {
            self.networkClient.request(request: endPoint) { result in
                switch result {
                case .success(let response):
                    if let userId = response.userId {
                        let userResult = SBUser(userId: userId,
                                                nickname: response.nickname,
                                                profileURL: response.profileURL)
                        // storage 저장 및 completion.
                        self.userStorage.upsertUser(userResult)
                        completionHandler?(.success(userResult))
                    } else {
                        // userID가 없는 케이스는 없겠지만, 예외처리.
                        completionHandler?(.failure(UserManageError.notFoundUserID))
                    }
                case .failure(let error):
                    completionHandler?(.failure(UserManageError.failedCreateUser(userId: params.userId, error: error)))
                }
            }
        }
    }
    
    func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        /// Restriction: 10명 이상의 사용자를 만들 수 없다.
        if params.count < Constants.maximumCreateUsers {
            let fetchGroup = DispatchGroup()
            var succeedUsers: [SBUser] = []
            var failedUsers: [UserCreationParams] = []
            
            params.forEach { userCreationParams in
                fetchGroup.enter()
                
                self.createUser(params: userCreationParams) { result in
                    switch result {
                    case .success(let response):
                        // 요청한 params 순서대로 리스트 전달.
                        if let index = params.firstIndex(where: { $0.userId == response.userId }) {
                            if succeedUsers.isEmpty {
                                succeedUsers.append(response)
                            } else {
                                succeedUsers.insert(response, at: index)
                            }
                        }
                    case .failure(_):
                        // 요청 실패한 user params를 저장.
                        // 현재 UsersResult 인터페이스에는 성공하지 않은 유저 정보를 전달할 수 없음.
                        failedUsers.append(userCreationParams)
                    }
                    fetchGroup.leave()
                }
            }
            
            fetchGroup.notify(queue: .main) {
                if succeedUsers.count > 0 {
                    // create 성공한 사용자가 1명만 있으면, 성공으로 처리
                    completionHandler?(.success(succeedUsers))
                } else {
                    // succeedUsers 리스트가 0개라면 모두 실패로 간주하고 failuredCreateUsers error 전달.
                    completionHandler?(.failure(UserManageError.failedCreateUsers))
                }
            }
        } else {
            // 10명 이상의 경우 range error 전달.
            completionHandler?(.failure(UserManageError.outOfRange("Cannot create more than 10 users at once. Please split into groups less than 10 users")))
        }
    }
    
    func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        let endPoint = UserEndpoint<UserResponse>.updateUser(params: params)
        
        self.networkClient.request(request: endPoint) { result in
            switch result {
            case .success(let response):
                if let userId = response.userId {
                    let userResult = SBUser(userId: userId,
                                            nickname: response.nickname,
                                            profileURL: response.profileURL)
                    // storage 저장 및 completion.
                    self.userStorage.upsertUser(userResult)
                    completionHandler?(.success(userResult))
                } else {
                    // userID가 없는 케이스는 없겠지만, 예외처리.
                    completionHandler?(.failure(UserManageError.notFoundUserID))
                }
            case .failure(let error):
                completionHandler?(.failure(UserManageError.failedUpdate(userId: params.userId, error: error)))
            }
        }
    }
    
    func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        // userId가 유무 체크.
        guard !userId.isEmpty else {
            completionHandler?(.failure(UserManageError.emptyUserID))
            return
        }
        
        let endPoint = UserEndpoint<UserResponse>.getUser(userId: userId)
        self.networkClient.request(request: endPoint) { result in
            switch result {
            case .success(let response):
                if let userId = response.userId {
                    let userResult = SBUser(userId: userId,
                                            nickname: response.nickname,
                                            profileURL: response.profileURL)
                    // storage 저장 및 completion.
                    self.userStorage.upsertUser(userResult)
                    completionHandler?(.success(userResult))
                } else {
                    // userID가 없는 케이스는 없겠지만, 예외처리.
                    completionHandler?(.failure(UserManageError.notFoundUserID))
                }
            case .failure(let error):
                completionHandler?(.failure(UserManageError.failedGet(userId: userId, error: error)))
            }
        }
    }
    
    func getUsers(nicknameMatches: String, completionHandler: ((UsersResult) -> Void)?) {
        guard !nicknameMatches.isEmpty else {
            completionHandler?(.failure(UserManageError.emptyNickname))
            return
        }
        
        /// Restriction: limit는 100개 고정
        let endPoint = UserEndpoint<UserListResponse>.getUsers(nicknameMatches: nicknameMatches, limit: Constants.limit)
        self.networkClient.request(request: endPoint) { result in
            switch result {
            case .success(let response):
                var sbUserList: [SBUser] = []
                // nickname과 매칭되는 user 정보가 없는 경우에도 타입에 맞춰 sbUserList 빈 배열 전달.
                response.users?.forEach({ userResponse in
                    if let userId = userResponse.userId {
                        let userResult = SBUser(userId: userId,
                                                nickname: userResponse.nickname,
                                                profileURL: userResponse.profileURL)
                        // storage 저장 및 completion 전달할 리스트 구성.
                        self.userStorage.upsertUser(userResult)
                        sbUserList.append(userResult)
                    }
                })
                completionHandler?(.success(sbUserList))
                
            case .failure(let error):
                completionHandler?(.failure(UserManageError.failedGetList(error: error)))
            }
        }
    }
}
