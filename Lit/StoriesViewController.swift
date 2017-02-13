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

protocol PopupProtocol {
    func showUser(_ uid:String)
    func showUsersList(_ uids:[String], _ title:String)
    func showOptions()
    func dismissPopup(_ animated:Bool)
}

class StoriesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate, PopupProtocol {
    
    weak var transitionController: TransitionController!
    
    var label:UILabel!
    var tabBarRef:MasterTabBarController!
    var userStories = [UserStory]()
    var currentIndex:IndexPath!
    var collectionView:UICollectionView!
    
    var longPressGR:UILongPressGestureRecognizer!
    var tapGR:UITapGestureRecognizer!
    
    var returnIndex:Int?
    var firstCell = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarRef.setTabBarVisible(_visible: false, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
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
        
        if let cell = getCurrentCell() {
            
            cell.setForPlay()
            //cell.phaseInCaption(animated:true)
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        tabBarRef.setTabBarVisible(_visible: true, animated: true)
        clearDirectory(name: "temp")
        
        for cell in collectionView.visibleCells as! [StoryViewController] {
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
        
        collectionView.register(StoryViewController.self, forCellWithReuseIdentifier: "presented_cell")
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
        
        longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGR.minimumPressDuration = 0.5
        longPressGR.delegate = self
        self.view.addGestureRecognizer(longPressGR)
        
        tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGR.delegate = self
        self.view.addGestureRecognizer(tapGR)
        
    }
    
    func appMovedToBackground() {
        dismissPopup(false)
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .began {
            getCurrentCell()?.pauseStory()
            getCurrentCell()?.focusItem()
            self.collectionView.isScrollEnabled = false
        }
        if gestureReconizer.state == UIGestureRecognizerState.ended {
            getCurrentCell()?.resumeStory()
            getCurrentCell()?.unfocusItem()
            self.collectionView.isScrollEnabled = true
        }
    }
    
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        getCurrentCell()?.tapped(gesture: gestureRecognizer)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cell = getCurrentCell() else { return false }
        let point = gestureRecognizer.location(ofTouch: 0, in: self.view)
        let authorBottomY = cell.authorOverlay.frame.origin.y + cell.authorOverlay.frame.height
        let commentsTableHeight = cell.commentsView.getTableHeight()
        let commentsTopY = cell.infoView.frame.origin.y - commentsTableHeight
        if cell.keyboardUp {
            if point.y > commentsTopY {
                return false
            }
        } else {
            if point.y < authorBottomY || point.y > commentsTopY {
                return false
            }
        }

        
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer  {
            return !cell.keyboardUp
        }
        
        if let _ = gestureRecognizer as? UITapGestureRecognizer  {
            return true
        }

        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?

            let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
            
            if cell.keyboardUp {
                if translate.y > 0 {
                    cell.commentBar.textField.resignFirstResponder()
                }
                return false
            }
            
            if translate.y < 0 {
                cell.commentBar.textField.becomeFirstResponder()
            }

            return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
        }
        return false
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userStories.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: StoryViewController = collectionView.dequeueReusableCell(withReuseIdentifier: "presented_cell", for: indexPath as IndexPath) as! StoryViewController
        cell.contentView.backgroundColor = UIColor.black
        cell.delegate = self
        print("user return index: \(returnIndex)")
        cell.prepareStory(withStory: userStories[indexPath.item], atIndex: returnIndex)
        returnIndex = nil
        if firstCell {
            firstCell = false
            //cell.captionView.backgroundView!.isHidden = true
        }
        
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
        guard let cell = getCurrentCell() else { return }
        returnIndex = cell.viewIndex
        print("set return index: \(returnIndex)")
        self.navigationController?.delegate = self
        let controller = UserProfileViewController()
        controller.uid = uid
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showUsersList(_ uids:[String], _ title:String) {
        self.navigationController?.delegate = self
        let controller = UsersListViewController()
        controller.title = title
        controller.tempIds = uids
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
    func showLocation(location:Location) {
        self.navigationController?.delegate = self
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "LocationViewController") as! LocationViewController
        controller.location = location
        self.navigationController?.pushViewController(controller, animated: true)
    }
    

    func showOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else {
            cell.resumeStory()
            return }
        
        if cell.story.getUserId() == mainStore.state.userState.uid {
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resumeStory()
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
                    cell.shouldPlay = true
                    cell.setupItem()
                    cell.resumeStory()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
                    cell.resumeStory()
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
            actionSheet.addAction(captionActionButton)
            
            let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive) { action -> Void in
                
                if item.postPoints() > 1 {
                    let deleteController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                        cell.resumeStory()
                    }
                    deleteController.addAction(cancelAction)
                    let storyAction: UIAlertAction = UIAlertAction(title: "Remove from my story", style: .destructive)
                    { action -> Void in
                        UploadService.removeItemFromStory(item: item, completion: {
                            self.dismissPopup(true)
                        })
                    }
                    deleteController.addAction(storyAction)
                    
                    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                        UploadService.deleteItem(item: item, completion: {
                            self.dismissPopup(true)
                        })
                    }
                    deleteController.addAction(deleteAction)
                    
                    self.present(deleteController, animated: true, completion: nil)
                } else {
                    UploadService.deleteItem(item: item, completion: {
                        self.dismissPopup(true)
                    })
                }
            }
            actionSheet.addAction(deleteActionButton)
            
            self.present(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resumeStory()
            }
            actionSheet.addAction(cancelActionButton)
            
            let OKAction = UIAlertAction(title: "Report", style: .destructive) { (action) in
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                    cell.resumeStory()
                }
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "It's Inappropriate", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Inappropriate, showNotification: true, completion: { success in
                        
                        cell.resumeStory()
                    })
                }
                alertController.addAction(OKAction)
                
                let OKAction2 = UIAlertAction(title: "It's Spam", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Spam, showNotification: true, completion: { success in
                        
                        cell.resumeStory()
                    })
                }
                alertController.addAction(OKAction2)
                
                self.present(alertController, animated: true) {
                    cell.resumeStory()
                }
            }
            actionSheet.addAction(OKAction)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
        
    }
    
    func getCurrentCell() -> StoryViewController? {
        if let cell = collectionView.visibleCells.first as? StoryViewController {
            return cell
        }
        return nil
    }
    
    func getCurrentCellIndex() -> IndexPath {
        return collectionView.indexPathsForVisibleItems[0]
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
        let cell = cell as! StoryViewController
    
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

extension StoriesViewController: View2ViewTransitionPresented {
    
    func destinationFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
        let cell: StoryViewController = self.collectionView.cellForItem(at: indexPath) as! StoryViewController
        
        cell.prepareForTransition(isPresenting: isPresenting)
        
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


public class PresentingCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let view: UIImageView = UIImageView(frame: self.contentView.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.gray
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
}

