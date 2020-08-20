//
//  Topic.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/11/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation

struct Topic {
  var topic: String
  var songNumbers: [String]
  var subtopics: [Topic]
  
  init?(dict: [AnyHashable : Any]?) {
    if dict == nil {
      return nil
    }
    
    topic = dict?["topic"] as? String ?? ""
    songNumbers = dict?["psalm_numbers"] as? [String] ?? [String]()
    
    var tmpArray: [Topic] = []
    
    if let aDict = dict?["subtopics"] as? [AnyHashable : Any] {
      for subtopicDict in aDict {
        if let subtopicDict = subtopicDict as? [AnyHashable : Any] {
          let sub = Topic(dict: subtopicDict)
          
          if let sub = sub {
            tmpArray.append(sub)
          }
        }
      }
    }
    
    subtopics = tmpArray
  }
}
