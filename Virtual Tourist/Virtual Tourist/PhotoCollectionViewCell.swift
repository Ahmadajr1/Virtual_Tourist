//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Ahmed Al Ramadhan on 02/02/2019.
//  Copyright © 2019 Ahmed Al Ramadhan. All rights reserved.
//

import Foundation
import UIKit

class PhotoCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var photoImageView: UIImageView!
//
    func startAnActivityIndicator() -> UIActivityIndicatorView {
        self.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        return activityIndicator
    }
}
