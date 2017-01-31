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
    
    func loadImageAsync(_ url:String, completion:(()->())?) {
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            self.image = image
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
