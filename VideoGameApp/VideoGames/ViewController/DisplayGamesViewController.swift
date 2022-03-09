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
    private var dataSource = [GameModel]() // All video games
    private var pageSource = [GameModel]() // Page controller games
    private var listSource = [GameModel]() // Collection games
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
                    self.showErrorAlert(message: "something went wrong!")
                    return
                }
                
                let game = result.map({ GameModel(id: $0.id, rating: $0.rating, released: $0.released, metacritic: $0.metacritic, name: $0.name, backgroundImage: $0.backgroundImage, isFav: self.favouriteGameIDs.contains($0.id))
                })
                
                if let secondTab = (self.tabBarController?.viewControllers?[1]),
                   let navVC = secondTab as? UINavigationController,
                   let favVC = navVC.viewControllers[0] as? FavouriteGamesViewController {
                    favVC.updateFavGames(games: game)
                }
                
                self.dataSource.append(contentsOf: game)
                self.adjustDatasources()
                self.isLoadingList = false
            }
        }
    }
    
    func adjustDatasources() {
        filteredVideoGames.removeAll()
        filteredVideoGames.append(contentsOf: dataSource)
        
        if dataSource.count <= 3 {
            pageSource.removeAll()
            pageSource.append(contentsOf: dataSource)
        } else {
            let gamePageSource = dataSource.prefix(3)
            let gameListSource = dataSource.suffix(dataSource.count - 3)
            
            pageSource.removeAll()
            pageSource.append(contentsOf: gamePageSource)
            listSource.removeAll()
            listSource.append(contentsOf: gameListSource)
        }
        
        self.collectionView.reloadData()
        self.createPageVC()
    }
    
    func createPageVC() {
        gamePageViewController.populateItems(gameSource: pageSource)
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
        if !dataSource.isEmpty {
            adjustDatasources()
            if isFiltering {
                if let isEmpty = searchBar.text?.isEmpty, !isEmpty{
                    searchBar.delegate?.searchBar?(searchBar, textDidChange: searchBar.text!)
                }
            }
        }
    }
    
    func loadMoreGames(){
        if currentPage <= 10000 {
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

// MARK: - EXTENSIONS

extension DisplayGamesViewController:  UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return filteredVideoGames.count
        }
        return listSource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCollectionViewCell
        
        var games = [GameModel]()
        if isFiltering {
            games = filteredVideoGames
        }else {
            games = listSource
        }
        
        let game = games[indexPath.row]
        cell.name.numberOfLines = 0
        cell.name.layer.masksToBounds = true
        cell.name.layer.cornerRadius = 20
        cell.name?.text = "\(game.name)\n" + "Rating: \(game.rating)\n" + "Release Date: \(game.released.prefix(4))"
        
        //cell.backgroundColor = .systemOrange
        
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
                games = listSource
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
        filteredVideoGames = dataSource.filter({ (game: GameModel) -> Bool in
            return game.name.lowercased().contains(searchText.lowercased())
        })
        
        if filteredVideoGames.isEmpty {
            collectionView.setEmptyView(title: "Oops! Your search was not found.", message: "Search for another result!")
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

extension UICollectionView {
    
    func setEmptyView(title: String, message: String){
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: "empty"))
        
        imageView.backgroundColor = .clear
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 15)
        
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        emptyView.addSubview(imageView)
        
        
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        
        imageView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -20).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        titleLabel.text = title
        messageLabel.text = message
        
        titleLabel.textAlignment = .center
        messageLabel.textAlignment = .center
        
        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0
        
        UIView.animate(withDuration: 1, animations: {
            
            imageView.transform = CGAffineTransform(rotationAngle: .pi / 15)
        }, completion: { (finish) in
            UIView.animate(withDuration: 1, animations: {
                imageView.transform = CGAffineTransform(rotationAngle: -1 * (.pi / 15))
            }, completion: { (finish) in
                UIView.animate(withDuration: 1, animations: {
                    imageView.transform = CGAffineTransform.identity
                })
            })
            
        })
        self.backgroundView = emptyView
    }
    func restore() {
        self.backgroundView = nil
    }
}





