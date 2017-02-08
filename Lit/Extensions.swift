//
//  Extensions.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func applyShadow(radius:CGFloat, opacity:Float, height:CGFloat, shouldRasterize:Bool) {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: height)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.shouldRasterize = shouldRasterize
    }
}
extension UIImageView {
    
    func loadImageAsync(_ url:String, completion:((_ fromCache:Bool)->())?) {
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            self.image = image
            completion?(fromCache)
        })
    }
}

extension UIImage{
    convenience init(view: UIView) {
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage)!)
        
    }
}

extension Date
{
    
    func timeStringSinceNow() -> String
    {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: self, to: Date())
        
        if components.day! >= 365 {
            return "\(components.day! / 365)y"
        }
        
        if components.day! >= 7 {
            return "\(components.day! / 7)w"
        }
        
        if components.day! > 0 {
            return "\(components.day!)d"
        }
        else if components.hour! > 0 {
            return "\(components.hour!)h"
        }
        else if components.minute! > 0 {
            return "\(components.minute!)m"
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

extension UITextView {
    
    func fitHeightToContent() {
        let fixedWidth = self.frame.size.width
        self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = self.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        self.frame = newFrame;
    }
}

public extension UISearchBar {
    
    public func setTextColor(color: UIColor) {
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf.textColor = color
    }
}

// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIVisualEffectView {
    
    public func pauseAnimation(delay: Double) {
        let time = delay + CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, time, 0, 0, 0, { timer in
            let layer = self.layer
            let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
            layer.speed = 0.0
            layer.timeOffset = pausedTime
        })
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, CFRunLoopMode.commonModes)
    }
    
    public func resumeAnimation() {
        let pausedTime  = layer.timeOffset
        
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
    }
    
    public func removeAnimation() {
        layer.removeAllAnimations()
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
    }
}
