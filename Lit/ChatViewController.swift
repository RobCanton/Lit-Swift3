//
//  ChatViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import ReSwift
import Firebase




class ChatViewController: JSQMessagesViewController, GetUserProtocol {
    

    var isEmpty = false
    var refreshControl: UIRefreshControl!

    //var containerDelegate:ContainerViewController?
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(white: 0.3, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: accentColor)
    var messages:[JSQMessage]!
    
    var settingUp = true
    
    var conversation:Conversation!
    var partner:User!
    {
        didSet {
            
            self.title = partner.getDisplayName()
//            if containerDelegate != nil {
//                containerDelegate?.title = partner.getDisplayName()
//            }

        }
    }
    
    var partnerImage:UIImage?
    

    func userLoaded(user: User) {
        partner = user
       
    }

    var activityIndicator:UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        messages = [JSQMessage]()
        // Do any additional setup after loading the view, typically from a nib.
        self.collectionView?.backgroundColor = UIColor.black
        self.navigationController?.navigationBar.backItem?.backBarButtonItem?.title = " "
        
        self.inputToolbar.barTintColor = UIColor.black
        self.inputToolbar.contentView.leftBarButtonItemWidth = 0
        self.inputToolbar.contentView.textView.keyboardAppearance = .dark
        self.inputToolbar.contentView.textView.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        self.inputToolbar.contentView.textView.textColor = UIColor.white
        self.inputToolbar.contentView.textView.layer.borderColor = UIColor(white: 0.10, alpha: 1.0).cgColor
        self.inputToolbar.contentView.textView.layer.borderWidth = 1.0
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        collectionView?.collectionViewLayout.springinessEnabled = true
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x:0,y:0,width:50,height:50))
        activityIndicator.activityIndicatorViewStyle = .white
        activityIndicator.center = CGPoint(x:UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2 - 50)
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()


        conversation.delegate = self
        if let user = conversation.getPartner() {
            partner = user
        }
        
        downloadRef = UserService.ref.child("conversations/\(conversation.getKey())/messages")
        
        downloadRef?.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() {
                self.stopActivityIndicator()
            }
        })

        self.setup()
        self.downloadMessages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name:NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func startActivityIndicator() {
        DispatchQueue.main.async {
            if self.settingUp {
               self.activityIndicator.startAnimating()
            }
        }
    }
    
    
    func stopActivityIndicator() {
        if settingUp {
            settingUp = false
            print("Swtich activity indicator")
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.refreshControl = UIRefreshControl()
                self.refreshControl.tintColor = UIColor.white
                self.refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
                self.collectionView?.addSubview(self.refreshControl)

            }
        }
    }
    
    func handleRefresh() {
        let oldestLoadedMessage = messages[0]
        let date = oldestLoadedMessage.date!
        let endTimestamp = date.timeIntervalSince1970 * 1000
        
        limit += 16
        downloadRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).queryEnding(atValue: endTimestamp).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var messageBatch = [JSQMessage]()
                let dict = snapshot.value as! [String:AnyObject]
                
                for message in snapshot.children {
                    let messageSnap = message as! FIRDataSnapshot
                    let value = messageSnap.value as! [String: Any]
                    let senderId  = value["senderId"] as! String
                    let text      = value["text"] as! String
                    let timestamp = value["timestamp"] as! Double

                    if timestamp != endTimestamp {
                        let date = Date(timeIntervalSince1970: timestamp/1000)
                        let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                        messageBatch.append(message!)
                    }

                }

                if messageBatch.count > 0 {
                    self.messages.insert(contentsOf: messageBatch, at: 0)
                    self.reloadMessagesView()
                    self.refreshControl.endRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                    self.refreshControl.isEnabled = false
                    self.refreshControl.removeFromSuperview()
                }
            } else {
                self.refreshControl.endRefreshing()
                self.refreshControl.isEnabled = false
                self.refreshControl.removeFromSuperview()
            }
        })
    }
    
    func appMovedToBackground() {
        //downloadRef?.removeAllObservers()
        //conversation.listenToConversation()
    }
    
    func appWillEnterForeground() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        downloadRef?.removeAllObservers()
        conversation.listen()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
        //set seen timestamp
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("conversations/\(conversation.getKey())/\(uid)")
        ref.updateChildValues(["seen": [".sv":"timestamp"]])
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    
    
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return nil
        default:
            if partnerImage != nil {
                let image = JSQMessagesAvatarImageFactory.avatarImage(with: partnerImage!, diameter: 48)
                return image
            }
            
            return nil
        }
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            cell.textView?.textColor = UIColor(white: 0.96, alpha: 1.0)
        default:
            cell.textView?.textColor = UIColor(white: 0.96, alpha: 1.0)
        }
        return cell
    }
    
    
    override func collectionView
        
        (_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let currentItem = self.messages[indexPath.item]
        
        if indexPath.item == 0 && messages.count > 8 {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentItem.date)
        }
        
        
        if indexPath.item > 0 {
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSince(prevItem.date)
            
            if gap > 1800 {
                return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentItem.date)
            }
        } else {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentItem.date)
        }
        
        
        return nil
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let currentItem = self.messages[indexPath.item]
        
        if indexPath.item == 0 && messages.count > 8 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        if indexPath.item > 0 {
            let currentItem = self.messages[indexPath.item]
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSince(prevItem.date)//timeIntervalSinceDate(prevItem.date)
            
            if gap > 1800 {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
            
            if prevItem.senderId != currentItem.senderId {
                return 1.0
            }
        }  else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
            let prevItem = indexPath.item - 1
            
            if prevItem >= 0 {
                let prevMessage = messages[prevItem]
                if prevMessage.isMediaMessage {
                    return kJSQMessagesCollectionViewCellLabelHeightDefault
                }
            }
            return 0.0
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let prevItem = indexPath.item - 1
        
        if prevItem >= 0 {
            let prevMessage = messages[prevItem]
            if prevMessage.isMediaMessage {
                return NSAttributedString(string: "            Temporary message.", attributes: nil)
            }
        }
        return NSAttributedString(string: "")
    }
        
        
    
        
    var loadingNextBatch = false
    var downloadRef:FIRDatabaseReference?
    
    var lastTimeStamp:Double?
    var limit:UInt = 16

}

