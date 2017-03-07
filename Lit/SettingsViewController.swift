//
//  SettingsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController {

    @IBOutlet weak var addFacebookFriends: UITableViewCell!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var privacyPolicy: UITableViewCell!
    @IBOutlet weak var terms: UITableViewCell!
    @IBOutlet weak var suggestLocation: UITableViewCell!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var report: UITableViewCell!
    
    @IBOutlet weak var blockedUsers: UITableViewCell!
    @IBOutlet weak var logout: UITableViewCell!
    
    @IBOutlet weak var allowInappropriateContent: UISwitch!
    
    let maxRadius = 200
    
    var notificationsRef:FIRDatabaseReference?
    var contentRef:FIRDatabaseReference?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let loc = GPSService.sharedInstance.lastLocation else { return }

        LocationService.requestNearbyLocations(loc.coordinate.latitude, longitude: loc.coordinate.longitude)
    }
    
    var radiusChanged = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        let uid = mainStore.state.userState.uid
        
        tableView.separatorColor = UIColor(white: 0.10, alpha: 1.0)
        
        notificationsRef = UserService.ref.child("users/settings/\(uid)/push_notifications")
        notificationsRef!.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                if let val = snapshot.value as? Bool {
                    if val {
                        self.notificationsSwitch.setOn(true, animated: false)
                    } else {
                        self.notificationsSwitch.setOn(false, animated: false)
                    }
                }
            } else {
                self.notificationsSwitch.setOn(true, animated: false)
            }
        })
        
        contentRef = UserService.ref.child("users/settings/\(uid)/allow_inappropriate_content")
        if UserService.allowContent {
            allowInappropriateContent.setOn(true, animated: false)
        } else {
            allowInappropriateContent.setOn(false, animated: false)
        }
        
        let radius = LocationService.radius
        
        distanceSlider.minimumValue = 0.05
        
        let progress:Float = Float(radius) / Float(maxRadius)
        distanceSlider.setValue(progress, animated: false)
        distanceLabel.text = "\(radius) km"
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath as IndexPath) {
            
            switch cell {
            case addFacebookFriends:
                let controller = FacebookFriendsListViewController()
                self.navigationController?.pushViewController(controller, animated: true)
                break
            case blockedUsers:
                let controller = UsersListViewController()
                var blocked = [String]()
                for uid in mainStore.state.socialState.blocked {
                    blocked.append(uid)
                }
                controller.tempIds = blocked
                controller.showFollowButton = false
                controller.title = "Blocked Users"
                self.navigationController?.pushViewController(controller, animated: true)
                break
            case privacyPolicy:
                let controller = WebViewController()
                controller.urlString = "https://getlit.site/privacypolicy.html"
                controller.title = "Privacy Policy"
                controller.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(controller, animated: true)
                break
            case terms:
                let controller = WebViewController()
                controller.urlString = "https://getlit.site/terms.html"
                controller.title = "Terms of Use"
                controller.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(controller, animated: true)
                break
            case suggestLocation:
                makeSuggestion()
                break
            case report:
                reportProblem()
                break
            case logout:
                showLogoutView()
                break
            default:
                break
            }
            
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        }
    }
    
    
    @IBAction func sliderChanged(_ sender: Any) {
        let radius = Int(Double(distanceSlider.value) * Double(maxRadius))
        LocationService.radius = radius
        distanceLabel.text = "\(radius) km"
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("users/settings/\(uid)/search_radius")
        ref.setValue(radius)
        radiusChanged = true
    }
    
    
    
    @IBAction func toggleNotificationsSwitch(sender: UISwitch) {
        if sender.isOn {
            notificationsRef?.setValue(true)
        } else {
            notificationsRef?.setValue(false)
        }
    }

    @IBAction func toggleContentSwitch(_ sender: UISwitch) {
        
        if sender.isOn {
            let alert = UIAlertController(title: "Are you sure?", message: "Content that has been reported to be inappropriate will no longer be blocked.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.allowInappropriateContent.setOn(false, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Allow", style: .destructive, handler: { _ in
                self.contentRef?.setValue(true)
                UserService.allowContent = true
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            contentRef?.setValue(false)
            UserService.allowContent = false
        }
    }
    
    
    func makeSuggestion() {
        let subject = "Location suggestion"
        let coded = "mailto:info@getlit.site?subject=\(subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: coded!)
        let application:UIApplication = UIApplication.shared
        if (application.canOpenURL(url!)) {
            if #available(iOS 10.0, *) {
                application.open(url!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                application.openURL(url!)
            }
        }
    }
    
    func reportProblem() {
        let subject = "Reporting a problem"
        let coded = "mailto:info@getlit.site?subject=\(subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: coded!)
        let application:UIApplication = UIApplication.shared
        if (application.canOpenURL(url!)) {
            if #available(iOS 10.0, *) {
                application.open(url!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                application.openURL(url!)
            }
        }
    }
    
    func showLogoutView() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Log Out", style: .destructive)
        { action -> Void in
            UserService.logout()
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}
