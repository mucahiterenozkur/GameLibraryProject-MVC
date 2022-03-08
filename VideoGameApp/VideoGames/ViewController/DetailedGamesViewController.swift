//
//  DetailedGamesViewController.swift
//  VideoGamesApp
//
//  Created by Mücahit Eren Özkur on 6.03.2022.
//

import UIKit
import CoreData
class DetailedGamesViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var detailTextView: UITextView!
    @IBOutlet var favoriteBarButtonItem: UIBarButtonItem!
    
    var gameModel: GameModel!
    var game: GameResult!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = gameModel.name
        
        if gameModel.isFav {
            favoriteBarButtonItem.tintColor = UIColor.red
        }
        
        imageView.image = UIImage(named: "PosterPlaceholder")
        GameRequest.getGameImage(path: gameModel.backgroundImage) { data, error in
            guard let data = data else {
                return
            }
            let image = UIImage(data: data)
            self.imageView.image = image
        }
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        GameRequest.getGameDetails(id: String(gameModel.id)) {videoGameDetail, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.showErrorAlert(message: "could not fetch the details")
                    return
                }
                if let videoGameDetail = videoGameDetail {
                    self.detailTextView.text =
                        ("\(videoGameDetail.nameOriginal)\n" + "Release Date: \(videoGameDetail.released)\n" + "Metacritic Rate: \(videoGameDetail.metacritic)\n" + "\(videoGameDetail.welcomeDescription)").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                }
            }
        }
    }
    
    @IBAction func favoriteBarButtonItemTapped(){
        if gameModel.isFav {
            favoriteBarButtonItem.tintColor = UIColor.gray
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"FavoriteVideoGames")
            
            fetchRequest.predicate = NSPredicate(format: "favoriteGameId = %@", "\(gameModel.id)")
            do
            {
                let fetchedResults =  try context.fetch(fetchRequest) as? [NSManagedObject]
                
                for entity in fetchedResults! {
                    
                    context.delete(entity)
                }
                try context.save()
            }
            catch _ {
                print("Could not be deleted!")
            }
        } else {
            favoriteBarButtonItem.tintColor = UIColor.red
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            
            let context = appDelegate.persistentContainer.viewContext
            let newGame = NSEntityDescription.insertNewObject(forEntityName: "FavoriteVideoGames", into: context)
            
            newGame.setValue(gameModel.id, forKey: "favoriteGameId")
            
            do {
                try context.save()
            } catch  {
                print("Could not be saved!")
            }
        }
        gameModel.isFav.toggle()
    }
}



