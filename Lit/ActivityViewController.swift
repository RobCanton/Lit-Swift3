//
//  ActivityViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import Firebase
import View2ViewTransition

class ActivityViewController: UITableViewController, UISearchBarDelegate {
    
    var myStory:UserStory?
    var myStoryKeys = [String]()
    var userStories = [UserStory]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    
    var returningCell:UserStoryTableViewCell?
    
    var myStoryRef:FIRDatabaseReference?
    var responseRef:FIRDatabaseReference?
    
    var statusBarShouldHide = false
    
    override var prefersStatusBarHidden: Bool
        {
        get{
            return statusBarShouldHide
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestActivity()
        listenToMyStory()
        listenToActivityResponse()
        
        NotificationCenter.default.addObserver(self, selector:#selector(handleEnterForeground), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myStoryRef?.removeAllObservers()
        responseRef?.removeAllObservers()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleEnterForeground() {
        myStory?.determineState()
        for story in self.userStories {
            story.determineState()
        }
        tableView?.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            nav.setNavigationBarHidden(false, animated: true)
            nav.setToStandardDelegate(interactive: true)
        }
        
        if returningCell != nil {
            returningCell!.activate(true)
            returningCell = nil
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func showUserSearch(sender: AnyObject) {
        
        let controller = UIStoryboard(name: "UserSearchViewController", bundle: nil)
            .instantiateViewController(withIdentifier: "UserSearchViewController")
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    func listenToMyStory() {
        let uid = mainStore.state.userState.uid
        myStoryRef = UserService.ref.child("users/activity/\(uid)")
        myStoryRef?.removeAllObservers()
        myStoryRef?.observe(.value, with: { snapshot in
            var itemKeys = [String]()
            var timestamp:Double!
            for upload in snapshot.children {
                let uploadSnap = upload as! FIRDataSnapshot
                itemKeys.append(uploadSnap.key)
                timestamp = uploadSnap.value! as! Double
            }

            if self.myStoryKeys == itemKeys {
            } else {
                if itemKeys.count > 0 {
                    self.myStoryKeys = itemKeys
                    let myStory = UserStory(user_id: uid, postKeys: self.myStoryKeys, timestamp: timestamp)
                    self.myStory = myStory
                } else{
                    self.myStory = nil
                }
                self.tableView.reloadData()
            }
        })
    }

    
    func requestActivity() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/requests/activity/\(uid)")
        ref.setValue(true)
    }
    
    func listenToActivityResponse() {
        let uid = mainStore.state.userState.uid
        responseRef = UserService.ref.child("api/responses/activity/\(uid)")
        responseRef?.removeAllObservers()
        responseRef?.observe(.value, with: { snapshot in
            
            var tempDictionary = [String:[String]]()
            var timestamps = [String:Double]()
            if snapshot.exists() {
                
                for user in snapshot.children {
                    
                    let userSnap = user as! FIRDataSnapshot
                    var postKeys = [String]()
                    var timestamp:Double!
                    
                    for post in userSnap.children {
                        let postSnap = post as! FIRDataSnapshot
                        postKeys.append(postSnap.key)
                        timestamp = postSnap.value! as! Double
                    }
                    
                    tempDictionary[userSnap.key] = postKeys
                    timestamps[userSnap.key] = timestamp
                }
                
                self.crossCheckStories(tempDictionary: tempDictionary, timestamps: timestamps)
                self.responseRef?.removeValue()
            }
        })
    }
    
    
    func crossCheckStories(tempDictionary:[String:[String]], timestamps:[String:Double]) {
        
        if NSDictionary(dictionary: storiesDictionary).isEqual(to: tempDictionary) {

        } else {
            storiesDictionary = tempDictionary
            var stories = [UserStory]()
            for (uid, itemKeys) in storiesDictionary {
                let story = UserStory(user_id: uid, postKeys: itemKeys, timestamp: timestamps[uid]!)
                stories.append(story)
            }
            
            stories.sort(by: {
                return $0 > $1
            })
            
            for i in 0..<stories.count {
                let story = stories[i]
                if story.getUserId() == mainStore.state.userState.uid {
                    stories.remove(at: i)
                    stories.insert(story, at: 0)
                }
            }
            
            self.userStories = stories
        }
        
        for story in self.userStories {
            story.determineState()
        }
        tableView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        
        let nib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "UserStoryCell")
        tableView.backgroundColor = UIColor.black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = true
        tableView.isPagingEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: tableView!.frame.width,height: 160))
        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView!.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ListHeaderView
        if section == 0 {
            headerView.isHidden = true
        }
        if section == 1 && userStories.count > 0 {
            headerView.isHidden = false
        }
        
        return headerView
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && userStories.count > 0 {
            return 28
        }
        return 14
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        default:
            return 76
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return userStories.count
        default:
            return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserStoryCell", for: indexPath) as! UserStoryTableViewCell
            if myStory != nil {
                cell.setUserStory(myStory!, useUsername: false)
            } else {
                cell.setToEmptyMyStory()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserStoryCell", for: indexPath) as! UserStoryTableViewCell
            cell.setUserStory(userStories[indexPath.item], useUsername: true)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let story = myStory {
                if story.state == .contentLoaded {
                    presentStory(indexPath: indexPath)
                } else {
                    story.downloadStory()
                }
            } else {
                if let tabBar = self.tabBarController as? MasterTabBarController {
                    tabBar.presentCamera()
                }
            }
        } else if indexPath.section == 1 {
            let story = userStories[indexPath.item]
            if story.state == .contentLoaded {
                presentStory(indexPath: indexPath)
            } else {
                story.downloadStory()
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    
    func presentStory(indexPath:IndexPath) {
        self.selectedIndexPath = indexPath
        
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: false, animated: true)
        }
        
        let presentedViewController: StoriesViewController = StoriesViewController()
        presentedViewController.tabBarRef = self.tabBarController! as! MasterTabBarController
        if indexPath.section == 0 {
            presentedViewController.userStories = [myStory!]
        } else {
            presentedViewController.userStories = userStories
        }
        presentedViewController.transitionController = self.transitionController
        let i = IndexPath(item: indexPath.row, section: 0)
        self.transitionController.userInfo = ["destinationIndexPath": i as AnyObject, "initialIndexPath": indexPath as AnyObject]

        if let nav = navigationController as? MasterNavigationController {
            statusBarShouldHide = true
            nav.disableInteractivePop()
            nav.delegate = transitionController
            transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
        }
    }
}


extension ActivityViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        if indexPath.section == 0 {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: indexPath)! as! UserStoryTableViewCell
            let image_frame = cell.contentImageView.frame
            let image_height = image_frame.height
            let x = cell.frame.origin.x + 23
            
            var y = cell.frame.origin.y + 11 + navHeight
            if !isPresenting {
                y += 20.0
            }
            
            let rect = CGRect(x: x, y: y, width: image_height, height: image_height)
            return self.tableView.convert(rect, to: self.tableView.superview)

        } else {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: indexPath)! as! UserStoryTableViewCell
            let image_frame = cell.contentImageView.frame
            let image_height = image_frame.height
            let x = cell.frame.origin.x + 23

            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height

            var y = cell.frame.origin.y + 11 + navHeight - self.tableView.contentOffset.y
            if !isPresenting {
                y += 20.0
            }
            
            
            let rect = CGRect(x: x, y: y, width: image_height, height: image_height)
            return self.tableView.convert(rect, to: self.tableView.superview)
        }
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {

        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        if indexPath.section == 0 {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: indexPath as IndexPath)! as! UserStoryTableViewCell
            return cell.contentImageView
        } else {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: indexPath as IndexPath)! as! UserStoryTableViewCell
            return cell.contentImageView
        }
    }

    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {

        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath

        if !isPresenting {
            if let cell = tableView?.cellForRow(at: indexPath) as? UserStoryTableViewCell {
                returningCell?.activate(false)
                returningCell = cell
                returningCell!.deactivate()
            }
        }

        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(indexPath) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRow(at: indexPath, at: .middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
    
    func dismissInteractionEnded(_ completed: Bool) {
        if completed {
            statusBarShouldHide = false
            self.setNeedsStatusBarAppearanceUpdate()
            
            if let tabBar = self.tabBarController as? MasterTabBarController {
                tabBar.setTabBarVisible(_visible: true, animated: true)
            }
        }
    }
}
