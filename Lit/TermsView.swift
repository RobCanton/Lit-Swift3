//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

class TermsView: MessageView {

    @IBOutlet weak var cardBackgroundView: UIView!

    var tapGesture:UITapGestureRecognizer!

    var handleCancel:(()->())?
    var handleAgree:(()->())?
    
    var handleTerms:(()->())?
    var handlePrivacy:(()->())?

    
    func setup() {
        //self.isUserInteractionEnabled = false
//        let terms = ActiveType.custom(pattern: "\\sTerms of Use\\b") //Regex that looks for "with"
//        let privacy = ActiveType.custom(pattern: "\\sPrivacy Policy\\b")
//        

        
    }
    
    @IBAction func handleTerms(_ sender: Any) {
        handleTerms?()
    }
    
    @IBAction func handlePrivacy(_ sender: Any) {
       handlePrivacy?()
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        handleCancel?()
    }

    @IBAction func handleAgree(_ sender: Any) {
        handleAgree?()
    }
    
    
}
