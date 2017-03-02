//
//  LocationViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import View2ViewTransition
import ZoomTransitioning

class LocationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var location:Location!
    
    var userStories = [UserStory]()
    var storiesDictionary = [String:[String]]()
    
    var tableView:UITableView!
    
    var headerView:LocationHeaderView!
    
    var returningCell:UserStoryTableViewCell?
    
    var statusBarShouldHide = false
    
    var storiesRetrieved = false
    
    var descriptionTap:UITapGestureRecognizer!
    var descriptionCollapsed = true
    
    var mapTap:UITapGestureRecognizer!
    
    
    override var prefersStatusBarHidden: Bool
    {
        get{
            return true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationItem.title = location.getName()
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        //navigationController?.setNavigationBarHidden(true, animated: true)
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let slack:CGFloat = 1.0
        let eventsHeight:CGFloat = 0
        let topInset:CGFloat = navHeight + eventsHeight + slack
        
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: topInset , left: 0, bottom: 200, right: 0)
        layout.itemSize = CGSize(width: screenWidth, height: 80)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        
        let userStoryNib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
        tableView.register(userStoryNib, forCellReuseIdentifier: "storyCell")
        
        let infoNib = UINib(nibName: "InfoTableViewCell", bundle: nil)
        tableView.register(infoNib, forCellReuseIdentifier: "infoCell")
        
        
        let loadingNib = UINib(nibName: "LoadingTableViewCell", bundle: nil)
        tableView.register(loadingNib, forCellReuseIdentifier: "loadingCell")

        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0)
        

        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = true
        tableView.isPagingEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView.backgroundColor = UIColor.black
        
        headerView = UINib(nibName: "LocationHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LocationHeaderView
        
        
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: calculateHeaderHeight())
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        headerView.layoutSubviews()
        headerView.clipsToBounds = true
        headerView.backHandler = dismiss
        headerView.contactHandler = handleContact
        
        descriptionTap = UITapGestureRecognizer(target: self, action: #selector(descriptionTapped))
        headerView.descriptionLabel.isUserInteractionEnabled = true
        headerView.descriptionLabel.addGestureRecognizer(descriptionTap)
        
        print("LABEL HEIGHT: \(headerView.descriptionLabel.frame.height)")
        
        headerView.setLocationInfo(location: location)

        
        
        tableView.tableHeaderView = headerView
        
        let footerNib = UINib(nibName: "LocationFooterView", bundle: nil)
        tableView!.register(footerNib, forHeaderFooterViewReuseIdentifier: "footerView")
        
        let footerView = UINib(nibName: "LocationFooterView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LocationFooterView
        tableView.tableFooterView = footerView
        footerView.setLocationInfo(location: location)
        
        mapTap = UITapGestureRecognizer(target: self, action: #selector(showMap))
        footerView.mapContainer.isUserInteractionEnabled = true
        footerView.mapContainer.addGestureRecognizer(mapTap)
        
        tableView.reloadData()
        
        view.addSubview(tableView)
        
//        if let distance = location.getDistance() {
//            let distanceButton = UIBarButtonItem(title: getDistanceString(distance: distance), style: .plain, target: self, action: #selector(showMap))
//            distanceButton.setTitleTextAttributes([ NSFontAttributeName: UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)], for: UIControlState.normal)
//            self.navigationItem.rightBarButtonItem = distanceButton
//            
//        }
    }
    
    func dismiss() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func descriptionTapped(sender:UITapGestureRecognizer) {
        print("TAPPED")
        descriptionCollapsed = !descriptionCollapsed
        let desc = headerView.descriptionLabel!
        if descriptionCollapsed {
            desc.numberOfLines = 2
        } else {
            desc.numberOfLines = 0
        }
        desc.sizeToFit()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: calculateHeaderHeight())
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        headerView.layoutSubviews()
        tableView.reloadData()
    }
    
    func calculateHeaderHeight() -> CGFloat {
        let titleSize =  UILabel.size(withText: location.getName(), forWidth: tableView.frame.size.width - 118, withFont: UIFont.systemFont(ofSize: 24.0, weight: UIFontWeightHeavy))
        
        var descHeight:CGFloat = 0.0
        if let desc = location.desc {
            descHeight = UILabel.size(withText: desc, forWidth: tableView.frame.size.width - 28, withFont: UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightLight)).height
            if descHeight > 38.5 && descriptionCollapsed {
                descHeight = 38.5
            }
            descHeight + 16 // padding
        }
        
        return titleSize.height + 210 + 50 + 10 + descHeight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenToUserStories()
        tableView.isUserInteractionEnabled = false
        //self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector:#selector(handleEnterForeground), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        if let tabBar = self.tabBarController as? MasterTabBarController {
            // tabBar.setTabBarVisible(_visible: false, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.isUserInteractionEnabled = true
        
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
        
//        if let tabBar = self.tabBarController as? MasterTabBarController {
//            tabBar.setTabBarVisible(_visible: true, animated: true)
//        }
        
        if let nav = navigationController as? MasterNavigationController {
            //nav.setNavigationBarHidden(false, animated: true)
            //nav.delegate = nav
            nav.setToZoomDelegate()
        }
        
        if returningCell != nil {
            returningCell!.activate(true)
            returningCell = nil
        }
        
        UIView.animate(withDuration: 0.15, delay: 0.075, options: .curveEaseIn, animations: {
            self.headerView.backButton.alpha = 1.0
        }, completion: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
        UserService.ref.child("locations/uploads/\(location.getKey())").removeAllObservers()
         NotificationCenter.default.removeObserver(self)

    }
    
    func handleEnterForeground() {
        for story in self.userStories {
            story.determineState()
        }
        tableView?.reloadData()
    }
    
    func listenToUserStories() {

        let locRef = UserService.ref.child("locations/uploads/\(location.getKey())")
        locRef.removeAllObservers()
        locRef.queryOrderedByKey().observe(.value, with: { snapshot in
            var tempDictionary = [String:[String]]()
            var timestamps = [String:Double]()
            
            for user in snapshot.children {
                let userSnap = user as! FIRDataSnapshot
                if !mainStore.state.socialState.blockedBy.contains(userSnap.key) {
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
            }
            
            self.crossCheckStories(tempDictionary, timestamps: timestamps)
        })
    }

    func crossCheckStories(_ tempDictionary:[String:[String]], timestamps:[String:Double]) {
        let uid = mainStore.state.userState.uid
        
        if NSDictionary(dictionary: storiesDictionary).isEqual(to: tempDictionary) {
            //print("Stories unchanged. No download required")
            //print("Current: \(storiesDictionary) | Temp: \(tempDictionary)")
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
        storiesRetrieved = true
        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && userStories.count == 0 && storiesRetrieved {
            return 0
        }
        return 33
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ListHeaderView
            headerView.isHidden = false
            headerView.backgroundColor = UIColor.black
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if storiesRetrieved {
            return userStories.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if storiesRetrieved {
            let cell = tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath) as! UserStoryTableViewCell
            cell.setUserStory(userStories[indexPath.item], useUsername: false)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath) as! LoadingTableViewCell
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if storiesRetrieved {
            let story = userStories[indexPath.item]
            if story.state == .contentLoaded {
                presentStory(indexPath)
            } else {
                story.downloadStory()
                
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func handleContact() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Call", style: .default, handler: { _ in
            self.promptPhoneCall()
        }))
        sheet.addAction(UIAlertAction(title: "Email", style: .default, handler: { _ in
            self.promptEmail()
        }))
        sheet.addAction(UIAlertAction(title: "Visit Website", style: .default, handler: { _ in
            self.promptWebsite()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    func showMap() {
        if let nav = navigationController as? MasterNavigationController {
            nav.setToStandardDelegate(interactive: false)
        }
        let controller = LocationMapViewController()
        controller.location = location
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    func presentStory(_ indexPath:IndexPath) {
        self.selectedIndexPath = indexPath
        
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: false, animated: true)
        }

        let presentedViewController: StoriesViewController = StoriesViewController()
        presentedViewController.tabBarRef   = self.tabBarController! as! MasterTabBarController
        presentedViewController.userStories = userStories
        presentedViewController.location    = location
        presentedViewController.transitionController = self.transitionController
        let i = IndexPath(item: indexPath.row, section: 0)
        self.transitionController.userInfo = ["destinationIndexPath": i as AnyObject, "initialIndexPath": i as AnyObject]
        
        // This example will push view controller if presenting view controller has navigation controller.
        // Otherwise, present another view controller
        if let navigationController = self.navigationController {
            
            statusBarShouldHide = true
            // Set transitionController as a navigation controller delegate and push.
            
            
            
            if let nav = navigationController as? MasterNavigationController {
                nav.disableInteractivePop()
                nav.delegate = transitionController
                transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
            }

        }
    }
    
    func promptPhoneCall() {
        guard let phoneNumber = location.phone else { return }
        let phoneAlert = UIAlertController(title: "Call \(location.getName())?", message: phoneNumber, preferredStyle: UIAlertControllerStyle.alert)
        
        phoneAlert.addAction(UIAlertAction(title: "Call", style: .default, handler: { (action: UIAlertAction!) in
            let stringArray = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted)//decimalDigitCharacterSet().invertedSet)
            let cleanNumber = stringArray.joined(separator: "")
            if let phoneCallURL:URL = URL(string:"tel://\(cleanNumber)") {
                let application:UIApplication = UIApplication.shared
                if (application.canOpenURL(phoneCallURL)) {
                    if #available(iOS 10.0, *) {
                        application.open(phoneCallURL, options: [:], completionHandler: nil)
                    } else {
                        // Fallback on earlier versions
                        application.openURL(phoneCallURL)
                    }
                }
            }
        }))
        
        phoneAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        present(phoneAlert, animated: true, completion: nil)
    }
    
    func promptEmail() {
        guard let email = location.email else { return }
        let phoneAlert = UIAlertController(title: "Contact \(location.getName())?", message: email, preferredStyle: UIAlertControllerStyle.alert)
        
        phoneAlert.addAction(UIAlertAction(title: "Email", style: .default, handler: { (action: UIAlertAction!) in
            
            let url = URL(string: "mailto:\(email)")
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(url!)) {
                if #available(iOS 10.0, *) {
                    application.open(url!, options: [:], completionHandler: nil)
                } else {
                    application.openURL(url!)
                }
            }
        }))
        
        phoneAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        present(phoneAlert, animated: true, completion: nil)
    }
    
    
    func promptWebsite() {
        guard let website = location.website else { return }
        let phoneAlert = UIAlertController(title: "Visit \(website)?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        phoneAlert.addAction(UIAlertAction(title: "Open", style: .default, handler: { (action: UIAlertAction!) in
            let url = URL(string: "http://\(website)")!
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(url)) {
                if #available(iOS 10.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                    application.openURL(url)
                }
            }
        }))
        
        phoneAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        present(phoneAlert, animated: true, completion: nil)
    }

}

