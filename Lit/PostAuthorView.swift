//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import QuartzCore

class PostAuthorView: UIView {

    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorUsernameLabel: UILabel!

    @IBOutlet weak var timeLabelLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timeLabel: UILabel!
    var user:User?
    var authorTap:UITapGestureRecognizer!
    var authorTappedHandler:((_ uid:String)->())?

    var locationTap:UITapGestureRecognizer!
    var locationTappedHandler:((_ location:Location)->())?
    var closeHandler:(()->())?
    
    var location:Location?

    
    var margin:CGFloat = 16
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()

        authorImageView.layer.cornerRadius = authorImageView.frame.width/2
        authorImageView.clipsToBounds = true
        authorTap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
        
        locationTap = UITapGestureRecognizer(target: self, action: #selector(locationTapped))
        
        _ = CGRect(x: 0, y: 0, width: authorImageView.frame.width + margin, height: authorImageView.frame.height + margin)
        
        //self.applyShadow(2.0, opacity: 0.25, height: 1, shouldRasterize: false)
    }
    
    func setPostMetadata(post:StoryItem) {
        
        UserService.getUser(post.getAuthorId(), completion: { user in
            if user != nil {

                self.authorImageView.loadImageAsync(user!.getImageUrl(), completion: nil)
                self.authorUsernameLabel.text = user!.getDisplayName()
                self.authorImageView.removeGestureRecognizer(self.authorTap)
                self.authorImageView.addGestureRecognizer(self.authorTap)
                
                let superView = self.authorImageView.superview!
                superView.isUserInteractionEnabled = true
                superView.removeGestureRecognizer(self.authorTap)
                superView.addGestureRecognizer(self.authorTap)
                
                //let locSuperview = self.locationLabel.superview!
                //locSuperview.removeGestureRecognizer(self.locationTap)
                //locSuperview.addGestureRecognizer(self.locationTap)

                self.user = user
                
                self.timeLabel.text = post.getDateCreated()!.timeStringSinceNow()
                
                if post.toLocation {
                    LocationService.getLocation(post.getLocationKey(), completion: { location in
                        if location != nil {
                            self.location = location!
                            self.locationLabel.text = location!.getName()
                            //locSuperview.isUserInteractionEnabled = true
                        }
                    })
                } else {
                    self.location = nil
                    self.locationLabel.text = ""
                    //locSuperview.isUserInteractionEnabled = false
                }
            }
        })

    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        if user != nil {
            authorTappedHandler?(user!.getUserId())
        }
    }
    
    func locationTapped(gesture:UITapGestureRecognizer) {
        if location != nil {
           locationTappedHandler?(location!)
        }
    }
    
    
    @IBAction func handleClose(_ sender: Any) {
        closeHandler?()

    }
    

    func cleanUp() {
        user = nil
        location = nil
        authorImageView.image = nil
        authorUsernameLabel.text = nil
        locationLabel.text = nil
    }
    
    
}
