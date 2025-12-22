//
//  Friend.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

struct Friend: Decodable {
    let name: String
    let status: Int
    let isTop: String
    let fid: String
    let updateDate: String
}
