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
        
        _ = CGRect(x: 0, y: 0, width: authorImageView.frame.width + margin, height: authorImageView.frame.height + margin)
        
    }
    
    func setAuthorInfo(user:User, post:StoryItem) {
       
        self.authorUsernameLabel.text = user.getDisplayName()
        self.user = user
        self.timeLabel.text = post.getDateCreated()!.timeStringSinceNow()
    }
    
    func setAuthorImage(image:UIImage) {
        self.authorImageView.image = image
        self.authorImageView.removeGestureRecognizer(self.authorTap)
        self.authorImageView.addGestureRecognizer(self.authorTap)
        
        let superView = self.authorImageView.superview!
        superView.isUserInteractionEnabled = true
        superView.removeGestureRecognizer(self.authorTap)
        superView.addGestureRecognizer(self.authorTap)
    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        if user != nil {
            authorTappedHandler?(user!.getUserId())
        }
    }

    func cleanUp() {
        user = nil
        location = nil
        authorImageView.image = nil
        authorUsernameLabel.text = nil
        locationLabel.text = nil
    }
    
    
}
