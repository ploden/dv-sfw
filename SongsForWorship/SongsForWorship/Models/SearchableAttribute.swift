//
//  SearchableAttribute.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/1/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

/// A type that represents the category of a SearchableAttribute
public enum SearchableAttributeType {
    case title
    case songNumber
    case tuneName
    case tuneMeter
    case stanzas
    case undefined
}

/// A type that represents the priority of a SearchableAttribute
public enum SearchableAttributePriority {
    case low
    case high
    case highest
    case undefined
}

extension SearchableAttributePriority: Comparable {
    
}

/// A type that represents a searchable value from a Song
public struct SearchableAttribute {
    let type: SearchableAttributeType
    let priority: SearchableAttributePriority
    let attribute: String
    
    public init(type: SearchableAttributeType, priority: SearchableAttributePriority, attribute: String) {
        self.type = type
        self.priority = priority
        self.attribute = attribute
    }
}
