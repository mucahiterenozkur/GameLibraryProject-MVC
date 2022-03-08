//
//  Endpoints.swift
//  VideoGamesApp
//
//  Created by Mücahit Eren Özkur on 6.03.2022.
//

import Foundation

enum URLMaker {
    static let base = "https://api.rawg.io/api"
    static let apiKeyParam = "?key=\(GameRequest.APIKEY)"
    
    case getGames(Int)
    case getGameDetails(String)
    //    case search(String)
    case getGameImage(String)
    
    var url: URL {
        switch self {
        case .getGames(let page):
            return URL(string: URLMaker.base + "/games" + URLMaker.apiKeyParam + "&page=\(page)")!
        case .getGameDetails(let id): return URL(string: URLMaker.base + "/games/\(id)" + URLMaker.apiKeyParam)!
        case .getGameImage(let backgroundImagePath):
            return URL(string: backgroundImagePath)!
        }
    }
}
