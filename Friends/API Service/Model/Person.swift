//
//  Person.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

struct Person: Decodable {
    let name: String
    let kokoid: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case kokoid
        case response
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var responseArray = try? container.nestedUnkeyedContainer(forKey: .response)
        let personContainer = try? responseArray?.nestedContainer(keyedBy: CodingKeys.self)
        
        name = try personContainer?.decode(String.self, forKey: .name) ?? container.decode(String.self, forKey: .name)
        kokoid = try personContainer?.decode(String.self, forKey: .kokoid) ?? container.decode(String.self, forKey: .kokoid)
    }
}
