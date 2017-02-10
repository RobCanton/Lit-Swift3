//
//  UserStoryTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserStoryTableViewCell: UITableViewCell, StoryProtocol {


    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    @IBOutlet weak var userBadge: UIImageView!
    
    var userStory:UserStory?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageContainer.layer.cornerRadius = imageContainer.frame.width/2
        imageContainer.clipsToBounds = true
        imageContainer.layer.borderColor = UIColor.clear.cgColor
        imageContainer.layer.borderWidth = 1.8
        
        contentImageView.layer.cornerRadius = contentImageView.frame.width/2
        contentImageView.clipsToBounds = true
        
        timeLabel.textColor = UIColor.gray
    }
    
    func activate(_ animated:Bool) {
        guard let story = userStory else { return }
        guard let items = story.items else { return }
        
        var borderColor = accentColor.cgColor
        if story.hasViewedAll() {
            borderColor = UIColor.darkGray.cgColor
        }
        if items.count == 0 { return }
        if animated {
            let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
            color.fromValue = UIColor.black.cgColor
            color.toValue = borderColor
            imageContainer.layer.borderColor = borderColor
            
            
            let both:CAAnimationGroup = CAAnimationGroup()
            both.duration = 0.30
            both.animations = [color]
            both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            imageContainer.layer.add(both, forKey: "color and Width")
        } else {
            imageContainer.layer.borderColor = borderColor
        }
    }
    
    func deactivate() {
        imageContainer.layer.borderColor = UIColor.clear.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setUserStory(_ story:UserStory, useUsername:Bool) {
        self.userStory = story
        story.delegate = self
        stateChange(story.state)

        UserService.getUser(story.getUserId(), completion: { user in
            if user != nil {
                
                if user!.getUserId() == mainStore.state.userState.uid && !useUsername {
                    
                    self.usernameLabel.text = "Your Story"
                } else {
                    self.usernameLabel.text = user!.getDisplayName()
                }
                
                self.userBadge.isHidden = !user!.isVerified()
                
                
                // Load in image to avoid blip in story view
//                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
//                    self.contentImageView.image = image
//                })
                
                UploadService.getUpload(key: story.getPostKeys().last!, completion: { item in
                    if item != nil {
                        loadImageUsingCacheWithURL(item!.getDownloadUrl().absoluteString, completion: { image, fromCache in
                            self.contentImageView.image = image
                            if !fromCache {
                                self.contentImageView.alpha = 0.0
                                UIView.animate(withDuration: 0.25, animations: {
                                    self.contentImageView.alpha = 1.0
                                })
                            } else {
                                self.contentImageView.alpha = 1.0
                            }
                        })
                    }
                })
                self.timeLabel.text = "\(story.getDate().timeStringSinceNowWithAgo())"
            }
        })
    }
    

    func setToEmptyMyStory() {
        self.usernameLabel.text = "Your Story"
        self.timeLabel.text = "+ Tap to add"
        imageContainer.layer.borderColor = UIColor.darkGray.cgColor
        if let user = mainStore.state.userState.user {
            loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromCache in
                self.contentImageView.image = image
            })
        }

    }
    
    
    func stateChange(_ state:UserStoryState) {

        switch state {
        case .notLoaded:
            userStory?.downloadItems()
            self.usernameLabel.textColor = UIColor.gray
            break
        case .loadingItemInfo:
            self.usernameLabel.textColor = UIColor.gray
            break
        case .itemInfoLoaded:
            self.usernameLabel.textColor = UIColor.gray
            itemsLoaded()
            break
        case .loadingContent:
            self.usernameLabel.textColor = UIColor.gray
            loadingContent()
            break
        case .contentLoaded:
            self.usernameLabel.textColor = UIColor.white
            contentLoaded()
            break
        }
    }
    
    func itemsLoaded() {
        guard let items = userStory?.items else { return }
        if items.count > 0 {

            activate(false)
            /*loadImageUsingCacheWithURL(lastItem.getDownloadUrl().absoluteString, completion: { image, fromCache in
                
                if !fromCache {
                    self.contentImageView.alpha = 0.0
                    UIView.animateWithDuration(0.30, animations: {
                        self.contentImageView.alpha = 1.0
                    })
                } else {
                    self.contentImageView.alpha = 1.0
                }
                self.contentImageView.image = image
            })*/
        }
    }
    
    func loadingContent() {
        timeLabel.text = "Loading..."
    }
    
    func contentLoaded() {
        guard let story = userStory else { return }
        timeLabel.text = "\(story.getDate().timeStringSinceNowWithAgo())"
        
    }
}
