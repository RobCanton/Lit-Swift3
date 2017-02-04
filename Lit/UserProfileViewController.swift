//
//  UserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import View2ViewTransition
import Firebase

class MyUserProfileViewController: UserProfileViewController {
    
    override func viewDidLoad() {
        uid = mainStore.state.userState.uid
        super.viewDidLoad()
    }

}

class UserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, EditProfileProtocol {
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var posts = [StoryItem]()
    var collectionView:UICollectionView!
    var user:User?
    
    var uid:String!
    
    var followers = [String]()
        {
        didSet {
            getHeaderView()?.setFollowersCount(count: followers.count)
        }
    }
    var following = [String]()
        {
        didSet {
            getHeaderView()?.setFollowingCount(count: following.count)
        }
    }
    
    var postKeys = [String]()
        {
        didSet {
            
            getHeaderView()?.setPostsCount(count: postKeys.count)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.white]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 0,width: view.frame.width,height: view.frame.height), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "ProfileHeaderView", bundle: nil)
        
        self.collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView.contentInset = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.black
        self.view.addSubview(collectionView)
        
        getFullUser()
    
    }
    
    func getFullUser() {
        self.getHeaderView()?.fetched = false
        UserService.getUser(uid, completion: { _user in
            if _user != nil {
                
                self.navigationItem.title = _user!.getDisplayName()
                UserService.getUserFullProfile(user: _user!, completion: { fullUser in
                    
                    //self.getKeys()
                    self.user = fullUser
                    if self.user!.getUserId() == mainStore.state.userState.uid {
                        mainStore.dispatch(UpdateUser(user: self.user!))
                    }

                    self.collectionView?.reloadData()
                    UserService.listenToFollowers(uid: self.user!.getUserId(), completion: { followers in
                        self.followers = followers
                    })
                    
                    UserService.listenToFollowing(uid: self.user!.getUserId(), completion: { following in
                        self.following = following
                    })
                })
            }
        })
    }
    
    var largeImageURL:String?
    var bio:String?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = self
        
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            
            nav.delegate = nav
        }
        listenToPosts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        UserService.stopListeningToFollowers(uid: uid)
        UserService.stopListeningToFollowing(uid: uid)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListeningToPosts()
    }
    
    func newState(state: AppState) {
        let status = checkFollowingStatus(uid: uid)
        getHeaderView()?.setUserStatus(status: status)
    }
    
    func followersBlockTapped() {
        if followers.count == 0 { return }
        let controller = UsersListViewController()
        controller.title = "Followers"
        controller.tempIds = followers
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func followingBlockTapped() {
        if following.count == 0 { return }
        let controller = UsersListViewController()
        controller.title = "Following"
        controller.tempIds = following
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func messageBlockTapped() {
        
        let current_uid = mainStore.state.userState.uid
        guard let partner_uid = uid else { return }
        if current_uid == partner_uid { return }
        if let conversation = checkForExistingConversation(partner_uid: current_uid) {
            prepareConverstaionForPresentation(conversation: conversation)
        } else {
            
            let pairKey = createUserIdPairKey(uid1: current_uid, uid2: partner_uid)
            let ref = UserService.ref.child("conversations/\(pairKey)")
            ref.child(uid).setValue(["seen": [".sv":"timestamp"]], withCompletionBlock: { error, ref in
                
                let recipientUserRef = UserService.ref.child("users/conversations/\(partner_uid)")
                recipientUserRef.child(current_uid).setValue(true)
                
                let currentUserRef = UserService.ref.child("users/conversations/\(current_uid)")
                currentUserRef.child(partner_uid).setValue(true, withCompletionBlock: { error, ref in
                    let conversation = Conversation(key: pairKey, partner_uid: partner_uid)
                    self.presentingEmptyConversation = true
                    self.prepareConverstaionForPresentation(conversation: conversation)
                })
            })
        }
    }
    
    var presentingEmptyConversation = false
    
    
    func editProfileTapped() {
        let controller = UIStoryboard(name: "EditProfileViewController", bundle: nil)
            .instantiateViewController(withIdentifier: "EditProfileNavigationController") as! UINavigationController
        let c = controller.viewControllers[0] as! EditProfileViewController
        c.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    var presentConversation:Conversation?
    var partnerImage:UIImage?
    
    func prepareConverstaionForPresentation(conversation:Conversation) {
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.presentConversation(conversation: conversation, user: user!)
            }
        })
    }
    
    func presentConversation(conversation:Conversation, user:User) {
        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromCache in
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            controller.conversation = conversation
            controller.partnerImage = image
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.pushViewController(controller, animated: true)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //        if segue.identifier == "toMessage" {
        //            guard let conversation = presentConversation else { return }
        //            let controller = segue.destinationViewController as! ContainerViewController
        //            controller.isEmpty = presentingEmptyConversation
        //            controller.hidesBottomBarWhenPushed = true
        //            controller.conversation = conversation
        //            controller.partnerImage = partnerImage
        //        }
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let staticHeight:CGFloat = 275 + 50 + 4 + 56
        if user != nil {
            if let text = self.user!.bio {
                if text != "" {
                    var size =  UILabel.size(withText: text, forWidth: collectionView.frame.size.width, withFont: UIFont(name: "AvenirNext-Regular", size: 14.0)!)
                    let height2 = size.height + staticHeight + 10  // +8 for some bio padding
                    size.height = height2
                    return size
                }
            }
            
        }
        let size =  CGSize(width: collectionView.frame.size.width, height: staticHeight) // +8 for some empty padding
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! ProfileHeaderView
            if user != nil {
                view.populateHeader(user: user!)
                
            }
            view.followersHandler = followersBlockTapped
            view.followingHandler = followingBlockTapped
            view.messageHandler = messageBlockTapped
            
            view.editProfileHandler = editProfileTapped
            view.unfollowHandler = unfollowHandler
            view.setPostsCount(count: postKeys.count)
            view.setFollowersCount(count: followers.count)
            view.setFollowingCount(count: following.count)
            return view
        }
        
        return UICollectionReusableView()
    }
    
    var postsRef:FIRDatabaseReference?
    
    func listenToPosts() {

        guard let userId = uid else { return }
        postsRef = UserService.ref.child("users/uploads/\(userId)")
        postsRef?.observeSingleEvent(of: .value, with: { snapshot in
            var postKeys = [String]()
            if snapshot.exists() {
                let keys = snapshot.value as! [String:AnyObject]
                for (key, _) in keys {
                    postKeys.append(key)
                }
            }
            self.postKeys = postKeys
            self.downloadStory(postKeys: postKeys)
        })
    }
    
    func stopListeningToPosts() {
        postsRef?.removeAllObservers()
    }
    
    func downloadStory(postKeys:[String]) {
        if postKeys.count > 0 {
            UploadService.downloadStory(postKeys: postKeys, completion: { story in
                
                self.posts = story.sorted(by: { return $0 > $1 })
                self.collectionView!.reloadData()
            })
        } else {
            self.posts = [StoryItem]()
            self.collectionView.reloadData()
        }
        
    }
    
    func unfollowHandler(user:User) {
        let actionSheet = UIAlertController(title: nil, message: "Unfollow \(user.getDisplayName())?", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Unfollow", style: .destructive)
        { action -> Void in
            
            UserService.unfollowUser(uid: user.getUserId())
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        cell.setPhoto(item: posts[indexPath.item])
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength)
    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
         
         self.selectedIndexPath = indexPath
         
         let galleryViewController: GalleryViewController = GalleryViewController()
         
         guard let tabBarController = self.tabBarController as? MasterTabBarController else { return }
         galleryViewController.uid = uid
         galleryViewController.posts = self.posts
         galleryViewController.tabBarRef = tabBarController
         galleryViewController.transitionController = self.transitionController
         self.transitionController.userInfo = ["destinationIndexPath": indexPath as AnyObject, "initialIndexPath": indexPath as AnyObject]
         self.transitionController.rounded = false
         
         // This example will push view controller if presenting view controller has navigation controller.
         // Otherwise, present another view controller
         if let navigationController = self.navigationController {
         
         // Set transitionController as a navigation controller delegate and push.
         navigationController.delegate = transitionController
         transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
         
         }
    }

    
    func getHeaderView() -> ProfileHeaderView? {
        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? ProfileHeaderView {
            return header
        }
        return nil
    }
    
}

extension UserProfileViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath, let attributes: UICollectionViewLayoutAttributes = self.collectionView!.layoutAttributesForItem(at: indexPath) else {
            return CGRect.zero
        }
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let rect = CGRect(x: attributes.frame.origin.x, y: attributes.frame.origin.y + navHeight, width: attributes.frame.width, height: attributes.frame.height)
        return self.collectionView!.convert(rect, to: self.collectionView!.superview)
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let cell: UICollectionViewCell = self.collectionView!.cellForItem(at: indexPath)!
        
        return cell.contentView
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        
        if !isPresenting && !self.collectionView!.indexPathsForVisibleItems.contains(indexPath) {
            self.collectionView!.reloadData()
            self.collectionView!.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.collectionView!.layoutIfNeeded()
        }
    }
    
    func dismissInteractionEnded(completed: Bool) {
        if completed {
            
        }
    }
}


