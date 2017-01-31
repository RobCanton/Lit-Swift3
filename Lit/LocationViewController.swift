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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = location.getName()
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.white]
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
        
        headerView.loadImageAsync(location.getImageURL(), completion: nil)
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
                print("YE: \(self.location.desc)")
                footer.descriptionLabel.text = self.location.desc
                footer.descriptionLabel.sizeToFit()
            }
            self.tableView?.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenToUserStories()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserService.ref.child("locations/uploads/\(location.getKey())").removeAllObservers()
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
                //showMap()
                break
            case .phone:
                //promptPhoneCall()
                break
            case .email:
                //promptEmail()
                break
            case .website:
                //promptWebsite()
                break
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func presentStory(_ indexPath:IndexPath) {
        print("PRESENT STORY")
    }
    
   
    
}

extension LocationViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        let i =  IndexPath(row: indexPath.item, section: 1)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: i)! as! UserStoryTableViewCell
        let image_frame = cell.contentImageView.frame
        let image_height = image_frame.height
        let x = cell.frame.origin.x + 20
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        let y = cell.frame.origin.y + 12 + navHeight
        
        let rect = CGRect(x: x, y: y, width: image_height, height: image_height)// CGRectMake(x,y,image_height, image_height)
        return self.tableView.convert(rect, to: self.tableView.superview)
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 1)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRow(at: i)! as! UserStoryTableViewCell
        
        return cell.contentImageView
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 1)
        if !isPresenting {
            if let cell = tableView?.cellForRow(at: i) as? UserStoryTableViewCell {
                returningCell?.activate(false)
                returningCell = cell
                returningCell!.deactivate()
            }
        }
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(i) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRow(at: i, at: .middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
}
