//
//  CustomPhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Dan Pham on 3/13/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import UIKit

class CustomPhotoCollectionViewCell: UICollectionViewCell{

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func imageSetup() {
        imageView.contentMode = .scaleAspectFill
        activityIndicator.hidesWhenStopped = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(named: "defaultPlaceholderImage")
    }
}
