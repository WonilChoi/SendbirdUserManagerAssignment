//
//  LRUCache.swift
//
//
//  Created by 최원일 on 2024/08/06.
//

import Foundation

final class LRUCache<Key: Hashable, Value>: Cacheble {
   
    private let lock: NSLock = .init()
    private var entries: LinkedList<Key, Value>
    private var values: [Key : Node<Key, Value>]
    private var totalCount: Int = 0
    private var capacity: Int
    
    var allValues: [Value] {
        lock.lock()
        defer { lock.unlock() }
        
        var values: [Value] = .init()
        var next = entries.head
        while let node = next {
            values.append(node.value)
            next = node.next
        }
        return values
    }
    
    public init(capacity: Int = 10,
                notificationCenter: NotificationCenter = .default) {
        self.capacity = capacity
        self.entries = LinkedList()
        self.values = [Key: Node<Key, Value>](minimumCapacity: capacity)
    }

    func insert(_ value: Value?, forKey key: Key) {
        guard let value else {
            remove(forKey: key)
            return
        }
        
        lock.lock()
        if let node = values[key] {
            node.value = value
            totalCount -= 1
            
            entries.remove(node)
            entries.append(node)
        } else {
            let newNode = Node(key: key, value: value)
            if self.totalCount < self.capacity {
                self.totalCount += 1
            } else {
                if self.entries.tail != nil {
                    values.removeValue(forKey: self.entries.tail!.key)
                    self.entries.tail = self.entries.tail?.prev
                    self.entries.tail?.next = nil
                }
            }
            
            entries.append(newNode)
            values[key] = newNode
        }
        lock.unlock()
    }
    
    @discardableResult 
    func remove(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = values.removeValue(forKey: key) else {
            return nil
        }
        entries.remove(node)
        totalCount -= 1
        return node.value
    }
    
    func value(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        if let node = values[key] {
            self.entries.remove(node)
            self.entries.append(node)
            return node.value
        }
        return nil
    }
    
    func removeAll() {
        lock.lock()
        entries = LinkedList()
        values.removeAll()
        totalCount = 0
        lock.unlock()
    }
}

// MARK: sub class
extension LRUCache {
    
    final class Node<K, V> {
        unowned(unsafe) var next: Node?
        unowned(unsafe) var prev: Node?
        var key: K
        var value: V
        
        init(key: K, value: V) {
            self.key = key
            self.value = value
        }
    }
    
    final class LinkedList<K, V> {
        var head: Node<K, V>?
        var tail: Node<K, V>?
    
        /// add to Head
        func append(_ node: Node<K, V>) {
            if self.head == nil {
                self.head = node
                self.tail = node
            } else {
                let headTemp = self.head
                self.head?.prev = node
                self.head = node
                self.head?.next = headTemp
            }
        }
        
        func remove(_ node: Node<K, V>) {
            if self.head === node {
                if self.head?.next != nil {
                    self.head = self.head?.next
                    self.head?.prev = nil
                } else {
                    self.head = nil
                    self.tail = nil
                }
            } else if node.prev != nil {
                node.prev?.next = node.next
                node.next?.prev = node.prev
            } else {
                node.prev?.next = nil
                self.tail = node.prev
            }
        }
    }
}
