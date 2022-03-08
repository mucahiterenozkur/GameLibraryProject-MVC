//
//  Endpoints.swift
//  VideoGames
//
//  Created by Gizem Boskan on 14.07.2021.
//

import Foundation

enum Endpoints {
    static let base = "https://api.rawg.io/api"
    static let apiKeyParam = "?key=\(GameRequest.apiKey)"
    
    case getGames(Int)
    case getGameDetails(String)
    //    case search(String)
    case gameImage(String)
    
    var url: URL {
        switch self {
        case .getGames(let page):
            return URL(string: Endpoints.base + "/games" + Endpoints.apiKeyParam + "&page=\(page)")!
        case .getGameDetails(let id): return URL(string: Endpoints.base + "/games/\(id)" + Endpoints.apiKeyParam)!
        case .gameImage(let backgroundImagePath):
            return URL(string: backgroundImagePath)!
        }
    }
}
