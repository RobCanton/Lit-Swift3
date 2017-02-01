//
//  ProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProfileHeaderView: UICollectionReusableView {

    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var controlBarContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var errorLabel: UILabel!
    

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    
    
    @IBOutlet weak var dividerView: UIView!
    let subColor = UIColor(white: 0.5, alpha: 1.0)
    
    var user:User?
    var status:FollowingStatus?
    
    var messageHandler:(()->())?
    var followersHandler:(()->())?
    var followingHandler:(()->())?
    var editProfileHandler:(()->())?
    
    var followersTap: UITapGestureRecognizer!
    var followingTap: UITapGestureRecognizer!
    var messageTap: UILongPressGestureRecognizer!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        dividerView.layer.borderColor = UIColor(white: 0.15, alpha: 1.0).cgColor
        dividerView.layer.borderWidth = 0.5
    }
    
    var fetched = false
    
    func populateHeader(user:User){
        if fetched { return }
        fetched = true

        self.user = user
        
        if let url = user.largeImageURL {
            loadImageUsingCacheWithURL(url, completion: { image, fromCache in
                if image != nil {
                    self.errorLabel.isHidden = true
                    if !fromCache {
                        self.profileImageView.alpha = 0.0
                        UIView.animate(withDuration: 0.25, animations: {
                            self.profileImageView.alpha = 1.0
                        })
                    }
                    self.profileImageView.image = image
                } else {
                    self.errorLabel.isHidden = false
                }

            })
        }
        
        if let bio = user.bio {
            bioLabel.text = bio
        }
        
        postsLabel.styleProfileBlockText(count: 0, text: "posts", color: subColor, color2: UIColor.black)
        
        followersLabel.styleProfileBlockText(count: 0, text: "followers", color: subColor, color2: UIColor.black)
        followingLabel.styleProfileBlockText(count: 0, text: "following", color: subColor, color2: UIColor.black)
        messageLabel.styleProfileBlockText(count: 0, text: "Message", color: UIColor.white, color2: UIColor.clear)

        
        followButton.layer.cornerRadius = 2.0
        followButton.clipsToBounds = true
        followButton.layer.borderWidth = 1.0
        followButton.isHidden = false

        messageButton.layer.cornerRadius = 2.0
        messageButton.clipsToBounds = true
        messageButton.isHidden
            = false
        
        if let name = user.getName() {
            nameLabel.text = name
        } else {
            nameLabel.text = user.getDisplayName()
        }
        
        locationLabel.text = "@\(user.getDisplayName())"
        
        
        setUserStatus(status: checkFollowingStatus(uid: user.getUserId()))
        
        followersTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowersTap))
        followingTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowingTap))
        
        messageTap = UILongPressGestureRecognizer(target: self, action: #selector(handleMessageLongTap))
        messageTap.minimumPressDuration = 0.0
        messageTap.numberOfTouchesRequired = 1
        messageTap.allowableMovement = 30.0
    
        
        
        let followersView = followersLabel.superview!
        followersView.isUserInteractionEnabled = true
        followersView.addGestureRecognizer(followersTap)
        
        let followingView = followingLabel.superview!
        followingView.isUserInteractionEnabled = true
        followingView.addGestureRecognizer(followingTap)

        
        controlBarContainer.isUserInteractionEnabled = true
        let messageView = messageButton.superview!
        if user.uid == mainStore.state.userState.uid {
            messageView.alpha = 0.35
        } else {
            messageView.alpha = 1.0
            messageView.isUserInteractionEnabled = true
            messageView.addGestureRecognizer(messageTap)
        }
    }
    
    func setFullProfile(largeImageURL:String?, bio:String?) {
        
    }
    
    func setPostsCount(count:Int) {
        if count == 1 {
            postsLabel.styleProfileBlockText(count: count, text: "post", color: subColor, color2: UIColor.white)
        } else {
            postsLabel.styleProfileBlockText(count: count, text: "posts", color: subColor, color2: UIColor.white)
        }
    }
    
    func setFollowersCount(count:Int) {
        if count == 1 {
            followersLabel.styleProfileBlockText(count: count, text: "follower", color: subColor, color2: UIColor.white)
        } else {
            followersLabel.styleProfileBlockText(count: count, text: "followers", color: subColor, color2: UIColor.white)
        }
    }
    
    func setFollowingCount(count:Int) {
        followingLabel.styleProfileBlockText(count: count, text: "following", color: subColor, color2: UIColor.white)
    }
    
    var unfollowHandler:((_ user:User)->())?
    func setUserStatus(status:FollowingStatus) {
        if self.status == status { return }
        self.status = status
        switch status {
        case .CurrentUser:
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = UIColor.white.cgColor
            followButton.setTitle("Edit Profile", for: .normal)
            break
        case .None:
            followButton.backgroundColor = accentColor
            followButton.layer.borderColor = UIColor.clear.cgColor
            followButton.setTitle("Follow", for: .normal)
            break
        case .Requested:
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = UIColor.white.cgColor
            followButton.setTitle("Requested", for: .normal)
            break
        case .Following:
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = UIColor.white.cgColor
            followButton.setTitle("Following", for: .normal)
            break
        }
    }
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }

        switch status {
        case .CurrentUser:
            editProfileHandler?()
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
    

    func handleFollowersTap(sender:UITapGestureRecognizer) {
        followersHandler?()
    }
    
    func handleFollowingTap(sender:UITapGestureRecognizer) {
        followingHandler?()
    }
    
    func handleMessageTap(sender:UITapGestureRecognizer) {
        messageHandler?()
    }
    
    func handleMessageLongTap(recognizer:UILongPressGestureRecognizer) {
        let state = recognizer.state
        let messageView = messageButton.superview!
        if state == .began {
            messageView.alpha = 0.5
        } else if state == .ended || state == .failed || state == .cancelled {
            messageView.alpha = 1.0
        }
        
        if recognizer.state == .ended {
            messageHandler?()
        }
    }
}
