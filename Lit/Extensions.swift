//
//  Extensions.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    
    func loadImageAsync(_ url:String, completion:((_ fromCache:Bool)->())?) {
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            self.image = image
            completion?(fromCache)
        })
    }
}

extension Date
{
    
    func timeStringSinceNow() -> String
    {
        let calendar = Calendar.current
        
        let date = Date()
        let days = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        if days >= 365 {
            return "\(days / 365)y"
        }
        
        if days >= 7 {
            return "\(days / 7)w"
        }
        
        if days > 0 {
            return "\(days)d"
        }
        else if hour > 0 {
            return "\(hour)h"
        }
        else if minutes > 0 {
            return "\(minutes)m"
        }
        return "Now"
        //return "\(components.second)s"
    }
    
    func timeStringSinceNowWithAgo() -> String
    {
        let timeStr = timeStringSinceNow()
        if timeStr == "Now" {
            return timeStr
        }
        
        return "\(timeStr) ago"
    }
    
}

extension UILabel {
    func styleProfileBlockText(count:Int, text:String, color:UIColor, color2:UIColor) {
        self.numberOfLines = 2
        self.textAlignment = .center
        
        let str = "\(count)\n\(text)"
        let font = UIFont(name: "AvenirNext-Regular", size: 12)
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : color,
            ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let countStr = "\(count)"
        if let range = str.range(of: countStr) {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont(name: "AvenirNext-Medium", size: 16)!,
                NSForegroundColorAttributeName : color2
            ]
            title.addAttributes(a, range: NSRange(location: index, length: countStr.characters.count))
        }
        
        
        self.attributedText = title
    }
    
    public class func size(withText text: String, forWidth width: CGFloat, withFont font: UIFont) -> CGSize {
        let measurementLabel = UILabel()
        measurementLabel.font = font
        measurementLabel.text = text
        measurementLabel.numberOfLines = 0
        measurementLabel.lineBreakMode = .byWordWrapping
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        measurementLabel.widthAnchor.constraint(equalToConstant: width).isActive = true
        return measurementLabel.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
}
