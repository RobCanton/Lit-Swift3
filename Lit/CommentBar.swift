//
//  CommentBar.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit


class CommentBar: UIView {
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var commentPlaceHolder: UILabel!
    
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var likeButton: UIButton!
    override func awakeFromNib() {
    }
    
    var liked = false
    
    @IBAction func likeTapped(_ sender: Any) {
        liked = !liked
        if liked {
            likeButton.setImage(UIImage(named: "fireon"), for: .normal)
            self.likeButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

            UIView.animate(withDuration: 0.5, delay: 0.0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 1.5,
                           options: .curveEaseOut,
                           animations: {
                                self.likeButton.transform = CGAffineTransform.identity
                            },
                           completion: nil)
        } else {
            likeButton.setImage(UIImage(named:"fire"), for: .normal)
        }
        
        
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        
    }
}
