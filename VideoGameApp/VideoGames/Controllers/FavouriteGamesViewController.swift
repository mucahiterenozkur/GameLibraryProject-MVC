//
//  FavoritesViewController.swift
//  VideoGamesApp
//
//  Created by Mücahit Eren Özkur on 6.03.2022.
//

import UIKit
import CoreData

class FavouriteGamesViewController: UIViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    
    private var filteredVideoGames = [GameModel]()
    private var isFiltering: Bool = false
    private var dataSource = [GameModel]() // Collection games
    private var gamesSource = [GameModel]()
    private var favouriteGameIDS = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        collectionView.restore()
        flowLayout.minimumLineSpacing = 10
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search a game..", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.6)])
        UISearchBar.appearance().tintColor = .white // for cancel button
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemOrange]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFavouriteGames()
    }
    
    private func getFavouriteGames() {
        favouriteGameIDS.removeAll()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteVideoGames")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    
                    guard let favoriteGameId = result.value(forKey: "favoriteGameId") as? Int else { return }
                    self.favouriteGameIDS.append(favoriteGameId)
                    checkFavoriteUpdates()
                }
            }
        } catch {
            print("Error")
        }
    }
    
    private func checkFavoriteUpdates() {
        if !gamesSource.isEmpty {
            dataSource.removeAll()
            dataSource.append(contentsOf: gamesSource.filter({favouriteGameIDS.contains($0.id)}))
            collectionView.reloadData()
        }
    }
    
    func updateFavGames(games: [GameModel]){
        gamesSource.removeAll()
        gamesSource.append(contentsOf: games)
    }
}

extension FavouriteGamesViewController:  UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return filteredVideoGames.count
        }
        return dataSource.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteGameCell", for: indexPath) as! GameCollectionViewCell
        
        var games = [GameModel]()
        if isFiltering {
            games = filteredVideoGames
        }else {
            games = dataSource
        }
        
        let game = games[indexPath.row]
        cell.name.numberOfLines = 0
        cell.name?.text = "\(game.name)\n" + "Rating: \(game.rating)\n" + "Release Date: \(game.released.prefix(4))"
        
        cell.gameImageView?.image = UIImage(named: "PosterPlaceholder")
        GameRequest.getGameImage(path: game.backgroundImage){ data, error in
            guard let data = data else {
                return
            }
            let image = UIImage(data: data)
            cell.gameImageView?.image = image
            cell.setNeedsLayout()
        }
        
        cell.gameImageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.gameImageView.layer.borderWidth = 2
        cell.gameImageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 20
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let vc = storyboard?.instantiateViewController(withIdentifier: "GameDetail") as? DetailedGamesViewController {
            
            var games = [GameModel]()
            if isFiltering{
                games = filteredVideoGames
            }else {
                games = dataSource
            }
            vc.gameModel = games[indexPath.row]
            vc.gameModel.isFav = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension FavouriteGamesViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if let isEmpty = searchBar.text?.isEmpty, isEmpty, searchText.isEmpty{
            DispatchQueue.main.async {
                self.isFiltering = false
                self.collectionView.restore()
                self.collectionView.reloadData()
                self.searchBar.resignFirstResponder()
                return
            }
        }
        
        if searchBar.text!.count <= 3 {
            isFiltering = false
            self.collectionView.restore()
            self.collectionView.reloadData()
            return
        }
        
        isFiltering = true
        filteredVideoGames = dataSource.filter({ (game: GameModel) -> Bool in
            return game.name.lowercased().contains(searchText.lowercased())
        })
        
        if filteredVideoGames.isEmpty {
            collectionView.setEmptyView(title: "Oops! Your search was not found.", message: "Search for another result!")
        }else {
            collectionView.restore()
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isFiltering = false
        searchBar.text = ""
        collectionView.reloadData()
        collectionView.restore()
    }
}

extension FavouriteGamesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 204, height: 267)
        
        
//        let height = self.collectionView.frame.size.height
//        let width = self.collectionView.frame.size.width
//
//        //return CGSize(width: width * 0.5, height: height * 0.5)
//        //return CGSize(width: width * 0.5, height: height * 0.5)
//        return CGSize(width: width / 2, height: 130)
//
//        //204-267
    }
}
