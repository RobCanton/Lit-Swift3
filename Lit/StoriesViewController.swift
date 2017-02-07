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

class StoriesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    weak var transitionController: TransitionController!
    
    var label:UILabel!
    var tabBarRef:MasterTabBarController!
    var userStories = [UserStory]()
    var currentIndex:IndexPath!
    var collectionView:UICollectionView!
    
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
            cell.phaseInCaption(animated:true)
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
        
        for cell in collectionView.visibleCells as! [StoryViewController] {
            cell.yo()
        }
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
        
    }
    
    func appMovedToBackground() {
        popStoryController(animated: false)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cell = getCurrentCell() else { return false }

        
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
        
        if cell.keyboardUp {
            if translate.y > 0 {
                cell.dismissKeyboard()
            }
            return false
        } else if !cell.keyboardUp && translate.y < 0{
            cell.textView.becomeFirstResponder()
        }

        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
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
        cell.story = userStories[indexPath.item]
        cell.authorOverlay.authorTappedHandler = showAuthor
        cell.authorOverlay.locationTappedHandler = showLocation
        cell.authorOverlay.closeHandler = storyComplete
        cell.optionsTappedHandler = showOptions
        cell.storyCompleteHandler = storyComplete
        cell.commentsView.userTapped = showAuthor
        
        if firstCell {
            firstCell = false
            cell.captionView.backgroundView!.isHidden = true
        }
        
        return cell
    }
    
    func popStoryController(animated:Bool) {
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
        navigationController?.popViewController(animated: animated)
    }
    
    
    func storyComplete() {
        popStoryController(animated: true)
    }
    
    func showAuthor(uid:String) {
        self.navigationController?.delegate = self
        let controller = UserProfileViewController()
        controller.uid = uid
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
                            self.popStoryController(animated: true)
                        })
                    }
                    deleteController.addAction(storyAction)
                    
                    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                        UploadService.deleteItem(item: item, completion: {
                            self.popStoryController(animated: true)
                        })
                    }
                    deleteController.addAction(deleteAction)
                    
                    self.present(deleteController, animated: true, completion: nil)
                } else {
                    UploadService.deleteItem(item: item, completion: {
                        self.popStoryController(animated: true)
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
    
        cell.removeTimers()
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

