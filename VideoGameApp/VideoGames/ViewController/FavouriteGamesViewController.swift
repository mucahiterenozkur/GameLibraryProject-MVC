//
//  FavoritesViewController.swift
//  VideoGames
//
//  Created by Gizem Boskan on 14.07.2021.
//

import UIKit
import CoreData

class FavouriteGamesViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    
    var filteredVideoGames = [GameModel]()
    var isFiltering: Bool = false
    var dataSource = [GameModel]() // Collection games
    var gamesSource = [GameModel]()
    var favVideoGameIds = [Int]()
    
    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        collectionView.restore()
        flowLayout.minimumLineSpacing = 10
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFavorites()
    }
    
    private func getFavorites() {
        favVideoGameIds.removeAll()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteVideoGames")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    
                    guard let favoriteGameId = result.value(forKey: "favoriteGameId") as? Int else { return }
                    self.favVideoGameIds.append(favoriteGameId)
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
            dataSource.append(contentsOf: gamesSource.filter({favVideoGameIds.contains($0.id)}))
            collectionView.reloadData()
        }
    }
    
    func updateFavGames(games: [GameModel]){
        gamesSource.removeAll()
        gamesSource.append(contentsOf: games)
    }
}

// MARK: - UICollectionViewDataSource and Delegate
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
        GameRequest.downloadGameImage(path: game.backgroundImage){ data, error in
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
        cell.layer.cornerRadius = 7
        
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
            vc.game = games[indexPath.row]
            vc.game.isFav = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UISearchBarDelegate
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
    }
}

