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
        
        let developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjNCTjVHUUc1SjIifQ.eyJpc3MiOiJCNDU1M0E3NTQyIiwiaWF0IjoxNjE4NDg2OTQ1LCJleHAiOjE2MTg1MzAxNDV9.9SE95YPFJw6OoTps-Q95nyf4ctLWP6IdsXL2G9b2gk9Pnlg9GydLzTzUW0lGwMrxQLmvyRcjloEbBKMmuzIO9g"
        
        let controller = SKCloudServiceController()
        
        SKCloudServiceController.requestAuthorization { status in
            
            controller.requestStorefrontCountryCode { countryCode, error in
                if let countryCode = countryCode {
                    var urlComponents = URLComponents()
                    urlComponents.scheme = "https"
                    urlComponents.host   = "api.music.apple.com"
                    urlComponents.path   = "/v1/catalog/\(countryCode)/search"
                    //urlComponents.path = "/v1/catalog/\(countryCode)/artists/1455392338/search"
                    
                    urlComponents.queryItems = [
                        URLQueryItem(name: "term", value: "book of psalms for worship psalm \(song.number)"),
                        URLQueryItem(name: "limit", value: "25"),
                        URLQueryItem(name: "types", value: "songs"),
                    ]
                    
                    if let url = urlComponents.url {
                        var request = URLRequest(url: url)
                        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
                        
                        let session = URLSession.shared
                        
                        let task = session.dataTask(with: request) { data, response, error in
                            guard let data = data else {
                                return
                            }
                            
                            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                var items = [AppleMusicMediaItem]()
                                
                                if
                                    let results = json["results"] as? [String:Any],
                                    let songs = results["songs"] as? [String:Any],
                                    let data = songs["data"] as? [[String:Any]]
                                {
                                    for datum in data {
                                        let id = datum["id"] as? String
                                        let attributes = datum["attributes"] as? [String:Any]
                                        
                                        let artistName = attributes?["artistName"] as? String
                                        let albumName = attributes?["albumName"] as? String
                                        let name = attributes?["name"] as? String
                                        
                                        let artwork = attributes?["artwork"] as? [String:Any]

                                        let filterString = "psalm \(song.number)".lowercased()
                                        
                                        if
                                            let id = id,
                                            let artistName = artistName,
                                            let albumName = albumName,
                                            let name = name,
                                            let artwork = artwork,
                                            name.lowercased().contains(filterString)
                                        {
                                            let item = AppleMusicMediaItem(id: id, artistName: artistName, albumName: albumName, name: name, artwork: artwork)
                                            items.append(item)
                                        }
                                    }
                                    completion(items, nil)
                                }
                            }
                        }
                        task.resume()
                    }
                }
            }
            
        }
    }
    
}
