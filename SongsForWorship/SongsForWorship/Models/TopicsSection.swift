//
//  LetterTopics.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/30/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

struct TopicsSection {
    var section: String
    var topics: [Topic]
    
    /*
    init?(letter: Character, topics: [Topic]) {
        self.letter = letter
        self.topics = topics
    }
     */
}

extension TopicsSection: Decodable {}
