//
//  PhotoCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {


    @IBOutlet weak var imageView: UIImageView!
    
    
//    @IBOutlet weak var gradientView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.0

    }
    
    func setPhoto(item:StoryItem) {
        imageView.image = nil
        
        imageView.loadImageAsync(item.getDownloadUrl().absoluteString, completion: { fromCache in
            
        })
    }
    

    
    
    
    

}
