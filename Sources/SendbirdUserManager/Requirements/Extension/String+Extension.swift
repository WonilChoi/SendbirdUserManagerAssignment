//
//  String+Extension.swift
//
//
//  Created by 최원일 on 8/10/24.
//

import Foundation

extension String {
    
    var addingPercentEncoding: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
