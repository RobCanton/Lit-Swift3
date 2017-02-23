//
//  MasterNavigationController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class MasterNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.interactivePopGestureRecognizer?.delegate = self
        self.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
