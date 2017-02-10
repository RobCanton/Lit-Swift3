//
//  CommentBar.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

protocol CommentBarProtocol {
    func sendComment(_ comment:String)
    func toggleLike(_ like:Bool)
    func more()
}

class CommentBar: UIView {
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var commentPlaceHolder: UILabel!
    
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var sendButton: UIButton!
    
    
    var delegate:CommentBarProtocol?
    var liked = false

    
    
    override func awakeFromNib() {
        sendButton.alpha = 0.0
        
        textField.autocapitalizationType = .sentences
        textField.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
        sendButton.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
    }
    

    @IBAction func likeTapped(_ sender: Any) {
        setLikedStatus(!self.liked, animated: true)
        delegate?.toggleLike(liked)
    }
    
    func setLikedStatus(_ _liked:Bool, animated: Bool) {
        self.liked = _liked
        
        if self.liked  {
            likeButton.setImage(UIImage(named: "liked"), for: .normal)
            if animated {
                likeButton.setImage(UIImage(named: "liked"), for: .normal)
                self.likeButton.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                
                UIView.animate(withDuration: 0.5, delay: 0.0,
                               usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 1.6,
                               options: .curveEaseOut,
                               animations: {
                                self.likeButton.transform = CGAffineTransform.identity
                },
                               completion: nil)
            }

        } else {
            likeButton.setImage(UIImage(named:"like"), for: .normal)
        }
    }
    
    
    @IBAction func moreTapped(_ sender: Any) {
        delegate?.more()
    }
    
    @IBAction func sendButton(_ sender: Any) {
        if let text = textField.text {
            textField.text = ""
            delegate?.sendComment(text)
        }

    }
    
}
