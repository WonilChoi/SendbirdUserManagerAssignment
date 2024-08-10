//
//  Cacheble.swift
//
//
//  Created by 최원일 on 2024/08/06.
//

import Foundation

/// Cache 구현를 위한 interface입니다.
public protocol Cacheble {
    associatedtype Key
    associatedtype Value
    
    /// 데이터를 저장하는 메소드
    /// insert하는 데이터가 존재한다면, update하는 역할을 합니다.
    /// - Parameters:
    ///    - value: 저장하는 데이터 type
    ///    - key: Key
    func insert(_ value: Value?, forKey key: Key)
    /// Key로부터 데이터를 삭제하고, 삭제한 데이터를 리턴해주는 메소드
    /// - Parameters:
    ///    - key: Key
    func remove(forKey key: Key) -> Value?
    /// Key로부터 가져오고, 해당하는 데이터가 없는 경우 nil을 반환하는 메소드
    /// - Parameters:
    ///    - key: Key
    func value(forKey key: Key) -> Value?
    /// 저장되어 있는 모든 데이터(Value Type)를 반환하는 메소드
    var allValues: [Value] { get }
    /// 저장되어 있는 모든 데이터(Key, Value Type)를 제거하는 메소드
    func removeAll()
}
