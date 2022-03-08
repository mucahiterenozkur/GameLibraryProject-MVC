//
//  VideoGameClient .swift
//  VideoGames
//
//  Created by Gizem Boskan on 14.07.2021.
//

import Foundation

class GameRequest {
    
    static let apiKey = "47431fdea017443888eaf99d950c17db"
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        DispatchQueue.main.async(qos: .utility) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                
                if error != nil {
                    completion(nil, error)
                    return
                }
                guard let data = data else {
                    completion(nil, error)
                    return
                }
                
                print(String(decoding: data, as: UTF8.self))
                
                let decoder = JSONDecoder()
                
                do {
                    let responseObject = try decoder.decode(ResponseType.self, from: data)
                    completion(responseObject, nil)
                } catch {
                    
                    completion(nil, error)
                }
            }
            task.resume()
        }
        
    }
    
    class func getGames(page: Int, completion: @escaping ([GameResult], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getGames(page).url, responseType: Game.self) { response, error in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    class func getGameDetails (id: String, completion: @escaping (GameDetail?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getGameDetails(id).url, responseType: GameDetail.self) { response, error in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    class func downloadGameImage(path: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.gameImage(path).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}
