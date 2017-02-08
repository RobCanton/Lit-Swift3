//
//  CommentCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var authorTapped:((_ userId:String)->())?
    
    var comment:Comment!
    @IBOutlet weak var userImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundView = nil
        backgroundColor = UIColor.clear
        
        selectedBackgroundView = nil

        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        userImage.addGestureRecognizer(tap)
        
        userImage.isUserInteractionEnabled = true
        
        authorLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        commentLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
    }
    
    var tap:UITapGestureRecognizer!

    func handleTap(sender:UITapGestureRecognizer) {
        authorTapped?(comment.getAuthor())
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setContent(comment:Comment) {
        self.comment = comment
        userImage.layer.cornerRadius = userImage.frame.width / 2
        userImage.clipsToBounds = true
        
        backgroundColor = UIColor.clear
        backgroundView = nil
        
        UserService.getUser(comment.getAuthor(), completion: { user in
            if user != nil {
                self.authorLabel.text = user!.getDisplayName()
                self.commentLabel.text = comment.getText()
                self.commentLabel.sizeToFit()
                self.userImage.loadImageAsync(user!.getImageUrl(), completion: nil)
            }
        })
    }
    
}
