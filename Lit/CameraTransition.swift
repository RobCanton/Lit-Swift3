//
//  CameraTransition.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//



import UIKit
import QuartzCore



// MARK: Segue class
class CameraTransition: UIStoryboardSegue {
    
    
    override func perform() {
        animateSwipeDown()
        
    }
    
    
    
    private func animateSwipeDown() {
        let toViewController = destination as! CameraViewController
        let fromViewController = source as! MasterTabBarController
        
        let containerView = fromViewController.view.superview
        let screenBounds = fromViewController.view.bounds
        
        let cameraBtnFrame = fromViewController.cameraButton.frame
        
        let cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))

        cameraButton.frame = CGRect(x: screenBounds.width/2 - cameraBtnFrame.size.width/2, y: screenBounds.height - cameraBtnFrame.height - 8, width: cameraBtnFrame.width, height: cameraBtnFrame.height)
        
        cameraButton.backgroundColor = UIColor.black
        cameraButton.layer.cornerRadius = cameraBtnFrame.height/2
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = fromViewController.cameraButton.layer.borderWidth
        cameraButton.tintColor = UIColor.white

        let definiteBounds = UIScreen.main.bounds
        
        let recordButtonCenter = CGPoint(x: cameraButton.center.x, y: definiteBounds.height - 100)
        
        let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        color.fromValue = cameraButton.layer.borderColor
        color.toValue = UIColor.white.cgColor
        cameraButton.layer.borderColor = UIColor.white.cgColor
        
        let Width:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        Width.fromValue = cameraButton.layer.borderWidth
        Width.toValue = 4.0
        
        cameraButton.layer.borderWidth = 4.0
        
        let both:CAAnimationGroup = CAAnimationGroup()
        both.duration = 0.35
        both.animations = [color,Width]
        both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        cameraButton.layer.add(both, forKey: "color and Width")
        
        let finalToFrame = screenBounds
        let finalFromFrame = finalToFrame.offsetBy(dx: 0, dy: screenBounds.size.height)
        
        //toViewController.view.frame = CGRectOffset(finalToFrame, 0, -screenBounds.size.height)
        containerView?.insertSubview(toViewController.view, at: 0)
        containerView?.addSubview(cameraButton)
        
        
        
        fromViewController.cameraButton.isHidden = true
        
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            //toViewController.view.frame = finalToFrame
            fromViewController.view.frame = finalFromFrame
            cameraButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            cameraButton.center = recordButtonCenter
            cameraButton.backgroundColor = UIColor.clear
        
        }, completion: { finished in
                cameraButton.removeFromSuperview()
                toViewController.recordBtn?.isHidden = false
                fromViewController.cameraButton.isHidden = false
                let fromVC = self.source
                let toVC = self.destination
                fromVC.present(toVC, animated: false, completion: nil)
        })
    }
    
    
}

// MARK: Unwind Segue class
class CameraUnwindTransition: UIStoryboardSegue {
    
    
    override func perform() {
        animateSwipeDown()
        
    }
    
    
    private func animateSwipeDown() {
        let toViewController = destination as! MasterTabBarController
        let fromViewController = source as! CameraViewController

        let containerView = fromViewController.view.superview
        let screenBounds = toViewController.view.bounds
        containerView!.insertSubview(fromViewController.view, at: 0)
        //containerView!.sendSubview(toBack: fromViewController.view)
        let cameraBtnFrame = toViewController.cameraButton.frame
        
        
        let cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        
        cameraButton.frame = CGRect(x: screenBounds.width/2 - cameraBtnFrame.size.width/2, y: screenBounds.height - cameraBtnFrame.height - 8, width: cameraBtnFrame.width, height: cameraBtnFrame.height)
        
        cameraButton.backgroundColor = UIColor.clear
        cameraButton.layer.cornerRadius = cameraBtnFrame.height/2
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = toViewController.cameraButton.layer.borderWidth
        cameraButton.tintColor = UIColor.white
        
        
        cameraButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        let definiteBounds = UIScreen.main.bounds
        
        let recordButtonCenter = CGPoint(x: cameraButton.center.x, y: definiteBounds.height - 100)

        
        let rbc = CGPoint(x: cameraButton.center.x, y: definiteBounds.height - 100)
        cameraButton.center = rbc
        
        let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        color.fromValue = cameraButton.layer.borderColor
        color.toValue = UIColor.white.cgColor
        cameraButton.layer.borderColor = UIColor.white.cgColor
        
        
        
        let Width:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        Width.fromValue = 4.0
        Width.toValue = toViewController.cameraButton.layer.borderWidth
        
        cameraButton.layer.borderWidth = toViewController.cameraButton.layer.borderWidth
        
        let both:CAAnimationGroup = CAAnimationGroup()
        both.duration = 0.35
        both.animations = [color,Width]
        both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        cameraButton.layer.add(both, forKey: "color and Width")
        

        let yo = CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height - screenStatusBarHeight)
        let finalToFrame = yo.offsetBy(dx: 0, dy: screenStatusBarHeight)
        let finalFromFrame = finalToFrame.offsetBy(dx: 0, dy: -screenBounds.size.height)
        