//MARK - Setup
extension ChatViewController {
    
    func setup() {
        self.senderId = mainStore.state.userState.uid
        self.senderDisplayName = ""
    }
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        UserService.sendMessage(conversation: conversation, message: text, uploadKey: nil, completion: nil)
        self.finishSendingMessage(animated: true)
    }

    

    func downloadMessages() {
        
        self.messages = []

        downloadRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).observe(.childAdded, with: { snapshot in
            let dict = snapshot.value as! [String:AnyObject]
        
            let senderId  = dict["senderId"] as! String
            let text      = dict["text"] as! String
            let timestamp = dict["timestamp"] as! Double
            
            let date = NSDate(timeIntervalSince1970: timestamp/1000)
        
//            if let uploadKey = snapshot.value!["upload"] as? String {
//                let mediaItem = AsyncPhotoMediaItem(withURL: uploadKey)
//                let mediaMessage = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, media: mediaItem)
//                let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
//                self.messages.append(mediaMessage)
//                self.messages.append(message)
//                self.reloadMessagesView()
//                self.stopActivityIndicator()
//                self.finishReceivingMessageAnimated(true)
//                //SocialService.deleteMessage(self.conversation, messageKey: snapshot.key)
//                
//            } else {
                let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date as Date!, text: text)
                self.messages.append(message!)
                self.reloadMessagesView()
                self.stopActivityIndicator()
                self.finishReceivingMessage(animated: true)
            //
        
        })
    }

}

class AsyncPhotoMediaItem: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(withURL url: String) {
        super.init()

        let size = UIScreen.main.bounds
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRect(x: 0, y: 0, width: size.width * 0.5, height: size.height * 0.35)
        asyncImageView.contentMode = .scaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 5
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGray()
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.withActivityIndicator()
        activityIndicator?.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator!)
        
        
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            if image != nil {
                self.asyncImageView.image = image!
                activityIndicator?.removeFromSuperview()
            }
        })
    }
    
    override func mediaView() -> UIView! {
        return asyncImageView
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        return asyncImageView.frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
