//
//  AppleMusicController.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/15/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation
import StoreKit

class AppleMusicController {
    
    static func search(forSong song: Song, completion: @escaping ([AppleMusicMediaItem]?, Error?) -> ()) {
        
        let developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjNCTjVHUUc1SjIifQ.eyJpc3MiOiJCNDU1M0E3NTQyIiwiaWF0IjoxNjE4Nzc1MjA1LCJleHAiOjE2MzQzMjcyMDV9.zG_dJ9_MV99lVyS-uGls2l2_75BZ4GzO9hG0bpBfHR7unCjjfHf4WRS7Dx7-lfcwCqSSI8cizICyr-T5kgohOg"
        
        let controller = SKCloudServiceController()
        
        controller.requestStorefrontCountryCode { countryCode, error in
            guard let countryCode = countryCode else {
                completion(nil, NSError(domain: "sfw", code: 1, userInfo: nil))
                return
            }
            
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host   = "api.music.apple.com"
            urlComponents.path   = "/v1/catalog/\(countryCode)/search"
            
            urlComponents.queryItems = [
                URLQueryItem(name: "term", value: "book of psalms for worship psalm \(song.number)"),
                URLQueryItem(name: "limit", value: "25"),
                URLQueryItem(name: "types", value: "songs"),
            ]
            
            guard let url = urlComponents.url else {
                completion(nil, NSError(domain: "sfw", code: 1, userInfo: nil))
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
            
            let session = URLSession.shared
                        
            let task = session.dataTask(with: request) { data, response, error in
                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                else {
                    completion(nil, NSError(domain: "sfw", code: 1, userInfo: nil))
                    return
                }
                
                var items = [AppleMusicMediaItem]()
                
                if
                    let results = json["results"] as? [String:Any],
                    let songs = results["songs"] as? [String:Any],
                    let data = songs["data"] as? [[String:Any]]
                {
                    for datum in data {
                        let filterString1 = "psalm \(song.number)".lowercased()
                        let filterString2: String = {
                            let idx = song.number.endIndex
                            return "psalm \(song.number[..<song.number.index(before: idx)]) \(song.number[song.number.index(before: idx)])".lowercased()
                        }()
                        
                        if
                            let id = datum["id"] as? String,
                            let attributes = datum["attributes"] as? [String:Any],
                            let artistName = attributes["artistName"] as? String,
                            let albumName = attributes["albumName"] as? String,
                            let name = attributes["name"] as? String,
                            let artworkDict = attributes["artwork"] as? [String:Any],
                            let artwork = try? Artwork(json: artworkDict),
                            let durationInMillis = attributes["durationInMillis"] as? Int,
                            name.lowercased().contains(filterString1) || name.lowercased().contains(filterString2)
                        {
                            let duration: TimeInterval = Double(durationInMillis) / 1000
                            let item = AppleMusicMediaItem(id: id, artistName: artistName, albumName: albumName, name: name, artwork: artwork, length: duration)
                            items.append(item)
                        }
                    }
                }
                completion(items, nil)
            }
            task.resume()
        }
        
    }
    
}
