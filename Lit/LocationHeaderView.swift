//
//  LocationHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class LocationHeaderView: UIView {
    
    @IBOutlet weak var subtitle: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var descriptionLabel: UILabel!
    var backHandler:(()->())?
    var contactHandler:(()->())?
    @IBAction func handleBackButton(_ sender: Any) {
        backHandler?()
    }
    @IBOutlet weak var contactButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        contactButton.layer.cornerRadius = 2.0
        contactButton.clipsToBounds = true
        contactButton.layer.borderWidth = 1.0
        contactButton.layer.borderColor = UIColor.white.cgColor
        contactButton.isHidden = false
        
        contactButton.setTitleColor(UIColor.white, for: .normal)
        contactButton.setTitleColor(UIColor.gray, for: .selected)
        
    }

    @IBAction func handleContact(_ sender: Any) {
        contactHandler?()
    }
    
    
    func setLocationInfo(location:Location) {
        
        titleLabel.text = location.getName()
        var distanceStr = ""
        if let distance = location.getDistance() {
            distanceStr = " · \(getDistanceString(distance: distance))"
        }
        subtitle.text = location.getType()
        descriptionLabel.text = location.desc
        
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("location-\(location.getKey()).jpg"))
        
        if let imageFile = UIImage(contentsOfFile: fileURL.path) {
           imageView.image = imageFile
        } else {
            imageView.loadImageAsync(location.getImageURL(), completion: nil)
        }
        
        if location.phone == nil && location.website == nil && location.email == nil {
            contactButton.isHidden = true
        } else {
            contactButton.isHidden = false
        }
    }

}

extension UIButton {
    func centerButtonImageAndTitle() {
        let spacing: CGFloat = 5
        let titleSize = self.titleLabel!.frame.size
        let imageSize = self.imageView!.frame.size
        
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(imageSize.height + spacing), right: 0)
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing), left: -imageSize.width/2, bottom: 0, right: -titleSize.width)
    }
    

    
    func adjustImageAndTitleOffsetsForButton () {
        
        let spacing: CGFloat = 6.0
        
        let imageSize = self.imageView!.frame.size
        
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -(imageSize.height + spacing), 0)
        
        let titleSize = self.titleLabel!.frame.size
        
        self.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0, 0, -titleSize.width)
    }
}
