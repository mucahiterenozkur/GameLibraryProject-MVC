//
//  OnboardingViewController.swift
//  VideoGamesApp
//
//  Created by Mücahit Eren Özkur on 11.03.2022.
//

import UIKit

class OnboardingViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var slides: [OnboardingSlide] = []
    
    var currentPage = 0 {
        didSet {
            print(currentPage)
            pageControl.currentPage = currentPage
            if currentPage == slides.count - 1 {
                nextBtn.setTitle("Get Started", for: .normal)
                nextBtn.titleLabel?.font = UIFont(name: "Chalkboard SE", size: 18)
            } else {
                nextBtn.setTitle("Next", for: .normal)
                nextBtn.titleLabel?.font = UIFont(name: "Chalkboard SE", size: 18)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentPage == 0 {
            nextBtn.setTitle("Next", for: .normal)
            nextBtn.titleLabel?.font = UIFont(name: "Chalkboard SE", size: 18)
        }
        
        slides = [
            OnboardingSlide(title: "Amazing Games", description: "Reach a variety of amazing games' informations from different platforms.", image: #imageLiteral(resourceName: "1")),
            OnboardingSlide(title: "List Your Favourites", description: "Like your favourite games and store them in a different page.", image: #imageLiteral(resourceName: "2")),
            OnboardingSlide(title: "Enjoy It", description: "See what a game is about and detailed descriptions.", image: #imageLiteral(resourceName: "3"))
        ]
        
        pageControl.numberOfPages = slides.count
    }
    
    @IBAction func nextBtnClicked(_ sender: UIButton) {
        if currentPage == slides.count - 1 {
            let controller = storyboard?.instantiateViewController(identifier: "tabBar") as! UITabBarController
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .crossDissolve
            UserDefaults.standard.hasOnboardedd = true
            present(controller, animated: true, completion: nil)
        } else {
            currentPage += 1
            let indexPath = IndexPath(item: currentPage, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
}

extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingCollectionViewCell.identifier, for: indexPath) as! OnboardingCollectionViewCell
        cell.setup(slides[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        currentPage = Int(scrollView.contentOffset.x / width)
    }
}
