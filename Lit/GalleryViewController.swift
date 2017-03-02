//
//  StoriesViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import View2ViewTransition

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate, PopupProtocol {
    
    weak var transitionController: TransitionController!
    
    var uid:String!
    var label:UILabel!
    var tabBarRef:MasterTabBarController!
    var posts = [StoryItem]()
    var currentIndex:IndexPath!
    var collectionView:UICollectionView!
    
    var statusBarShouldHide = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarRef.setTabBarVisible(_visible: false, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        if self.navigationController!.delegate !== transitionController {
            self.collectionView.reloadData()
        }
        
        if self.navigationController!.delegate !== transitionController {
            self.collectionView.reloadData()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
        tabBarRef.setTabBarVisible(_visible: false, animated: false)
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.delegate = transitionController
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
        }
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                }
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        for cell in collectionView.visibleCells as! [PostViewController] {
            //cell.yo()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        tabBarRef.setTabBarVisible(_visible: true, animated: true)
        
        for cell in collectionView.visibleCells as! [PostViewController] {
            cell.cleanUp()
        }
    }
    
    var textField:UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.black
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.main.bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView.register(PostViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.black
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.isOpaque = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.addSubview(collectionView)
        
        
        label = UILabel(frame: CGRect(x:0,y:0,width:self.view.frame.width,height:100))
        label.textColor = UIColor.white
        label.center = view.center
        label.textAlignment = .center
        
    }
    
    func appMovedToBackground() {
        dismissPopup(false)
    }
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cell = getCurrentCell() else { return false }
        if cell.keyboardUp {
            return false
        }
        
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
        
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PostViewController = collectionView.dequeueReusableCell(withReuseIdentifier: "presented_cell", for: indexPath as IndexPath) as! PostViewController
        cell.storyItem = posts[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func dismissPopup(_ animated:Bool) {
        getCurrentCell()?.pauseVideo()
        getCurrentCell()?.destroyVideoPlayer()
        if let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as? IndexPath {
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
            navigationController?.popViewController(animated: animated)
        }
    }
    
    func showUser(_ uid:String) {
        if self.uid == uid {
            dismissPopup(true)
        } else {
            guard let cell = getCurrentCell() else { return }
            self.navigationController?.delegate = self
            let controller = UserProfileViewController()
            controller.uid = uid
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func showUsersList(_ uids:[String], _ title:String) {
        self.navigationController?.delegate = self
        let controller = UsersListViewController()
        controller.title = title
        controller.tempIds = uids
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.storyItem else { return }
        
        if uid == mainStore.state.userState.uid {
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in

            }
            actionSheet.addAction(cancelActionButton)
            
            let captionActionButton: UIAlertAction = UIAlertAction(title: "Edit Caption", style: .default) { action -> Void in
                //cell.resumeStory()
                let alert = UIAlertController(title: "Edit Caption", message: nil, preferredStyle: .alert)
                alert.addTextField(configurationHandler: {(textField) -> Void in
                    textField.text = item.caption
                    textField.keyboardAppearance = .dark
                    textField.autocapitalizationType = .sentences
                })
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                    let textF = alert.textFields![0]
                    var text = textF.text
                    if text == nil {
                        text = ""
                    }
                    item.editCaption(caption: text!)
                    UploadService.editCaption(postKey: item.getKey(), caption: text!)
                    cell.setItem()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
                    
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
            actionSheet.addAction(captionActionButton)
            
            let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive) { action -> Void in
                
                if item.postPoints() > 1 {
                    let deleteController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in

                    }
                    deleteController.addAction(cancelAction)
                    let storyAction: UIAlertAction = UIAlertAction(title: "Remove from my profile", style: .destructive)
                    { action -> Void in
                        UploadService.removeItemFromProfile(item: item, notify: true, completion: { success in
                            if success {
                                self.dismissPopup(true)
                            }
                        })
                    }
                    deleteController.addAction(storyAction)
                    
                    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                        UploadService.deleteItem(item: item, completion: { success in
                            if success {
                               self.dismissPopup(true)
                            }
                        })
                    }
                    deleteController.addAction(deleteAction)
                    
                    self.present(deleteController, animated: true, completion: nil)
                } else {
                    UploadService.deleteItem(item: item, completion: { success in
                        if success {
                            self.dismissPopup(true)
                        }
                    })
                }
            }
            actionSheet.addAction(deleteActionButton)
            
            self.present(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(cancelActionButton)
            
            let OKAction = UIAlertAction(title: "Report", style: .destructive) { (action) in
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "It's Inappropriate", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Inappropriate, showNotification: true, completion: { success in
                        if success {
                            let reportAlert = UIAlertController(title: "Report Sent.",
                                                                message: "Thanks for lettings us know. We will act upon this report within 24 hours.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        } else {
                            let reportAlert = UIAlertController(title: "Report Failed to Send.",
                                                                message: "Please try again.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        }
                        
                        
                    })
                }
                alertController.addAction(OKAction)
                
                let OKAction2 = UIAlertAction(title: "It's Spam", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Spam, showNotification: true, completion: { success in
                        if success {
                            let reportAlert = UIAlertController(title: "Report Sent",
                                                                message: "Thanks for lettings us know. We will act upon this report within 24 hours.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        } else {
                            let reportAlert = UIAlertController(title: "Report Failed to Send",
                                                                message: "Please try again.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        }
                        
                        
                    })
                }
                alertController.addAction(OKAction2)
                
                self.present(alertController, animated: true, completion: nil)
            }
            actionSheet.addAction(OKAction)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func getCurrentCell() -> PostViewController? {
        if let cell = collectionView.visibleCells.first as? PostViewController {
            return cell
        }
        return nil
    }
    
    func stopPreviousItem() {
        if let cell = getCurrentCell() {
            cell.pauseVideo()
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
        
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        
        
        let newItem = Int(xOffset / self.collectionView.frame.width)
        currentIndex = IndexPath(item: newItem, section: 0)
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! PostViewController
        cell.reset()
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func keyboardWillAppear() {
        collectionView.isScrollEnabled = false
    }
    
    func keyboardWillDisappear() {
        collectionView.isScrollEnabled = true
    }
    
}

extension GalleryViewController: View2ViewTransitionPresented {
    
    func destinationFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
        //let cell: StoryViewController = self.collectionView.cellForItemAtIndexPath(indexPath) as! StoryViewController
        
        //cell.prepareForTransition(isPresenting)
        
        return view
        
    }
    
    func prepareDestinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
            currentIndex = indexPath
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
}

