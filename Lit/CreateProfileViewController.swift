//
//  CreateProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-30.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import Firebase
import UIKit
import FBSDKCoreKit
import AudioToolbox

class CreateProfileViewController: UIViewController,UIScrollViewDelegate ,UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var changePictureButton:UIButton!
    var usernameField:MadokaTextField!
    var fullnameField:MadokaTextField!

    
    var scrollView:UIScrollView!
    var bodyView:UIView!
    var headerView:UIImageView!
    
    var headerTap:UITapGestureRecognizer!
    let imagePicker = UIImagePickerController()
    
    var tap: UITapGestureRecognizer!
    
    
    var userInfo:[String : String] = [
        "displayName": ""
    ]
    
    func cancel() {
        UserService.logout()
        self.dismiss(animated: true, completion: nil)
    }
    
    var doneButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(proceed))
        navigationItem.rightBarButtonItem = doneButton
        deactivateCreateProfileButton()
        
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        headerView =  UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 300))
        headerView.contentMode = .scaleAspectFill
        scrollView = UIScrollView()

        scrollView.frame = view.frame
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height + 300)
        scrollView.backgroundColor = UIColor.black
        scrollView.isScrollEnabled = true
        bodyView = UIView()
        bodyView.backgroundColor = UIColor.black
        bodyView.frame = CGRect(x: 0, y: headerView.frame.height, width: view.frame.width, height: view.frame.height - headerView.frame.height)
        scrollView.addSubview(headerView)
        scrollView.addSubview(bodyView)
        view.addSubview(scrollView)
        
        usernameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.86, height: 64))
        usernameField.placeholderColor = .white
        usernameField.borderColor = .white
        usernameField.textColor = .white
        usernameField.placeholder = "Username"
        
        usernameField.delegate = self
        usernameField.font = UIFont(name: "Avenir-Medium", size: 20.0)
        usernameField.textAlignment = .center
        usernameField.autocapitalizationType = .none
        usernameField.addTarget(self, action: #selector(textViewChanged), for: .editingChanged);
        usernameField.keyboardAppearance = .dark

        
        fullnameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.86, height: 64))
        fullnameField.placeholderColor = .white
        fullnameField.borderColor = .white
        fullnameField.textColor = .white
        fullnameField.placeholder = "Full name"
        fullnameField.delegate = self
        fullnameField.font = UIFont(name: "Avenir-Medium", size: 20.0)
        fullnameField.textAlignment = .center
        fullnameField.keyboardAppearance = .dark
        
        fullnameField.center = CGPoint(x: bodyView.frame.width/2, y: fullnameField.frame.height)
        bodyView.addSubview(fullnameField)
        
        usernameField.center = CGPoint(x: bodyView.frame.width/2, y: fullnameField.center.y + usernameField.frame.height + 15)
        bodyView.addSubview(usernameField)
        

        
        tap = UITapGestureRecognizer(target: self, action: #selector(proceed))
        
        headerTap = UITapGestureRecognizer(target: self, action: #selector(showProfilePhotoMessagesView))
        headerView.addGestureRecognizer(headerTap)
        headerView.isUserInteractionEnabled = true

        imagePicker.delegate = self
        imagePicker.navigationBar.isTranslucent = false
        imagePicker.navigationBar.barTintColor = .black
        imagePicker.navigationBar.tintColor = .white // Cancel button ~ any UITabBarButton items
        imagePicker.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.white
        ] // Title colorr
        
        
        doSet()

    }
    
    func showProfilePhotoMessagesView() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let facebookActionButton: UIAlertAction = UIAlertAction(title: "Import from Facebook", style: .default)
        { action -> Void in
            self.setFacebookProfilePicture()
        }
        actionSheet.addAction(facebookActionButton)
        
        let libraryActionButton: UIAlertAction = UIAlertAction(title: "Choose from Library", style: .default)
        { action -> Void in
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        actionSheet.addAction(libraryActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.headerView.image = nil
            self.smallProfileImageView.image = nil
            headerView.image = resizeImage(image: pickedImage, newWidth: 720)
            smallProfileImageView.image = resizeImage(image: pickedImage, newWidth: 150)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        
    }
    var smallProfileImageView:UIImageView!
    
    var facebook_uid = ""
    
    func doSet() {
        
        if let user = FIRAuth.auth()!.currentUser {
            
            for item in user.providerData {
                facebook_uid = item.uid
            }
            
            userInfo["displayName"] = ((user.displayName ?? "").isEmpty ? "" : user.displayName!)
            userInfo["photoURL"] = ((user.photoURL?.absoluteString ?? "").isEmpty ? "" : user.photoURL!.absoluteString)
        }
        
        fullnameField.text = userInfo["displayName"]
        
        smallProfileImageView = UIImageView()
        smallProfileImageView.loadImageAsync(userInfo["photoURL"]!, completion: nil)
        
        setFacebookProfilePicture()
        
    }
    
    func setFacebookProfilePicture() {
        FacebookGraph.getProfilePicture(completion: { imageURL in
            if imageURL != nil {
                self.headerView.image = nil
                self.headerView.loadImageAsync(imageURL!, completion: { fromCache in
                    self.smallProfileImageView.image = nil
                    self.smallProfileImageView.image = resizeImage(image: self.headerView.image!, newWidth: 150)
                })
            }
        })
    }
    
    
    
    func getNewUser() {
        if let user = FIRAuth.auth()?.currentUser {
            
            UserService.getUser(user.uid, completion: { _user in
                if _user != nil {

                    FacebookGraph.getFacebookFriends(completion: { _userIds in
                        UserService.login(_user!)
                        if _userIds.count == 0 {
                            self.performSegue(withIdentifier: "showLit", sender: self)
                        } else {
                            DispatchQueue.main.async {
                                self.fbFriend_uids = _userIds
                                self.performSegue(withIdentifier: "showFacebookFriends", sender: self)
                            }
                        }
                    })
                }
            })
        }
    }
    
    var fbFriend_uids:[String]?
    var user: User?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFacebookFriends" {
            let controller = segue.destination as! FacebookFriendsListViewController
            controller.fbIds = fbFriend_uids
        }
    }
    
    
    func proceed() {
        if usernameField.text == nil || usernameField.text == "" { return }
        
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
        
        
        deactivateCreateProfileButton()
        fullnameField.isEnabled = false
        usernameField.isEnabled = false
        cancelButton.isEnabled  = false
        cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.gray], for: .normal)
        
        usernameField.resignFirstResponder()
        fullnameField.resignFirstResponder()
        
        let name = fullnameField.text!
        let username = usernameField.text!
        
        if let user = FIRAuth.auth()?.currentUser {
            let largeImage = headerView.image!
            let smallImage = smallProfileImageView.image!
            UserService.uploadProfilePicture(largeImage: largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
                
                if success {
                    let ref = UserService.ref.child("users/facebook/\(self.facebook_uid)")
                    ref.setValue(user.uid)
                    
                    let publicRef = UserService.ref.child("users/profile/basic/\(user.uid)")
                    publicRef.updateChildValues([
                        "name": name,
                        "username":username,
                        "profileImageURL": smallImageURL!
                        ], withCompletionBlock: {error, ref in
                            if error != nil {
                                print(error!.localizedDescription)
                            }
                            else {
                                let fullProfileRef = UserService.ref.child("users/profile/full/\(user.uid)")
                                let obj = [
                                    "largeProfileImageURL": largeImageURL!
                                ]
                                
                                fullProfileRef.setValue(obj, withCompletionBlock: {error, ref in
                                        if error != nil {
                                            print(error!.localizedDescription)
                                        }
                                        else {
                                            self.getNewUser()
                                        }
                                })
                            }
                    })
                }
            })
        }
    }
    
    func checkUsernameAvailability() {
        
        guard let text = usernameField.text else { return }
        
        if text.characters.count >= 5 {
            let ref = FIRDatabase.database().reference().child("users/profile/basic")
            ref.queryOrdered(byChild: "username").queryEqual(toValue: usernameField.text!).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    self.usernameUnavailable(reason: "Username unavailable")
                } else {
                    self.usernameAvailable()
                }
            })
        } else {
            self.usernameUnavailable(reason: "Username must be at least 5 characters")
        }
        
        
    }
    
    func usernameUnavailable(reason:String) {
        deactivateCreateProfileButton()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        usernameField.borderColor = errorColor
        usernameField.placeholderColor = errorColor
        usernameField.placeholder = reason
        //usernameField.shake()
    }
    
    func usernameAvailable() {
        activateCreateProfileButton()
        usernameField.borderColor = accentColor
        usernameField.placeholderColor = accentColor
        usernameField.placeholder = "Username available"
    }
    

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true;
    }
    
    func textViewChanged(){
        usernameField.text = usernameField.text?.lowercased();
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === usernameField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > usernameLengthLimit { return false }
            
            // Create an `NSCharacterSet` set 
            let inverseSet = NSCharacterSet(charactersIn:".0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            
            let components = string.components(separatedBy: inverseSet)
            
            // Rejoin these components
            let filtered = components.joined(separator: "")  // use join("", components) if you are using Swift 1.2
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            return string == filtered
        } else if textField === fullnameField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > 50 { return false }
            
            // Create an `NSCharacterSet` set
            let inverseSet = NSCharacterSet(charactersIn:" .0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            let components = string.components(separatedBy: inverseSet)
            
            // Rejoin these components
            let filtered = components.joined(separator: "")  // use join("", components) if you are using Swift 1.2
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            return string == filtered
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField === usernameField {
            //[scroll setContentOffset:CGPointMake(0, (textField.superview.frame.origin.y + (textField.frame.origin.y))) animated:YES]    }
            let point = CGPoint(x: 0,y: (textField.superview!.frame.origin.y + (textField.frame.origin.y) - headerView.frame.height))
            scrollView.setContentOffset(CGPoint(x:0,y:headerView.frame.height), animated: true)
            
            usernameField.borderColor = UIColor.white
            usernameField.placeholderColor = UIColor.white
            usernameField.placeholder = "Username"
            
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === usernameField {
            if (textField.text?.characters.count)! > 0 {
                checkUsernameAvailability()
            }
        }
    }
    
    func deactivateCreateProfileButton() {
        doneButton.isEnabled = false
        doneButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.gray], for: .normal)
    }
    
    func activateCreateProfileButton() {
        doneButton.isEnabled = true
        doneButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
    }
}
