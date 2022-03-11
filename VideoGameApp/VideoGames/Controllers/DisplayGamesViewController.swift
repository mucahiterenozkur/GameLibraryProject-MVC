//
//  DisplayGamesViewController.swift
//  VideoGamesApp
//
//  Created by Mücahit Eren Özkur on 6.03.2022.
//

import UIKit
import CoreData

class DisplayGamesViewController: UIViewController {
    /// References
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var pageView: UIView!
    @IBOutlet var pageVCHeightConstrait: NSLayoutConstraint!
    @IBOutlet var searchBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewTopConstraint: NSLayoutConstraint!
    
    /// Private properties
    private var initialY: CGFloat = 0
    private var updatedY: CGFloat = 0
    private var currentPage: Int = 1
    private var isLoadingList: Bool = false
    private var favouriteGameIDs = [Int]()
    private var filteredVideoGames = [GameModel]()
    private var allGames = [GameModel]()
    private var pageControllerGames = [GameModel]()
    private var collectionOfGames = [GameModel]()
    private var isFiltering: Bool = false  {
        didSet{
            if isFiltering == true {
                pageView.isHidden = true
                collectionView.center.y = updatedY
            }else {
                pageView.isHidden = false
                collectionView.center.y = initialY
            }
        }
    }
    
    /// Lazy properties
    lazy var gamePageViewController: GamePageViewController = {
        return children.lazy.compactMap({ $0 as? GamePageViewController }).first!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        loadMoreGames()
        collectionView.restore()
        flowLayout.minimumLineSpacing = 10
        initialY = collectionView.center.y
        updatedY = initialY - pageView.frame.height - 20
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemOrange]
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search a game..", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.6)])
        pageView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 15)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFavouriteGames()
    }
    
    private func getGames(with pageNumber: Int) {
        GameRequest.getGames(page: pageNumber) { result, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.showErrorAlert(message: "Couldn't fetch the information.")
                    return
                }
                
                let game = result.map({ GameModel(id: $0.id, rating: $0.rating, released: $0.released, metacritic: $0.metacritic, name: $0.name, backgroundImage: $0.backgroundImage, isFav: self.favouriteGameIDs.contains($0.id))
                })
                
                if let secondTab = (self.tabBarController?.viewControllers?[1]),
                   let navVC = secondTab as? UINavigationController,
                   let favVC = navVC.viewControllers[0] as? FavouriteGamesViewController {
                    favVC.updateFavGames(games: game)
                }
                
                self.allGames.append(contentsOf: game)
                self.adjustGames()
                self.isLoadingList = false
            }
        }
    }
    
    func adjustGames() {
        filteredVideoGames.removeAll()
        filteredVideoGames.append(contentsOf: allGames)
        
        if allGames.count <= 3 {
            pageControllerGames.removeAll()
            pageControllerGames.append(contentsOf: allGames)
        } else {
            let gamePageSource = allGames.prefix(3)
            let gameListSource = allGames.suffix(allGames.count - 3)
            
            pageControllerGames.removeAll()
            pageControllerGames.append(contentsOf: gamePageSource)
            collectionOfGames.removeAll()
            collectionOfGames.append(contentsOf: gameListSource)
        }
        
        self.collectionView.reloadData()
        self.createPageVC()
    }
    
    func createPageVC() {
        gamePageViewController.populateItems(gameSource: pageControllerGames)
    }
    
    /// to get favorites ids from local persistance.
    private func getFavouriteGames() {
        favouriteGameIDs.removeAll()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteVideoGames")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    
                    guard let favoriteGameId = result.value(forKey: "favoriteGameId") as? Int else { return }
                    self.favouriteGameIDs.append(favoriteGameId)
                    checkFavoriteUpdates()
                }
            }
        } catch {
            print("Error")
        }
    }
    
    private func checkFavoriteUpdates() {
        if !allGames.isEmpty {
            adjustGames()
            if isFiltering {
                if let isEmpty = searchBar.text?.isEmpty, !isEmpty{
                    searchBar.delegate?.searchBar?(searchBar, textDidChange: searchBar.text!)
                }
            }
        }
    }
    
    func loadMoreGames(){
        if currentPage <= 500 {
            currentPage += 1
            getGames(with: currentPage)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (((scrollView.contentOffset.y + scrollView.frame.size.height) > scrollView.contentSize.height ) && !isLoadingList){
            self.isLoadingList = true
            self.loadMoreGames()
        }
    }

}

extension DisplayGamesViewController:  UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return filteredVideoGames.count
        }
        return collectionOfGames.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCollectionViewCell
        
        var games = [GameModel]()
        if isFiltering {
            games = filteredVideoGames
        }else {
            games = collectionOfGames
        }
        
        let game = games[indexPath.row]
        cell.name.numberOfLines = 0
        cell.name.layer.masksToBounds = true
        cell.name.layer.cornerRadius = 20
        cell.name?.text = "\(game.name)\n" + "Rating: \(game.rating)\n" + "Release Date: \(game.released.prefix(4))"
        
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
        cell.gameImageView.layer.cornerRadius = 20
        cell.layer.cornerRadius = 20
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let vc = storyboard?.instantiateViewController(withIdentifier: "GameDetail") as? DetailedGamesViewController {
            
            var games = [GameModel]()
            if isFiltering{
                games = filteredVideoGames
            }else {
                games = collectionOfGames
            }
            vc.gameModel = games[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension DisplayGamesViewController: UISearchBarDelegate {
    
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
            collectionView.reloadData()
            return
        }
        
        isFiltering = true
        filteredVideoGames = allGames.filter({ (game: GameModel) -> Bool in
            return game.name.lowercased().contains(searchText.lowercased())
        })
        
        if filteredVideoGames.isEmpty {
            collectionView.setEmptyView(title: "\nSeriously, are you a gamer?", message: "What you are looking for doesn't even exist.")
            self.isLoadingList = false
        }else {
            collectionView.restore()
            self.isLoadingList = true
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
