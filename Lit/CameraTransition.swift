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
        
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
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
        let screenBounds = fromViewController.view.bounds
        
        
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
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            cameraButton.transform = CGAffineTransform.identity
            cameraButton.frame = finalCameraFrame
            cameraButton.backgroundColor = UIColor.black
            toViewController.view.frame = finalToFrame
            fromViewController.view.alpha = 0.0
            }, completion: { finished in
                cameraButton.removeFromSuperview()
                toViewController.cameraButton.isHidden = false
                let fromVC: UIViewController = self.source
                fromVC.dismiss(animated: false, completion: nil)

        })
    }
    
    
}
