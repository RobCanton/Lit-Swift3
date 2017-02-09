//
//  CommentsView.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentsView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var comments = [Comment]()

    var commentsInteractionHandler:((_ interacting:Bool)->())?
    
    var userTapped:((_ uid:String)->())?
    var tableView:UITableView!
    var divider:UIView!
    required internal init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cleanUp() {
        comments = [Comment]()
        tableView.reloadData()
        divider.isHidden = true
        userTapped = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        let gradient = CAGradientLayer()
        
        gradient.frame = self.bounds 
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.075, 1.0]
        self.layer.mask = gradient
        
        tableView = UITableView(frame: self.bounds)
        
        
        let nib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "commentCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor(white: 0.1, alpha: 0)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.backgroundColor = UIColor.clear//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        self.addSubview(tableView)
        
        divider = UIView(frame: CGRect(x: 8,y: frame.height-1, width: frame.width-16, height: 1))
        divider.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        //self.addSubview(divider)
        divider.isHidden = true
        
        reloadTable()
        scrollBottom(animated: false)
    }
    
    func setTableComments(comments:[Comment], animated:Bool)
    {
        self.comments = comments
        if self.comments.count > 0 {
            divider.isHidden = false
        } else {
            divider.isHidden = true
        }
        reloadTable()
        scrollBottom(animated: animated)
    }

    
    func reloadTable() {
        
        tableView.reloadData()
        
        let containerHeight = self.bounds.height
        let tableHeight = tableView.contentSize.height

        if tableHeight < containerHeight {
            tableView.frame.origin.y = containerHeight - tableHeight
            tableView.isScrollEnabled = false
        } else {
            tableView.frame.origin.y = 0
            tableView.isScrollEnabled = true
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let comment = comments[indexPath.row]
        let text = comment.getText()
        let width = tableView.frame.width - (8 + 8 + 8 + 32)
        let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular))
        let height2 = size.height + 26  // +8 for some bio padding
        return height2
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
        cell.setContent(comment: comments[indexPath.row])
        cell.authorTapped = userTapped
        
        if showTimeStamps {
            cell.timeLabel.isHidden = false
        } else {
            cell.timeLabel.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CommentCell
        cell.toggleTimeStamp()
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func scrollBottom(animated:Bool) {
        if comments.count > 0 {
            let lastIndex = IndexPath(row: comments.count-1, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: UITableViewScrollPosition.bottom, animated: animated)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //commentsInteractionHandler?(true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //commentsInteractionHandler?(false)
    }
    
    var showTimeStamps = false
    
    func showTimeLabels(visible:Bool) {
        showTimeStamps = visible
        for cell in tableView.visibleCells {
            let c = cell as! CommentCell
            if showTimeStamps {
                c.timeLabel.isHidden = false
            } else {
                c.timeLabel.isHidden = true
            }
            
        }
    }
    
    
}
