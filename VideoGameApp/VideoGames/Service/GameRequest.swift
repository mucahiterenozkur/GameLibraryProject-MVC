//
//  GameRequest .swift
//  VideoGamesApp
//
//  Created by Mücahit Eren Özkur on 6.03.2022.
//

import Foundation

class GameRequest {
    
    static let APIKEY = "47431fdea017443888eaf99d950c17db"
    
    class func getGames(page: Int, completion: @escaping ([GameResult], Error?) -> Void) {
        getRequestForGamesAndDetails(url: URLMaker.getGames(page).url, jsonType: Game.self) { response, error in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    class func getGameDetails (id: String, completion: @escaping (GameDetail?, Error?) -> Void) {
        getRequestForGamesAndDetails(url: URLMaker.getGameDetails(id).url, jsonType: GameDetail.self) { response, error in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    class func getGameImage(path: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: URLMaker.getGameImage(path).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
    class func getRequestForGamesAndDetails<JSONType: Decodable>(url: URL, jsonType: JSONType.Type, completion: @escaping (JSONType?, Error?) -> Void) {
        DispatchQueue.main.async(qos: .utility) {
            let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
                
                if error != nil {
                    completion(nil, error)
                    return
                }
                guard let data = data else {
                    completion(nil, error)
                    return
                }
                
//                print(String(decoding: data, as: UTF8.self))
                
                let decoder = JSONDecoder()
                do {
                    let results = try decoder.decode(JSONType.self, from: data)
                    completion(results, nil)
                } catch {
                    completion(nil, error)
                }
            }
            dataTask.resume()
        }
    }
    
    
}
