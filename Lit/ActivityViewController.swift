////
////  ActivityViewController.swift
////  Lit
////
////  Created by Robert Canton on 2016-09-12.
////  Copyright © 2016 Robert Canton. All rights reserved.
////
//
//import UIKit
//import ReSwift
//import Firebase
//
//class ActivityViewController: UITableViewController, UISearchBarDelegate {
//    
//    var myStory:UserStory?
//    var myStoryKeys = [String]()
//    var userStories = [UserStory]()
//    var postKeys = [String]()
//    
//    var storiesDictionary = [String:[String]]()
//    
//    var returningCell:UserStoryTableViewCell?
//    
//    var myStoryRef:FIRDatabaseReference?
//    var responseRef:FIRDatabaseReference?
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        requestActivity()
//        listenToMyStory()
//        listenToActivityResponse()
//        
//        if statusBarShouldHide {
//            UIView.animateWithDuration(0.3, animations: {
//                self.statusBarShouldHide = false
//                self.setNeedsStatusBarAppearanceUpdate()
//            })
//        }
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(handleEnterForeground), name:
//            UIApplicationWillEnterForegroundNotification, object: nil)
//        
//    }
//    
//    var statusBarShouldHide = false
//    
//    override func viewWillDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        myStoryRef?.removeAllObservers()
//        responseRef?.removeAllObservers()
//        
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
//    
//    func handleEnterForeground() {
//        myStory?.determineState()
//        for story in self.userStories {
//            story.determineState()
//        }
//        tableView?.reloadData()
//    }
//    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        if let tabBar = self.tabBarController as? PopUpTabBarController {
//            tabBar.setTabBarVisible(true, animated: true)
//        }
//        
//        if let nav = navigationController as? MasterNavigationController {
//            nav.setNavigationBarHidden(false, animated: true)
//            nav.delegate = nav
//        }
//        
//        if returningCell != nil {
//            returningCell!.activate(true)
//            returningCell = nil
//        }
//    }
//    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
//        self.setNeedsStatusBarAppearanceUpdate()
//    }
//    
//    @IBAction func showUserSearch(sender: AnyObject) {
//        
//        let controller = UIStoryboard(name: "UserSearchViewController", bundle: nil)
//            .instantiateViewControllerWithIdentifier("UserSearchViewController")
//        self.navigationController?.pushViewController(controller, animated: true)
//        
//    }
//    
//    func listenToMyStory() {
//        let uid = mainStore.state.userState.uid
//        myStoryRef = FirebaseService.ref.child("users/activity/\(uid)")
//        myStoryRef?.removeAllObservers()
//        myStoryRef?.observeEventType(.Value, withBlock: { snapshot in
//            var itemKeys = [String]()
//            var timestamp:Double!
//            for upload in snapshot.children {
//                let uploadSnap = upload as! FIRDataSnapshot
//                itemKeys.append(uploadSnap.key)
//                timestamp = uploadSnap.value! as! Double
//            }
//
//            if self.myStoryKeys == itemKeys {
//            } else {
//                if itemKeys.count > 0 {
//                    self.myStoryKeys = itemKeys
//                    let myStory = UserStory(user_id: uid, postKeys: self.myStoryKeys, timestamp: timestamp)
//                    self.myStory = myStory
//                    
//                } else{
//                    self.myStory = nil
//                }
//                self.tableView.reloadData()
//            }
//        })
//    }
//
//    
//    func requestActivity() {
//        let uid = mainStore.state.userState.uid
//        let ref = FirebaseService.ref.child("api/requests/activity/\(uid)")
//        ref.setValue(true)
//    }
//    
//    func listenToActivityResponse() {
//        let uid = mainStore.state.userState.uid
//        responseRef = FirebaseService.ref.child("api/responses/activity/\(uid)")
//        responseRef?.removeAllObservers()
//        responseRef?.observeEventType(.Value, withBlock: { snapshot in
//            var tempDictionary = [String:[String]]()
//            var timestamps = [String:Double]()
//            for user in snapshot.children {
//                
//                let userSnap = user as! FIRDataSnapshot
//                var postKeys = [String]()
//                var timestamp:Double!
//                
//                for post in userSnap.children {
//                    let postSnap = post as! FIRDataSnapshot
//                    postKeys.append(postSnap.key)
//                    timestamp = postSnap.value! as! Double
//                }
//                
//                tempDictionary[userSnap.key] = postKeys
//                timestamps[userSnap.key] = timestamp
//                
//            }
//            
//            self.crossCheckStories(tempDictionary, timestamps: timestamps)
//
//        })
//    }
//    
//    
//    func crossCheckStories(tempDictionary:[String:[String]], timestamps:[String:Double]) {
//        
//        if NSDictionary(dictionary: storiesDictionary).isEqualToDictionary(tempDictionary) {
//
//        } else {
//            storiesDictionary = tempDictionary
//            var stories = [UserStory]()
//            for (uid, itemKeys) in storiesDictionary {
//                let story = UserStory(user_id: uid, postKeys: itemKeys, timestamp: timestamps[uid]!)
//                stories.append(story)
//            }
//            
//            stories.sortInPlace({
//                return $0 > $1
//            })
//            
//            
//            for i in 0..<stories.count {
//                let story = stories[i]
//                if story.getUserId() == mainStore.state.userState.uid {
//                    stories.removeAtIndex(i)
//                    stories.insert(story, atIndex: 0)
//                }
//            }
//            
//            self.userStories = stories
//        }
//        
//        for story in self.userStories {
//            story.determineState()
//        }
//        tableView?.reloadData()
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.navigationController!.navigationBar.titleTextAttributes =
//            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!,
//             NSForegroundColorAttributeName: UIColor.whiteColor()]
//        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
//        self.automaticallyAdjustsScrollViewInsets = false
//        
//        
//        let nib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
//        tableView.registerNib(nib, forCellReuseIdentifier: "UserStoryCell")
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.bounces = true
//        tableView.pagingEnabled = false
//        tableView.showsVerticalScrollIndicator = false
//        tableView.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 160))
//        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
//        tableView!.reloadData()
//        
//    }
//    
//    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        searchBar.resignFirstResponder()
//    }
//    
//    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        searchBar.resignFirstResponder()
//    }
//    
//    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 2
//    }
//    
//    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        
//        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
//
//        if section == 1 && userStories.count > 0 {
//            headerView.hidden = false
//            headerView.label.text = "FOLLOWING"
//        }
//        
//        return headerView
//    }
//    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        if section == 1 && userStories.count > 0 {
//            return 34
//        }
//        return 0
//    }
//    
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        
//        switch indexPath.section {
//        default:
//            return 76
//        }
//    }
//    
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch section {
//        case 0:
//            return 1
//        case 1:
//            return userStories.count
//        default:
//            return 0
//        }
//        
//    }
//    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        if indexPath.section == 0 {
//            let cell = tableView.dequeueReusableCellWithIdentifier("UserStoryCell", forIndexPath: indexPath) as! UserStoryTableViewCell
//            if myStory != nil {
//               cell.setUserStory(myStory!, useUsername: false)
//            } else {
//                cell.setToEmptyMyStory()
//            }
//            return cell
//        } else {
//            let cell = tableView.dequeueReusableCellWithIdentifier("UserStoryCell", forIndexPath: indexPath) as! UserStoryTableViewCell
//            cell.setUserStory(userStories[indexPath.item], useUsername: true)
//            return cell
//        }
//    }
//    
//    override func prefersStatusBarHidden() -> Bool {
//        return statusBarShouldHide
//    }
//    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return .LightContent
//    }
//    
//    let transitionController: TransitionController = TransitionController()
//    var selectedIndexPath: NSIndexPath!
//    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//
//        if indexPath.section == 0 {
//            if let story = myStory {
//                
//                if story.state == .ContentLoaded {
//                    presentStory(indexPath)
//                } else {
//                    story.downloadStory()
//                }
//            } else {
//                if let tabBar = self.tabBarController as? PopUpTabBarController {
//                    tabBar.presentCamera()
//                }
//            }
//        } else if indexPath.section == 1 {
//            let story = userStories[indexPath.item]
//            if story.state == .ContentLoaded {
//                presentStory(indexPath)
//            } else {
//                story.downloadStory()
//            }
//        }
//
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//    }
//    
//    func presentStory(indexPath:NSIndexPath) {
//        self.selectedIndexPath = indexPath
//        
//        let presentedViewController: StoriesViewController = StoriesViewController()
//        presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
//        if indexPath.section == 0 {
//            presentedViewController.userStories = [myStory!]
//        } else {
//            presentedViewController.userStories = userStories
//        }
//        presentedViewController.transitionController = self.transitionController
//        let i = NSIndexPath(forItem: indexPath.row, inSection: 0)
//        self.transitionController.userInfo = ["destinationIndexPath": i, "initialIndexPath": indexPath]
//
//        if let navigationController = self.navigationController {
//            statusBarShouldHide = true
//            // Set transitionController as a navigation controller delegate and push.
//            navigationController.delegate = transitionController
//            transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
//            
//        }
//    }
//}
//
//extension ActivityViewController: View2ViewTransitionPresenting {
//    
//    func initialFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
//        
//        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath else {
//            return CGRect.zero
//        }
//        if indexPath.section == 0 {
//            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
//            let image_frame = cell.contentImageView.frame
//            let image_height = image_frame.height
//            let margin = (cell.frame.height - image_height) / 2
//            let x = cell.frame.origin.x + 20
//            
//            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
//            
//            let y = cell.frame.origin.y + 12 + navHeight
//            
//            let rect = CGRectMake(x,y,image_height, image_height)
//            return self.tableView!.convertRect(rect, toView: self.tableView!.superview)
//
//        } else {
//            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
//            let image_frame = cell.contentImageView.frame
//            let image_height = image_frame.height
//            let margin = (cell.frame.height - image_height) / 2
//            let x = cell.frame.origin.x + 20
//            
//            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
//            
//            let y = cell.frame.origin.y + 12 + navHeight
//            
//            let rect = CGRectMake(x,y,image_height, image_height)
//            return self.tableView!.convertRect(rect, toView: self.tableView!.superview)
//        }
//        
//    }
//    
//    func initialView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
//        
//        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
//        if indexPath.section == 0 {
//            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
//            return cell.contentImageView
//        } else {
//            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
//            return cell.contentImageView
//        }
//    }
//    
//    func prepareInitialView(userInfo: [String : AnyObject]?, isPresenting: Bool) {
//        
//        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
//
//        if !isPresenting {
//            if let cell = tableView?.cellForRowAtIndexPath(indexPath) as? UserStoryTableViewCell {
//                returningCell?.activate(false)
//                returningCell = cell
//                returningCell!.deactivate()
//            }
//        }
//        
//        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(indexPath) {
//            self.tableView!.reloadData()
//            self.tableView!.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: false)
//            self.tableView!.layoutIfNeeded()
//        }
//    }
//}
