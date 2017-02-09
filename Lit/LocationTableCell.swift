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
    
    @IBOutlet weak var topImageViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomImageViewConstraint: NSLayoutConstraint!

    @IBOutlet weak var guestIconsView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var guestsCountBubble: UIView!
    @IBOutlet weak var guestsCountLabel: UILabel!
    
    @IBOutlet weak var gradientView: UIView!
    

    var imageViewInitialTopConstraint: CGFloat!
    var imageViewInitialBottomConstraint: CGFloat!
    let parallaxIndex: CGFloat = 18
    var location:Location?
    var fadeView:UIView!
    
    var gradient:CAGradientLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.bottomImageViewConstraint.constant -= 2 * parallaxIndex
        
        self.imageViewInitialTopConstraint = self.bottomImageViewConstraint.constant
        self.imageViewInitialBottomConstraint = self.bottomImageViewConstraint.constant
        self.clipsToBounds = true
        
        guestsCountBubble.clipsToBounds = true
        guestsCountBubble.layer.cornerRadius = guestsCountBubble.frame.height / 2
        
        titleLabel.superview!.layer.cornerRadius = 1.5
        titleLabel.superview!.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setCellLocation(_ location:Location) {
        self.location = location
        titleLabel.text = location.getName()
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
            titleLabel.superview!.backgroundColor = accentColor
            distanceLabel.text = "Nearby"
            distanceLabel.font = UIFont(name: "Avenir-Heavy", size: 12.0)
        } else {
            titleLabel.superview!.backgroundColor = UIColor.black
            distanceLabel.font = UIFont(name: "Avenir-Medium", size: 11.0)
            if let distance = location.getDistance() {
                distanceLabel.text = getDistanceString(distance: distance)
                
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
        
        currentVisitors = visitors
        
        if guestIcons != nil {
            for icon in guestIcons! {
                icon.removeFromSuperview()
            }
        }
        gradient?.removeFromSuperlayer()
        
        x = guestsCountBubble.frame.origin.x + guestsCountBubble.frame.width - (guestsCountBubble.frame.height * 0.2)
        guestIcons = [UIImageView]()
        
        
        
        if visitors.count > 0 {
            guestsCountBubble.isHidden = false
            guestsCountLabel.text = "\(visitors.count)"

            for visitor in visitors {
                
                UserService.getUser(visitor, completion: { user in
                    if user != nil {
                        loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                            if image != nil {
                                self.addNewGuest(image!)
                            }
                        })
                    }
                })
            }
            let sideLength = guestIconsView.frame.height * 0.8
            let gradientWidth = guestsCountBubble.frame.origin.x * 4.0 + guestsCountBubble.frame.width + sideLength * CGFloat(visitors.count + 2)
            gradient = CAGradientLayer()
            gradient!.frame = CGRect(x: 0, y: 0, width: gradientWidth, height: gradientView.bounds.height * 1.25)
            gradient!.startPoint = CGPoint(x: 0, y: 1)
            gradient!.endPoint = CGPoint(x: 1, y: 0)
            gradient!.locations = [0.0, 0.5]
            let dark = UIColor(white: 0.0, alpha: 0.65)
            gradient!.colors = [dark.cgColor, UIColor.clear.cgColor]
            gradientView.layer.insertSublayer(gradient!, at: 0)
        } else {
            guestsCountBubble.isHidden = true
        }
    }
    
    func addNewGuest(_ image:UIImage) {
        
        if guestIcons == nil { return }
        
        let sideLength = guestIconsView.frame.height
        
        if x > self.bounds.width - sideLength {
            return
        }
        
        let frame = CGRect(x: x, y: 0, width: sideLength, height: sideLength)
        let guestIcon = UIImageView(frame: frame)
        guestIcon.image = image
        guestIcon.layer.cornerRadius = guestIcon.frame.width / 2
        guestIcon.clipsToBounds = true
        guestIcon.contentMode = .scaleAspectFill
        
        guestIcons!.append(guestIcon)
        
        if guestIcons!.count > 1{
            guestIconsView.insertSubview(guestIcon, belowSubview: guestIcons![guestIcons!.count - 2])
        } else if guestIcons!.count == 1 {
            guestIconsView.addSubview(guestIcon)
        }
        
        x = guestIcon.frame.origin.x + guestIcon.frame.width * 0.8
    }
    
    func setImageViewOffSet(_ tableView: UITableView, indexPath: IndexPath) {
        
        let cellFrame = tableView.rectForRow(at: indexPath)
        let cellFrameInTable = tableView.convert(cellFrame, to:tableView.superview)
        let cellOffset = cellFrameInTable.origin.y + cellFrameInTable.size.height
        let tableHeight = tableView.bounds.size.height + cellFrameInTable.size.height
        let cellOffsetFactor = cellOffset / tableHeight
        self.setOffSet(cellOffsetFactor)
        
    }
    
    func setOffSet(_ offset:CGFloat) {
        let boundOffset = max(0, min(1, offset))
        let pixelOffset = (1-boundOffset)*2*parallaxIndex
        self.topImageViewConstraint.constant = self.imageViewInitialTopConstraint - pixelOffset
        self.bottomImageViewConstraint.constant = self.imageViewInitialBottomConstraint + pixelOffset
    }
    
    var task:URLSessionDataTask?
    func loadLocationImage(_ _url:String, completion: @escaping (_ image: UIImage, _ fromCache:Bool)->()) {
        if task != nil{
            task!.cancel()
            task = nil
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("location_images").appendingPathComponent("\(self.location!.getKey()).jpg")
        
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
