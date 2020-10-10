//
//  Composer.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/25/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct Composer {
    private var _fullName: String?
    public var fullName: String? {
        get {
            if let full = _fullName {
                return full
            } else if
                let first = self.firstName,
                let last = self.lastName
            {
                return "\(first) \(last)"
            }
            return nil
        }
        set (newFullname) {
            _fullName = newFullname
        }
    }
    public var lastName: String?
    public var firstName: String?
    public var collection: String?
    public var displayName: String? {
        get {
            if let fullName = fullName {
                return fullName
            } else {
                return collection
            }
        }
    }
    
    public init(fullName: String?, lastName: String?, firstName: String?, collection: String?) {
        self.fullName = fullName
        self.lastName = lastName
        self.firstName = firstName
        self.collection = collection
    }
    
}
