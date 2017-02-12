//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

class TacoDialogView: MessageView {

    @IBOutlet weak var cardBackgroundView: UIView!

    var tapGesture:UITapGestureRecognizer!
    var longGesture:UILongPressGestureRecognizer!
    var tappedAction:(()->())?
    
    func setMessage() {
        bodyLabel?.text = "You are near Muzik Clubs."
        
        longGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressed))
        longGesture.minimumPressDuration = 0.0

        
        self.addGestureRecognizer(longGesture)
        self.isUserInteractionEnabled = true
    }
    
    func pressed(gesture:UILongPressGestureRecognizer) {
        let state = gesture.state
        print("STATE: \(state)")
        switch state {
        case .began:
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                self.cardBackgroundView.backgroundColor = UIColor.lightGray
            }, completion: nil)
            break
        case .ended:
            //self.backgroundColor =
            tappedAction?()
            break
        case .failed:
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                self.cardBackgroundView.backgroundColor = UIColor.white
            }, completion: nil)
            break
        case .cancelled:
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                self.cardBackgroundView.backgroundColor = UIColor.white
            }, completion: nil)
            break
        default:
            break
        }
    }
    

    
    
}
