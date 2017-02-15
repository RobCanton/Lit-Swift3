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

class LocationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var location:Location!
    
    var userStories = [UserStory]()
    var storiesDictionary = [String:[String]]()
    
    var tableView:UITableView!
    
    var headerView:UIImageView!
    
    var returningCell:UserStoryTableViewCell?
    
    var statusBarShouldHide = false
    
    override var prefersStatusBarHidden: Bool
    {
        get{
            return statusBarShouldHide
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = location.getName()
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)

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
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0)
        

        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = true
        tableView.isPagingEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView.backgroundColor = UIColor.black
        
        headerView = UIImageView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 190))
        headerView.contentMode = .scaleAspectFill
        headerView.clipsToBounds = true
        
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("location-\(self.location!.getKey()).jpg"))
        
        if let imageFile = UIImage(contentsOfFile: fileURL.path) {
            self.headerView.image = imageFile
        } else {
            headerView.loadImageAsync(location.getImageURL(), completion: nil)
        }
        
        tableView.tableHeaderView = headerView
        
        let footerNib = UINib(nibName: "LocationFooterView", bundle: nil)
        tableView!.register(footerNib, forHeaderFooterViewReuseIdentifier: "footerView")
        
        let footerView = UINib(nibName: "LocationFooterView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LocationFooterView
        tableView.tableFooterView = footerView
        
        tableView.reloadData()
        
        view.addSubview(tableView)
        
        LocationService.getLocationDetails(location, completion: { location in
            self.location = location
            if let footer = self.tableView?.tableFooterView as? LocationFooterView {
                footer.descriptionLabel.text = self.location.desc
                footer.descriptionLabel.sizeToFit()
            }
            self.tableView?.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenToUserStories()
        tableView.isUserInteractionEnabled = false
        
        NotificationCenter.default.addObserver(self, selector:#selector(handleEnterForeground), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.isUserInteractionEnabled = true
        
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            nav.setNavigationBarHidden(false, animated: true)
            nav.delegate = nav
        }
        
        if returningCell != nil {
            returningCell!.activate(true)
            returningCell = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && userStories.count == 0 {
            return 0
        }
        return 34
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ListHeaderView
            headerView.isHidden = false
            headerView.label.text = "RECENT"
            return headerView
        } else if section == 1 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ListHeaderView
            headerView.isHidden = false
            headerView.label.text = "INFO"
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 76
        } else {
            if indexPath.row == 0 {
                return 42
            } else if indexPath.row == 1 && location.phone != nil {
                return 42
            } else if indexPath.row == 2 && location.email != nil {
                return 42
            } else if indexPath.row == 3 && location.website != nil {
                return 42
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return userStories.count
        } else {
            return 4
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath) as! UserStoryTableViewCell
            cell.setUserStory(userStories[indexPath.item], useUsername: false)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath) as! InfoTableViewCell
            if indexPath.row == 0 {
                cell.type = .fullAddress
                cell.label.text = location.getAddress()
            } else if indexPath.row == 1 {
                cell.type = .phone
                cell.label.text = location.phone
            } else if indexPath.row == 2 {
                cell.type = .email
                cell.label.text = location.email
            }  else if indexPath.row == 3 {
                cell.type = .website
                cell.label.text = location.website
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let story = userStories[indexPath.item]
            if story.state == .contentLoaded {
                presentStory(indexPath)
            } else {
                story.downloadStory()
            }
        } else if indexPath.section == 1 {
            let cell = tableView.cellForRow(at: indexPath) as! InfoTableViewCell
            switch cell.type {
            case .fullAddress:
                self.performSegue(withIdentifier: "showMap", sender: self)
                break
            case .phone:
                promptPhoneCall()
                break
            case .email:
                promptEmail()
                break
            case .website:
                promptWebsite()
                break
            default:
                break
            }
        }
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
            navigationController.delegate = transitionController
            transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMap" {
            let controller = segue.destination as! MapViewController
            controller.setMapLocation(_location: location)
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
        let x = cell.frame.origin.x + 19
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        var y = cell.frame.origin.y + 11 + navHeight
        if !isPresenting {
            y += 20.0
        }
        
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
        if !isPresenting {
            self.tableView!.reloadData()
            self.tableView!.scrollToRow(at: i, at: .middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
    
    func dismissInteractionEnded(completed: Bool) {
        if completed {
            statusBarShouldHide = false
            self.setNeedsStatusBarAppearanceUpdate()
            
            if let tabBar = self.tabBarController as? MasterTabBarController {
                tabBar.setTabBarVisible(_visible: true, animated: true)
            }
        }
    }

}