        toViewController.view.frame = finalToFrame.offsetBy(dx: 0, dy: screenBounds.size.height)
        containerView?.addSubview(toViewController.view)
        let cameraViewControllerFrame = fromViewController.view.frame

        let finalCameraFrame = CGRect(x: screenBounds.width/2 - cameraBtnFrame.size.width/2, y: screenBounds.height - cameraBtnFrame.height - 8, width: cameraBtnFrame.width, height: cameraBtnFrame.height)
        
        if fromViewController.recordBtn.isHidden {
            cameraButton.isHidden = true
            toViewController.cameraButton.isHidden = false
        } else {
            cameraButton.isHidden = false
            toViewController.cameraButton.isHidden = true
        }
        
        fromViewController.recordBtn.isHidden = true
        containerView?.addSubview(cameraButton)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            
            cameraButton.transform = CGAffineTransform.identity
            cameraButton.frame = finalCameraFrame
            cameraButton.backgroundColor = UIColor.black
            toViewController.view.frame = finalToFrame
            fromViewController.view.alpha = 0.0
//            fromViewController.view.frame = containerView!.bounds
            }, completion: { finished in
                cameraButton.removeFromSuperview()
                toViewController.cameraButton.isHidden = false
                let fromVC: UIViewController = self.source
                fromVC.dismiss(animated: false, completion: nil)

        })
    }
}

//
//  CustomSegueTransition.swift
//  CustomSegueTest
//
//  Created by Robert Canton on 2017-02-15.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CustomSegueTransition: UIStoryboardSegue {
    override func perform() {
        
        //set the ViewControllers for the animation
        
        let sourceView = self.source.view as! UIView
        let destinationView = self.destination.view as! UIView
        print("PRESENT TRANSITION")
        
        let window = UIApplication.shared.delegate?.window!
        //set the destination View center
        //destinationView.frame = CGRect(x: 0, y: sourceView.frame.height, width: destinationView.frame.width, height: destinationView.frame.height)
        
        // the Views must be in the Window hierarchy, so insert as a subview the destionation above the source
        window?.insertSubview(destinationView, belowSubview: sourceView)
        
        //create UIAnimation- change the views's position when present it
        UIView.animate(withDuration: 3.0, animations: {
            sourceView.frame = CGRect(x: 0, y: sourceView.frame.height, width: destinationView.frame.width, height: destinationView.frame.height)
            //sourceView?.center = CGPoint(x: (sourceView?.center.x)!, y: 0 + 2 * (destinationView?.center.y)!)
            
        }, completion: {
            (value: Bool) in
            self.source.present(self.destination, animated: false, completion: nil)
            
            
        })
    }
}

class CustomUnwindSegueTransition: UIStoryboardSegue {
    override func perform() {
        //set the ViewControllers for the animation
        print("like wut")
        let sourceView = self.source.view as! UIView
        let destinationView = self.destination.view as! UIView
        let window = UIApplication.shared.delegate?.window!
        
        // 1. beloveSubview
        window?.insertSubview(destinationView, aboveSubview: sourceView)
        
        
        //2. y cordinate change
        destinationView.frame = CGRect(x: 0, y: sourceView.frame.height, width: destinationView.frame.width, height: destinationView.frame.height)
        
        
        //3. create UIAnimation- change the views's position when present it
        UIView.animate(withDuration: 0.4,
                       animations: {
                        destinationView.frame = CGRect(x: 0, y: 0, width: destinationView.frame.width, height: destinationView.frame.height)
                        //sourceView?.center = CGPoint(x: (sourceView?.center.x)!, y: 0 - 2 * (destinationView?.center.y)!)
        }, completion: {
            (value: Bool) in
            //4. dismiss
            
            destinationView.removeFromSuperview()
            
            self.source.dismiss(animated: false, completion: nil)
            
        })
        
    }
}

