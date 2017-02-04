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
    @IBOutlet weak var suggestLocation: UITableViewCell!
    
    @IBOutlet weak var report: UITableViewCell!
    
    @IBOutlet weak var logout: UITableViewCell!
    
    
    var notificationsRef:FIRDatabaseReference?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.white]
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

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath as IndexPath) {
            
            switch cell {
            case addFacebookFriends:
                let controller = FacebookFriendsListViewController()
                self.navigationController?.pushViewController(controller, animated: true)
                break
            case privacyPolicy:
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
    
    
    @IBAction func toggleNotificationsSwitch(sender: UISwitch) {
        if sender.isOn {
            print("TRUE")
            notificationsRef?.setValue(true)
        } else {
            print("FALSE")
            notificationsRef?.setValue(false)
        }
    }

    func showPrivacyPolicy() {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let controller = storyboard.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
//        controller.title = "Privacy Policy"
//        navigationController?.pushViewController(controller, animated: true)
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