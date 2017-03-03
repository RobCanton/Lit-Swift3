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
    var imageAlpha:CGFloat = 1.0
    
    func setPhoto(item:StoryItem) {
        imageView.image = nil
        
        if item.shouldBlock() {
            self.imageAlpha = 0.0
            
        } else {
            self.imageAlpha = 1.0
            
        }
        self.imageView.alpha = self.imageAlpha
        
    
        UploadService.retrieveImage(byKey: item.getKey(), withUrl: item.getDownloadUrl(), completion: { image, fromFile in
            if !fromFile {
                self.imageView.alpha = 0.0
                UIView.animate(withDuration: 0.35, animations: {
                    self.imageView.alpha = self.imageAlpha
                })
            } else {
                self.imageView.alpha = self.imageAlpha
            }
            self.imageView.image = image
        })
    }
    

    
    
    
    

}
