//
//  Utilities.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit


let imageCache = NSCache<NSString, UIImage>()

func loadImageUsingCacheWithURL(_ _url:String, completion: @escaping (_ image:UIImage?, _ fromCache:Bool)->()) {
    // Check for cached image
    if let cachedImage = imageCache.object(forKey: _url as NSString) {
        return completion(cachedImage, true)
    } else {
        downloadImageWithURLString(_url, completion: completion)
    }
}

func downloadImageWithURLString(_ _url:String, completion: @escaping (_ image:UIImage?, _ fromCache:Bool)->()) {

    let url = URL(string: _url)
    
    URLSession.shared.dataTask(with: url!, completionHandler:
        { (data, response, error) in
            
            //error
            if error != nil {
                if error?._code == -999 {
                    return
                }
                //print(error?.code)
                return completion(nil, false)
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: _url as NSString)
                }
                
                let image = UIImage(data: data!)
                return completion(image!, false)
            }
            
    }).resume()
}

func createDirectory(_ dirName:String) {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dataPath = documentsDirectory.appendingPathComponent(dirName)
    
    do {
        try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
        print("Error creating directory: \(error.localizedDescription)")
    }
}

var screenStatusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.height
}
