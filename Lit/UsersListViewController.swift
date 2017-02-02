//
//  UsersListViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import UIKit
import FBSDKCoreKit

//class FacebookFriendsListViewController: UsersListViewController {
//    
//    var fbIds:[String]?
//    
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.title = "Facebook Friends"
//        
//        
//        if fbIds != nil {
//            let done = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(handleDone))
//            self.navigationItem.rightBarButtonItem = done
//            
//            self.navigationItem.setHidesBackButton(true, animated: false)
//            
//            setFacebookFriends()
//        } else {
//            
//
//
//            FacebookGraph.getFacebookFriends({ _userIds in
//                if _userIds.count == 0 {
//                    self.performSegueWithIdentifier("showLit", sender: self)
//                } else {
//                    dispatch_async(dispatch_get_main_queue(), {
//                        self.fbIds = _userIds
//                        self.setFacebookFriends()
//                    })
//                }
//            })
//        }
//    }
//    
//    func setFacebookFriends() {
//        
//        var newFriendsList = [String]()
//        let following = mainStore.state.socialState.following
//        for id in fbIds! {
//            if !following.contains(id) {
//                newFriendsList.append(id)
//            }
//        }
//        self.userIds = newFriendsList
//    }
//    
//    func handleDone() {
//        self.performSegueWithIdentifier("showLit", sender: self)
//    }
//    
//    
//    override  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//    }
//}

class UsersListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    
    var location:Location?
    var uid:String?
    var postKey:String?
    
    var tableView:UITableView!
    
    let cellIdentifier = "userCell"
    var user:User?
    var users = [User]()
    {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var userIds = [String]()
    {
        didSet{
            UserService.getUsers(userIds: userIds, completionHandler: { users in
                self.users = users
            })
        }
    }
    
    var tempIds = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        tableView.reloadData()
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            
            nav.delegate = nav
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        tableView = UITableView(frame:  CGRect(x: 0,y: 0,width: view.frame.width,height: view.frame.height))
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorColor = UIColor(white: 0.25, alpha: 1.0)
        tableView.backgroundColor = UIColor.clear

        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        
        tableView.reloadData()
        view.backgroundColor = UIColor.clear
        
        tableView.backgroundColor = UIColor.black
        view.backgroundColor = UIColor.black
        
        if tempIds.count > 0 {
            userIds = tempIds
        }
        
        print("ids: \(userIds)")
    }
    
    func unfollowHandler(user:User) {
        let actionSheet = UIAlertController(title: nil, message: "Unfollow \(user.getDisplayName())?", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Unfollow", style: .destructive)
        { action -> Void in
            
            UserService.unfollowUser(uid: user.getUserId())
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! UserViewCell
        cell.setupUser(uid: users[indexPath.item].getUserId())
        cell.unfollowHandler = unfollowHandler
        let labelX = cell.usernameLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let controller = UserProfileViewController()
        controller.uid = users[indexPath.row].getUserId()
        self.navigationController?.pushViewController(controller, animated: true)
        
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    

    
    func addDoneButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        self.navigationItem.rightBarButtonItem  = doneButton
    }
    
    
    
    func doneTapped() {
        self.performSegue(withIdentifier: "showLit", sender: self)
    }
    

    


}
