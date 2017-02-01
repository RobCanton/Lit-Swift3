//
//  SendLocationViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class SendLocationViewCell: UITableViewCell {

    @IBOutlet weak var locationImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCellLocation(location:Location) {
        self.locationImageView.loadImageAsync(location.getImageURL(), completion: nil)
    }
    
}
