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


let guestCountMax = 7


class LocationTableCell: UITableViewCell {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var extraGuestCountLabel: UILabel!
    @IBOutlet weak var infoView: UIView!

    @IBOutlet weak var infoHeight: NSLayoutConstraint!

    
    @IBOutlet weak var guestIcon1: UIImageView!
    @IBOutlet weak var guestIcon2: UIImageView!
    @IBOutlet weak var guestIcon3: UIImageView!
    @IBOutlet weak var guestIcon4: UIImageView!
    @IBOutlet weak var guestIcon5: UIImageView!
    
    @IBOutlet weak var guestIcon6: UIImageView!
    @IBOutlet weak var guestIcon7: UIImageView!
    
    @IBOutlet weak var leading2: NSLayoutConstraint!
    @IBOutlet weak var leading3: NSLayoutConstraint!
    @IBOutlet weak var leading4: NSLayoutConstraint!
    @IBOutlet weak var leading5: NSLayoutConstraint!
    @IBOutlet weak var leading6: NSLayoutConstraint!
    @IBOutlet weak var leading7: NSLayoutConstraint!
    
    var imageViewInitialTopConstraint: CGFloat!
    var imageViewInitialBottomConstraint: CGFloat!
    let parallaxIndex: CGFloat = 18
    var location:Location?
    var fadeView:UIView!
    var gradient:CAGradientLayer?
    var check = 0
    
    let iconBorderWidth:CGFloat = 1.0

    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.clipsToBounds = true
        
        
        
        guestIcon1.clipsToBounds = true
        guestIcon1.layer.cornerRadius = guestIcon1.frame.height / 2
        guestIcon1.layer.borderColor = UIColor.black.cgColor
        guestIcon1.layer.borderWidth = iconBorderWidth
        
        guestIcon2.clipsToBounds = true
        guestIcon2.layer.cornerRadius = guestIcon2.frame.height / 2
        guestIcon2.layer.borderColor = UIColor.black.cgColor
        guestIcon2.layer.borderWidth = iconBorderWidth
        
        guestIcon3.clipsToBounds = true
        guestIcon3.layer.cornerRadius = guestIcon3.frame.height / 2
        guestIcon3.layer.borderColor = UIColor.black.cgColor
        guestIcon3.layer.borderWidth = iconBorderWidth
        
        guestIcon4.clipsToBounds = true
        guestIcon4.layer.cornerRadius = guestIcon4.frame.height / 2
        guestIcon4.layer.borderColor = UIColor.black.cgColor
        guestIcon4.layer.borderWidth = iconBorderWidth
        
        guestIcon5.clipsToBounds = true
        guestIcon5.layer.cornerRadius = guestIcon5.frame.height / 2
        guestIcon5.layer.borderColor = UIColor.black.cgColor
        guestIcon5.layer.borderWidth = iconBorderWidth
        
        guestIcon6.clipsToBounds = true
        guestIcon6.layer.cornerRadius = guestIcon5.frame.height / 2
        guestIcon6.layer.borderColor = UIColor.black.cgColor
        guestIcon6.layer.borderWidth = iconBorderWidth
        
        guestIcon7.clipsToBounds = true
        guestIcon7.layer.cornerRadius = guestIcon5.frame.height / 2
        guestIcon7.layer.borderColor = UIColor.black.cgColor
        guestIcon7.layer.borderWidth = iconBorderWidth
        
        
        self.addressLabel.superview!.layer.cornerRadius = 2.0
        self.addressLabel.superview!.clipsToBounds = true
        
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }

    
    @IBOutlet weak var distanceTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var distanceTrailingConstraint: NSLayoutConstraint!
    
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
        
        if location.getVisitors().count > 0 {
            infoHeight.constant = 60 + 36
        } else {
            infoHeight.constant = 60
        }
        
        
        if location.getVisitors().count > guestCountMax {
            extraGuestCountLabel.text = "+\(location.getVisitors().count - guestCountMax)"
        } else {
            extraGuestCountLabel.text = ""
        }
        
        if location.isActive() {
            distanceTopConstraint.constant = 4.0
            distanceTrailingConstraint.constant = 6.0
            addressLabel.superview!.backgroundColor = UIColor.white
            addressLabel.text = "Nearby"
            addressLabel.textColor = UIColor.black
            addressLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFontWeightSemibold)//UIFont(name: "Avenir-Heavy", size: 12.0)
        } else {
            distanceTopConstraint.constant = 0
            distanceTrailingConstraint.constant = 0
            addressLabel.textColor = UIColor.white
            addressLabel.superview!.backgroundColor = UIColor.black
            addressLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFontWeightLight)//UIFont(name: "Avenir-Medium", size: 11.0)
            if let distance = location.getDistance() {
                addressLabel.text = getDistanceString(distance: distance)
                
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
        
        
        var max = guestCountMax
        if visitors.count <= max {
            max = visitors.count

        }

        
        guestIcon1.isHidden = true
        guestIcon2.isHidden = true
        guestIcon3.isHidden = true
        guestIcon4.isHidden = true
        guestIcon5.isHidden = true
        guestIcon6.isHidden = true
        guestIcon7.isHidden = true
        
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
            
            if i == 5 {
                
                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {
                        
                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon6.isHidden = false
                                self.guestIcon6.image = image
                            }
                        })
                    }
                })
            }
            
            if i == 6 {
                
                UserService.getUser(visitor, check: check, completion: { user, check in
                    if user != nil && self.check == check {
                        
                        loadImageCheckingCache(withUrl: user!.getImageUrl(), check: check, completion: { image, fromCache, check in
                            if image != nil && self.check == check {
                                self.guestIcon7.isHidden = false
                                self.guestIcon7.image = image
                            }
                        })
                    }
                })
            }
 
        }
        
        switch visitors.count {
        case 1:
            setLeadingConstraints(constant: 3)
            break
        case 2:
            setLeadingConstraints(constant: 3)
            break
        case 3:
            setLeadingConstraints(constant: 3)
            break
        case 4:
            setLeadingConstraints(constant: -3)
            break
        case 5:
            setLeadingConstraints(constant: -6)
            break
        case 6:
            setLeadingConstraints(constant: -9)
            break
        default:
            setLeadingConstraints(constant: -12)
            break
         }
        
    }
    
    
    func setLeadingConstraints(constant:CGFloat) {
        leading2.constant = constant
        leading3.constant = constant
        leading4.constant = constant
        leading5.constant = constant
        leading6.constant = constant
        leading7.constant = constant
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
