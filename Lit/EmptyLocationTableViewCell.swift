//
//  EmptyLocationTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-03-01.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class EmptyLocationTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let ref = UserService.ref.child("config/client/messages/current_available_cities")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let message = snapshot.value as? String {
                self.label.text = message
            }
        })
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