extension LocationViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        let i =  IndexPath(row: indexPath.item, section: 0)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: i)! as! UserStoryTableViewCell
        let image_frame = cell.contentImageView.frame
        let image_height = image_frame.height
        let x = cell.frame.origin.x + 23
        
        let y = cell.frame.origin.y + 11 //+ navHeight

        let rect = CGRect(x: x, y: y, width: image_height, height: image_height)// CGRectMake(x,y,image_height, image_height)
        return self.tableView.convert(rect, to: self.tableView.superview)
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: i)! as! UserStoryTableViewCell
        
        return cell.contentImageView
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        if !isPresenting {
            if let cell = tableView?.cellForRow(at: i) as? UserStoryTableViewCell {
                returningCell?.activate(false)
                returningCell = cell
                returningCell!.deactivate()
            }
        }
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(indexPath) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRow(at: i, at: .middle, animated: false)
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

extension LocationViewController: ZoomTransitionDestinationDelegate {
    
    func transitionDestinationImageViewFrame(forward forward: Bool) -> CGRect {
        let largeImageView = headerView.imageView!
        var boundz = largeImageView.convert(largeImageView.bounds, to: view)
        if forward {
            let x: CGFloat = 0.0
            let y: CGFloat = 0.0
            let width = view.frame.width
            let height = boundz.height
            return CGRect(x: x, y: y, width: width, height: height)
        } else {
            return largeImageView.convert(largeImageView.bounds, to: view)
        }
    }
    
    func transitionDestinationWillBegin() {
        let largeImageView = headerView.imageView!
        largeImageView.isHidden = true
    }
    
    func transitionDestinationDidEnd(transitioningImageView imageView: UIImageView) {
        let largeImageView = headerView.imageView!
        largeImageView.isHidden = false
        largeImageView.image = imageView.image
    }
    
    func transitionDestinationDidCancel() {
        let largeImageView = headerView.imageView!
        largeImageView.isHidden = false
    }
    
    

}
