//
//  APIEndpoint.swift
//  Friends
//
//  Created by Jules on 2025/12/22.
//

import Foundation

enum APIEndpoint {
    case userProfile
    case friendsNoFriends
    case friendsWithInvitation
    case friendsList1
    case friendsList2

    var baseURL: String {
        return "https://dimanyen.github.io"
    }

    var path: String {
        switch self {
        case .userProfile:
            return "/man.json"
        case .friendsNoFriends:
            return "/friend4.json"
        case .friendsWithInvitation:
            return "/friend3.json"
        case .friendsList1:
            return "/friend1.json"
        case .friendsList2:
            return "/friend2.json"
        }
    }

    var urlString: String {
        return baseURL + path
    }

    var url: URL? {
        return URL(string: urlString)
    }
}
