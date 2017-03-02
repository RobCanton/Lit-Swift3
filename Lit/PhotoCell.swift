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
    
    var itemKey:String?
    
    func setPhoto(item:StoryItem) {
        imageView.image = nil
    
        UploadService.retrieveImage(byKey: item.getKey(), withUrl: item.getDownloadUrl(), completion: { image, fromFile in
            if !fromFile {
                self.imageView.alpha = 0.0
                UIView.animate(withDuration: 0.35, animations: {
                    self.imageView.alpha = 1.0
                })
            } else {
                self.imageView.alpha = 1.0
            }
            self.imageView.image = image
        })
    }
    

    
    
    
    

}
