//
//  LocationTableCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class LocationTableCell: UITableViewCell {
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    
    //@IBOutlet weak var topImageViewConstraint: NSLayoutConstraint!
    //@IBOutlet weak var bottomImageViewConstraint: NSLayoutConstraint!

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var guestsCountBubble: UIView!
    @IBOutlet weak var guestsCountLabel: UILabel!


    var imageViewInitialTopConstraint: CGFloat!
    var imageViewInitialBottomConstraint: CGFloat!
    let parallaxIndex: CGFloat = 18
    var location:Location?
    var fadeView:UIView!
    
    var gradient:CAGradientLayer?
    
    var check = 0
    @IBOutlet weak var gv: UIView!
    @IBOutlet weak var guestIcon1: UIImageView!
    @IBOutlet weak var guestIcon2: UIImageView!
    @IBOutlet weak var guestIcon3: UIImageView!
    @IBOutlet weak var guestIcon4: UIImageView!
    @IBOutlet weak var guestIcon5: UIImageView!
    
    
    @IBOutlet weak var leading1: NSLayoutConstraint!
    @IBOutlet weak var leading2: NSLayoutConstraint!
    @IBOutlet weak var leading3: NSLayoutConstraint!
    @IBOutlet weak var leading4: NSLayoutConstraint!
    @IBOutlet weak var leading5: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //self.bottomImageViewConstraint.constant -= 2 * parallaxIndex
        
        //self.imageViewInitialTopConstraint = self.bottomImageViewConstraint.constant
        //self.imageViewInitialBottomConstraint = self.bottomImageViewConstraint.constant
        self.clipsToBounds = true
        
        guestsCountBubble.clipsToBounds = true
        guestsCountBubble.layer.cornerRadius = guestsCountBubble.frame.height / 2
        
        guestsCountBubble.layer.borderColor = UIColor.white.cgColor
        guestsCountBubble.layer.borderWidth = 1.5
        
        guestIcon1.clipsToBounds = true
        guestIcon1.layer.cornerRadius = guestIcon1.frame.height / 2
        
        guestIcon2.clipsToBounds = true
        guestIcon2.layer.cornerRadius = guestIcon2.frame.height / 2
        
        guestIcon3.clipsToBounds = true
        guestIcon3.layer.cornerRadius = guestIcon3.frame.height / 2
        
        guestIcon4.clipsToBounds = true
        guestIcon4.layer.cornerRadius = guestIcon4.frame.height / 2
        
        guestIcon5.clipsToBounds = true
        guestIcon5.layer.cornerRadius = guestIcon5.frame.height / 2
        
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.5
        
        distanceBlurBox.layer.cornerRadius = 2.0
        distanceBlurBox.clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.frame = gv.bounds
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0)
        let dark = UIColor(white: 0.0, alpha: 0.65)
        gradient.colors = [dark.cgColor, UIColor.clear.cgColor]
        gv.layer.insertSublayer(gradient, at: 0)
        

        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }

    @IBOutlet weak var distanceBlurBox: UIVisualEffectView!
    
    func setCellLocation(location:Location) {
        
        self.location = location
        titleLabel.text = location.getName()
        //addressLabel.text = location.getShortAddress()
        backgroundImage.image = nil
        loadLocationImage(location.getImageURL(), completion: { image, fromCache in
            if !fromCache {
                self.backgroundImage.alpha = 0.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.backgroundImage.alpha = 1.0
                })
            }
            self.backgroundImage.image = image
            
        })
        
        
        let distanceBox = distanceLabel.superview!
        if location.isActive() {
            distanceBlurBox.effect = UIBlurEffect(style: .light)
            //distanceLabel.superview!.backgroundColor = UIColor.white
            addressLabel.text = "Nearby"
            distanceLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)//UIFont(name: "Avenir-Heavy", size: 12.0)
        } else {
            distanceBlurBox.effect = UIBlurEffect(style: .dark)
           // distanceLabel.superview!.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            distanceLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFontWeightLight)//UIFont(name: "Avenir-Medium", size: 11.0)
            if let distance = location.getDistance() {
                addressLabel.text = getDistanceString(distance: distance)
                
            } else {
                distanceBox.isHidden = true
            }
        }
        setMultipleGuests()
    }
    
    var guestIcons:[UIImageView]?
    
    var x:CGFloat!
    
    var currentVisitors:[String]?
    
    func setMultipleGuests() {
        
        
        
        let visitors = location!.getVisitors()
        

        if currentVisitors != nil {
            if currentVisitors! == visitors {
                return
            }
        }
        
        check += 1
        if check > 5 {
            check = 0
            
        }
        
        currentVisitors = visitors
        
        if guestIcons != nil {
            for icon in guestIcons! {
                icon.removeFromSuperview()
            }
        }
        gradient?.removeFromSuperlayer()
        
        var max = 5
        if visitors.count <= max {
            max = visitors.count

        }
        
        guestsCountLabel.text = "\(visitors.count)"
        
        
        if visitors.count > 0 {
            guestsCountBubble.isHidden = false
        } else {
            guestsCountBubble.isHidden = true
        }
        
        guestIcon1.isHidden = true
        guestIcon2.isHidden = true
        guestIcon3.isHidden = true
        guestIcon4.isHidden = true
        guestIcon5.isHidden = true
        
        for i in 0..<max {
            let visitor = visitors[i]
            if i == 0 {
                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {

                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon1.isHidden = false
                                self.guestIcon1.image = image
                            }
                        })
                    }
                })
            }
            
            if i == 1 {

                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {
                        
                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon2.isHidden = false
                                self.guestIcon2.image = image
                            }
                        })
                    }
                })
            }
            
            if i == 2 {
                
                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {
                        
                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon3.isHidden = false
                                self.guestIcon3.image = image
                            }
                        })
                    }
                })
            }
            
            if i == 3 {
                
                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {
                        
                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon4.isHidden = false
                                self.guestIcon4.image = image
                            }
                        })
                    }
                })
            }
            
            if i == 4 {
                
                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {
                        
                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon5.isHidden = false
                                self.guestIcon5.image = image
                            }
                        })
                    }
                })
            }
        
        }
        
        switch visitors.count {
        case 1:
            setLeadingConstraints(constant: 8)
            break
        case 2:
            setLeadingConstraints(constant: 2)
            break
        case 3:
            setLeadingConstraints(constant: -4)
            break
        case 4:
            setLeadingConstraints(constant: -8)
            break
        default:
            setLeadingConstraints(constant: -14)
            break
        }

    }
    
    
    func setLeadingConstraints(constant:CGFloat) {
        leading1.constant = constant
        leading2.constant = constant
        leading3.constant = constant
        leading4.constant = constant
        leading5.constant = constant
    }

    
    func setImageViewOffSet(_ tableView: UITableView, indexPath: IndexPath) {
        
//        let cellFrame = tableView.rectForRow(at: indexPath)
//        let cellFrameInTable = tableView.convert(cellFrame, to:tableView.superview)
//        let cellOffset = cellFrameInTable.origin.y + cellFrameInTable.size.height
//        let tableHeight = tableView.bounds.size.height + cellFrameInTable.size.height
//        let cellOffsetFactor = cellOffset / tableHeight
//        self.setOffSet(cellOffsetFactor)
        
    }
    
    func setOffSet(_ offset:CGFloat) {
//        let boundOffset = max(0, min(1, offset))
//        let pixelOffset = (1-boundOffset)*2*parallaxIndex
//        self.topImageViewConstraint.constant = self.imageViewInitialTopConstraint - pixelOffset
//        self.bottomImageViewConstraint.constant = self.imageViewInitialBottomConstraint + pixelOffset
    }
    
    var task:URLSessionDataTask?
    func loadLocationImage(_ _url:String, completion: @escaping (_ image: UIImage, _ fromCache:Bool)->()) {
        if task != nil{
            task!.cancel()
            task = nil
        }
        
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("location-\(self.location!.getKey()).jpg"))
        if let imageFile = UIImage(contentsOfFile: fileURL.path) {
            completion(imageFile, true)
        } else {
            // Otherwise, download image
            let url = URL(string: _url)
            
            task = URLSession.shared.dataTask(with: url!, completionHandler:
                { (data, response, error) in
                    
                    //error
                    if error != nil {
                        if error?._code == -999 {
                            return
                        }
                        print(error?._code)
                        return
                    }
                    
                    if let image = UIImage(data: data!) {
                        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
                            try? jpgData.write(to: fileURL, options: [.atomic])
                        }
                    }
                    
                    DispatchQueue.main.async(execute: {
                        completion(UIImage(data: data!)!, false)
                    })
                    
            })
            
            task?.resume()
        }
    }
}
