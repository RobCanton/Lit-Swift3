
//
//  UserViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserViewCell: UITableViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var imageContainer: UIView!
    
    @IBOutlet weak var followButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentImageView.layer.cornerRadius = contentImageView.frame.width/2
        contentImageView.clipsToBounds = true
        
        followButton.layer.cornerRadius = 3.0
        followButton.clipsToBounds = true
        followButton.layer.borderWidth = 1.0
        followButton.isHidden = false    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var user:User?
    
    var status:FollowingStatus?
    
    func setupUser(uid:String) {
        contentImageView.image = nil
        
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.user = user!
                self.contentImageView.loadImageAsync(user!.getImageUrl(), completion: nil)
                self.usernameLabel.text = user!.getDisplayName()
                
            }
        })
        
        setUserStatus(status: checkFollowingStatus(uid: uid))
    }
    
    func setUserStatus(status:FollowingStatus) {
        if self.status == status { return }
        self.status = status
        
        switch status {
        case .CurrentUser:
            followButton.isHidden = true
            break
        case .None:
            followButton.isHidden = false
            followButton.backgroundColor = accentColor
            followButton.layer.borderColor = UIColor.clear.cgColor
            followButton.setTitle("Follow", for: .normal)
            break
        case .Requested:
            followButton.isHidden = false
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = UIColor.white.cgColor
            followButton.setTitle("Requested", for: .normal)
            break
        case .Following:
            followButton.isHidden = false
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = UIColor.white.cgColor
            followButton.setTitle("Following", for: .normal)
            break
        }
    }
    
    var unfollowHandler:((_ user:User)->())?
    
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }
        
        switch status {
        case .CurrentUser:
            break
        case .Following:
            unfollowHandler?(user)
            break
        case .None:
            setUserStatus(status: .Requested)
            UserService.followUser(uid: user.getUserId())
            break
        case .Requested:
            break
        }
    }
    
}
