//
//  ListHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ListHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var label: UILabel!
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    var activityIndicator:UIActivityIndicatorView?
    func addActivityIndicator()  {
        activityIndicator?.removeFromSuperview()
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator!.frame = CGRect(x: 0, y: 0, width: 20.0, height: 20.0)
        activityIndicator!.center = label.center
        self.addSubview(activityIndicator!)
        activityIndicator!.startAnimating()
        label.isHidden = true
        
    }
    
    func stopIndicator() {
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        label.isHidden = false
    }

}
