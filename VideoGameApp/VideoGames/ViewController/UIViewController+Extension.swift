//
//  UIViewController+Extension.swift
//  VideoGames
//
//  Created by Gizem Boskan on 21.07.2021.
//

import Foundation

import UIKit

extension UIViewController {
    func showErrorAlert(message: String){
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(ac, animated: true)
    }
}
