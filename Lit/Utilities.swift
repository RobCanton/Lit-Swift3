//
//  Utilities.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import AVFoundation


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


let videoCache = NSCache<NSString, AnyObject>()


func loadVideoFromCache(key:String) -> NSData? {
    if let cachedData = videoCache.object(forKey: key as NSString) as? NSData {
        return cachedData
    }
    return nil
}

func saveVideoInCache(key:String, data:NSData) {
    videoCache.setObject(data, forKey: key as NSString)
}

func downloadVideoWithKey(key:String, author:String, completion: @escaping (_ data:NSData)->()) {
    let videoRef = FIRStorage.storage().reference().child("user_uploads/videos/\(author)/\(key)")
    
    // Download in memory with a maximum allowed size of 2MB (2 * 1024 * 1024 bytes)
    videoRef.data(withMaxSize: 2 * 1024 * 1024) { (data, error) -> Void in
        if (error != nil) {
            print("Error - \(error!.localizedDescription)")
        } else {
            return completion(data! as NSData)
        }
    }
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

func getDistanceString(distance:Double) -> String {
    if distance < 0.5 {
        // meters
        let meters = Double(round(distance * 1000)/1)
        return "\(meters) m"
    } else {
        let rounded = Double(round(10*distance)/10)
        return "\(rounded) km"
    }
}

func generateVideoStill(asset:AVAsset, time:CMTime) -> UIImage?{
    do {
        
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        return image
    } catch let error as NSError {
        print("Error generating thumbnail: \(error)")
        return nil
    }
}
