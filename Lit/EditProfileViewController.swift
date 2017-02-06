//
//  EditProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol EditProfileProtocol {
    func getFullUser()
}

class EditProfileViewController: UITableViewController {

    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    @IBOutlet weak var bioPlaceholder: UITextField!
    
    var imageTap: UITapGestureRecognizer!
    
    
    var headerView:UIImageView!
    var smallProfileImage:UIImage?
    
    var profileImageChanged = false
    
    var didEdit = false
    
    var smallImageURL:String?
    var largeImageURL:String?
    
    let imagePicker = UIImagePickerController()
    
    var delegate:EditProfileProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.width))
        headerView.contentMode = .scaleAspectFill

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300 // Something reasonable to help ios render your cells
        
        tableView.tableHeaderView = headerView
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textViewChanged), for: .editingChanged);
        
        usernameTextField.delegate = self
        usernameTextField.addTarget(self, action: #selector(textViewChanged), for: .editingChanged);
        
        if let user = mainStore.state.userState.user {
            
            headerView.loadImageAsync(user.largeImageURL!, completion: { _ in
                self.imageTap = UITapGestureRecognizer(target: self, action: #selector(self.showProfilePhotoMessagesView))
                self.headerView.isUserInteractionEnabled = true
                self.headerView.addGestureRecognizer(self.imageTap)
            })
            
            nameTextField.text     = user.getName()
            usernameTextField.text = user.getDisplayName()
            
            if let bio = user.bio {
                bioTextView.text = bio
            }
        }
        
        bioTextView.delegate = self
        bioPlaceholder.isHidden = !bioTextView.text.isEmpty
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.navigationBar.isTranslucent = false
        imagePicker.navigationBar.barTintColor = .black
        imagePicker.navigationBar.tintColor = .white // Cancel button ~ any UITabBarButton items
        imagePicker.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.white
        ] // Title colorr

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    @IBAction func handleCancel(sender: AnyObject) {
        
        if didEdit {
            let cancelAlert = UIAlertController(title: "Unsaved Changes", message: "You have unsaved changes. Are you sure you want to cancel?", preferredStyle: UIAlertControllerStyle.alert)
            
            cancelAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            cancelAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                
            }))
            
            present(cancelAlert, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func handleSave(sender: AnyObject) {
        
        cancelButton.isEnabled = false
        cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.gray], for: .normal)
        headerView.isUserInteractionEnabled = false
        nameTextField.isEnabled = false
        bioTextView.isUserInteractionEnabled = false
        title = "Saving..."
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
        
        if profileImageChanged {
            
            UserService.uploadProfilePicture(largeImage: headerView.image!, smallImage: smallProfileImage!, completionHandler: { success, largeImageURL, smallImageURL in
                if success {
                    self.smallImageURL = smallImageURL
                    self.largeImageURL = largeImageURL
                    UserService.updateProfilePictureURL(largeURL: largeImageURL!, smallURL: smallImageURL!, completionHandler: {
                        self.updateUser()
                    })
                }
            })
            
        } else {
            updateUser()
        }
    }
    
    func updateUser() {
        var basicProfileObj = [String:AnyObject]()
        
        if let name = nameTextField.text {
            basicProfileObj["name"] = name as AnyObject?
        }
        
        if let smallURL = smallImageURL {
            basicProfileObj["profileImageURL"] = smallURL as AnyObject?
        }

        let uid = mainStore.state.userState.uid
        let basicProfileRef = UserService.ref.child("users/profile/basic/\(uid)")
        basicProfileRef.updateChildValues(basicProfileObj, withCompletionBlock: { error in
            
            let fullProfileRef = UserService.ref.child("users/profile/full/\(uid)")
            var fullProfileObj = [String:AnyObject]()
            
            if let largeURL = self.largeImageURL {
                basicProfileObj["largeProfileImageURL"] = largeURL as AnyObject?
            }
            
            if let bio = self.bioTextView.text {
                fullProfileObj["bio"] = bio as AnyObject?
            } else {
                fullProfileRef.child("bio").removeValue()
            }
            
            fullProfileRef.updateChildValues(fullProfileObj, withCompletionBlock: { error in
                self.retrieveUpdatedUser()
            })
        })
    }
    
    func retrieveUpdatedUser() {
        let uid = mainStore.state.userState.uid
        
        dataCache.removeObject(forKey: "user-\(uid)" as NSString)
        UserService.getUser(uid, completion: { _user in
            if let user = _user {
                UserService.getUserFullProfile(user: user, completion: { fullUser in
                    mainStore.dispatch(UserIsAuthenticated(user: fullUser))
                    self.dismiss(animated: true, completion: {
                        self.delegate?.getFullUser()
                    })
                })
            }
        })
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            previewNewImage(image: pickedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)

    }
    
    func setFacebookProfilePicture() {
        FacebookGraph.getProfilePicture(completion: { imageURL in
            if imageURL != nil {
                loadImageUsingCacheWithURL(imageURL!, completion: { image, fromCache in
                    if image != nil {
                        self.previewNewImage(image: image!)
                    }
                })
            }
        })
    }
    
    func previewNewImage(image:UIImage) {
        
        DispatchQueue.main.async {
            self.headerView.image = nil
            
            if let croppedImage = cropImageToSquare(image: image) {
                self.headerView.image = resizeImage(image: croppedImage, newWidth: 600)
                self.smallProfileImage = resizeImage(image: croppedImage, newWidth: 100)
            }
            self.didEdit = true
            self.profileImageChanged = true
        }
    }
    
    func uploadProfileImages(largeImage:UIImage, smallImage:UIImage) {
        UserService.uploadProfilePicture(largeImage: largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
            if success {
                UserService.updateProfilePictureURL(largeURL: largeImageURL!, smallURL: smallImageURL!, completionHandler: {
                    mainStore.dispatch(UpdateProfileImageURL(largeImageURL: largeImageURL!, smallImageURL: smallImageURL!))
                    self.headerView.loadImageAsync(largeImageURL!, completion: nil)
                })
            }
        })
    }
    
    
    
    func showProfilePhotoMessagesView() {
        usernameTextField.resignFirstResponder()
        bioTextView.resignFirstResponder()
        
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
    
}

extension EditProfileViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        didEdit = true
        switch textView {
        case bioTextView:
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
            bioPlaceholder.isHidden = !textView.text.isEmpty
            break
        default:
            break
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 240
    }
}

extension EditProfileViewController: UITextFieldDelegate {
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == usernameTextField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            
            if newLength > usernameLengthLimit { return false }
            
            // Create an `NSCharacterSet` set
            let inverseSet = NSCharacterSet(charactersIn:"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted
            
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
        } else if textField === nameTextField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > 50 { return false }
            
            // Create an `NSCharacterSet`
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
    
    func textViewChanged(){
        didEdit = true
        //usernameTextField.text = usernameTextField.text?.lowercaseString;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true;
    }
    
    

    
}
