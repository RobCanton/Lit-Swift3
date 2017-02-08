//
//  StoryInfoView.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-07.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class StoryInfoView: UIView {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var usernameTopConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //backgroundBlur.isHidden = true
        //backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        
        usernameLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        captionLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        timeLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
    }
    
    func setInfo(user:User, item:StoryItem) {
        usernameLabel.text = user.getDisplayName()
        captionLabel.text = item.caption
        timeLabel.text = item.getDateCreated()!.timeStringSinceNow()
        if item.caption != "" {
            usernameTopConstraint.constant = 8
        } else {
            usernameTopConstraint.constant = 16
        }
    }
    
    func setUserImage(image:UIImage) {
        userImageView.image = image
        userImageView.layer.cornerRadius = userImageView.frame.width / 2
        userImageView.clipsToBounds = true
    }
    
    func phaseInCaption() {
        if #available(iOS 10.0, *) {
            
            if backgroundBlur.layer.speed == 0 { return }
            
            backgroundBlur.isHidden = false
            backgroundBlur.removeAnimation()
            backgroundBlur.effect = nil
            
            UIView.animate(withDuration: 1.0, animations: {
                self.backgroundBlur.effect = UIBlurEffect(style: .light)
            })
            
            backgroundBlur.pauseAnimation(delay: 0.42)
            backgroundBlur.resumeAnimation()
            
        } else {
            // Fallback on earlier versions
        }
    }
    
}
