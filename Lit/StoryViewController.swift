
//
//  StoryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import NVActivityIndicatorView


public class StoryViewController: UICollectionViewCell, StoryProtocol, StoryHeaderProtocol, CommentBarProtocol {

    var viewIndex = 0
    
    func validIndex() -> Bool {
        if let items = story.items {
            return viewIndex >= 0 && viewIndex < items.count
        } else {
            return false
        }
    }
    
    var commentsRef:FIRDatabaseReference?
    
    var item:StoryItem?
    
    var showUser:((_ uid:String)->())?
    var showUsersList:((_ uids:[String], _ title:String)->())?
    var optionsTappedHandler:(()->())?
    var storyCompleteHandler:(()->())?
    var viewsTappedHandler:(()->())?
    var itemSetHandler:((_ item:StoryItem)->())?
    
    var activityView:NVActivityIndicatorView!
    
    func commentsInteractionHandler(interacting:Bool) {
        if interacting || keyboardUp {
            pauseStory()
        } else {
            resumeStory()
        }
    }

    
    func showUser(_ uid: String) {
        showUser?(uid)
    }
    
    func showViewers() {
        guard let item = self.item else { return }
        if item.authorId == mainStore.state.userState.uid {
            showUsersList?(item.getViewsList(), "Views")
        }
    }
    
    func showLikes() {
        guard let item = self.item else { return }
        showUsersList?(item.getLikesList(), "Likes")
    }
    
    func more() {
        pauseStory()
        optionsTappedHandler?()
    }
    
    func sendComment(_ comment: String) {
        guard let item = self.item else { return }
        UploadService.addComment(postKey: item.getKey(), comment: comment)
    }
    
    func toggleLike(_ like: Bool) {
        guard let item = self.item else { return }
        
        if like {
            UploadService.addLike(postKey: item.getKey())
            item.addLike(mainStore.state.userState.uid)
        } else {
            UploadService.removeLike(postKey: item.getKey())
            item.removeLike(mainStore.state.userState.uid)
        }
        authorOverlay.setViews(post: item)
        authorOverlay.setLikes(post: item)
    }
    
    var playerLayer:AVPlayerLayer?
    var currentProgress:Double = 0.0
    var timer:Timer?
    
    var totalTime:Double = 0.0
    
    var progressBar:StoryProgressIndicator?
    
    var shouldPlay = false
    
    var story:UserStory!
        {
        didSet {

            shouldPlay = false
            self.story.delegate = self
            story.determineState()
            
            infoView.authorTappedHandler = showUser
            authorOverlay.delegate = self
            commentBar.delegate = self
            commentsView.userTapped = showUser
            NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
    }
    
    func observeKeyboard() {
        
    }
    
    func removeObserver() {
        
    }
    
    func stateChange(_ state:UserStoryState) {
        switch state {
        case .notLoaded:
            animateIndicator()
            break
        case .loadingItemInfo:
            animateIndicator()
            break
        case .itemInfoLoaded:
            animateIndicator()
            story.downloadStory()
            break
        case .loadingContent:
            animateIndicator()
            break
        case .contentLoaded:
            stopIndicator()
            contentLoaded()
            break
        }
    }
    var animateInitiated = false
    
    func animateIndicator() {
        if !animateInitiated {
            animateInitiated = true
            DispatchQueue.main.async {
                if self.story.state != .contentLoaded {
                    self.activityView.startAnimating()
                    self.infoView.alpha = 0.0
                }
            }
        }
    }
    
    func stopIndicator() {
        if activityView.animating {
            DispatchQueue.main.async {
                self.activityView.stopAnimating()
                self.animateInitiated = false
                self.infoView.alpha = 1.0
            }
        }
    }
    
    
    func contentLoaded() {

        let screenWidth: CGFloat = (UIScreen.main.bounds.size.width)
        let screenHeight: CGFloat = (UIScreen.main.bounds.size.height)
        let margin:CGFloat = 8.0
        progressBar?.removeFromSuperview()
        progressBar = StoryProgressIndicator(frame: CGRect(x: margin,y: margin, width: screenWidth - margin * 2,height: 1.5))
        progressBar!.createProgressIndicator(_story: story)
        contentView.addSubview(progressBar!)
        
        viewIndex = 0
        
        for item in story.items! {
        
            totalTime += item.getLength()
            
            if item.hasViewed() {
                viewIndex += 1
            }
        }
        
        if viewIndex >= story.items!.count{
            viewIndex = 0
        }
        
        self.setupItem()
    }
    
    func setupItem() {
        killTimer()
        pauseVideo()
        
        guard let items = story.items else { return }
        if viewIndex >= items.count { return }
        
        let item = items[viewIndex]
        self.item = item
        itemSetHandler?(item)
        
        if item.contentType == .image {
            prepareImageContent(item: item)
        } else if item.contentType == .video {
            prepareVideoContent(item: item)
        }
        
        UserService.getUser(item.authorId, completion: { user in
            if user != nil {
                self.authorOverlay.setAuthorInfo(user: user!, post: item)
                self.infoView.setInfo(user: user!, item: item)
                
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, _ in
                    if image != nil {
                        self.authorOverlay.setAuthorImage(image: image!)
                        self.infoView.setUserImage(image: image!)
                        
                    }
                })
            }
        })
        
        let caption = item.caption
        let width = self.frame.width - (8 + 8 + 8 + 32)
        var size:CGFloat = 0.0

        if caption != "" {
            size =  UILabel.size(withText: caption, forWidth: width, withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)).height + 34
            infoView.isHidden = false
        } else {
            infoView.isHidden = true
        }

        infoView.frame = CGRect(x: 0, y: commentBar.frame.origin.y - size, width: frame.width, height: size)
        commentsView.commentsInteractionHandler = commentsInteractionHandler
        commentsView.frame = CGRect(x: 0, y: getCommentsViewOriginY(), width: commentsView.frame.width, height: commentsView.frame.height)
        if !looping {
            commentsView.setTableComments(comments: item.comments, animated: false)
        }
        
        let uid = mainStore.state.userState.uid
        
        if !item.hasViewed() && item.authorId != uid{
            item.addView(uid)
            UploadService.addView(postKey: item.getKey())
            authorOverlay.setViews(post: item)
        }

        commentBar.setLikedStatus(item.likes[uid] != nil, animated: false)
        commentBar.likeButton.isHidden = item.authorId == uid
    }

    
    func getCommentsViewOriginY() -> CGFloat {
        return commentBar.frame.origin.y - infoView.frame.height - commentsView.frame.height
    }
    
    func prepareImageContent(item:StoryItem) {
        
        if let image = item.image {
            content.image = image
            self.playerLayer?.player?.replaceCurrentItem(with: nil)
            if self.shouldPlay {
                self.setForPlay()
            }
        } else {
            story.downloadStory()
        }
    }
    
    func prepareVideoContent(item:StoryItem) {
        /* CURRENTLY ASSUMING THAT IMAGE IS LOAD */
        if let image = item.image {
            content.image = image
            
        } else {
            return story.downloadStory()
        }
        createVideoPlayer()
        if let videoData = loadVideoFromCache(key: item.key) {
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filePath = documentsURL.appendingPathComponent("temp/\(item.key).mp4")
            
            try! videoData.write(to: filePath, options: NSData.WritingOptions.atomic)
            
            
            let asset = AVAsset(url: filePath)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                DispatchQueue.main.async {
                    let item = AVPlayerItem(asset: asset)
                    self.playerLayer?.player?.replaceCurrentItem(with: item)
                    
                    if self.shouldPlay {
                        self.setForPlay()
                    }
                }
            })
        } else {
            story.downloadStory()
        }
    }
    
    func setForPlay() {
        if story.state != .contentLoaded {
            shouldPlay = true
            return
        }
        
        guard let item = self.item else {
            shouldPlay = true
            return }
        
        shouldPlay = false
        
        var itemLength = item.getLength()
        if item.contentType == .image {
            videoContent.isHidden = true
            
        } else if item.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            
            if let currentItem = playerLayer?.player?.currentTime() {
                itemLength -= currentItem.seconds
            }
        }
        
        infoView.phaseInCaption()
        
        progressBar?.activateIndicator(itemIndex: viewIndex)
        timer = Timer.scheduledTimer(timeInterval: itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
        
        if !looping {

            commentsRef?.removeAllObservers()
            commentsRef = UserService.ref.child("uploads/\(item.getKey())/comments")
            
            if let lastItem = item.comments.last {
                let lastKey = lastItem.getKey()
                let ts = lastItem.getDate().timeIntervalSince1970 * 1000
                commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childAdded, with: { snapshot in
                    
                    let dict = snapshot.value as! [String:Any]
                    let key = snapshot.key
                    if key != lastKey {
                        let author = dict["author"] as! String
                        let text = dict["text"] as! String
                        let timestamp = dict["timestamp"] as! Double
                        
                        let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                        item.addComment(comment)
                        self.commentsView.setTableComments(comments: item.comments, animated: true)
                    }
                })
            } else {
                commentsRef?.observe(.childAdded, with: { snapshot in
                    let dict = snapshot.value as! [String:Any]
                    let key = snapshot.key
                    let author = dict["author"] as! String
                    let text = dict["text"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                    item.addComment(comment)
                    self.commentsView.setTableComments(comments: item.comments, animated: true)
                })
            }
        }
    }
    
    func nextItem() {
        guard let items = story.items else { return }
        if !looping {
            viewIndex += 1
        }
        
        if viewIndex >= items.count {
            storyCompleteHandler?()
        } else {
            shouldPlay = true
            setupItem()
        }
    }
    
    func prevItem() {
        guard let item = self.item else { return }
        guard let timer = self.timer else { return }
        let remaining = timer.fireDate.timeIntervalSinceNow
        let diff = remaining / item.getLength()
        
        if diff > 0.75 {
            if viewIndex > 0 {
                viewIndex -= 1
            }
        }
        
        shouldPlay = true
        setupItem()
    }

    
    func createVideoPlayer() {
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: AVPlayer())
            playerLayer!.player?.actionAtItemEnd = .pause
            playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            playerLayer!.frame = videoContent.bounds
            self.videoContent.layer.addSublayer(playerLayer!)
        }
    }
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.isHidden = false
        
    }

    func cleanUp() {
        shouldPlay = false
        content.image = nil
        authorOverlay.cleanUp()
        commentsView.cleanUp()
        destroyVideoPlayer()
        killTimer()
        progressBar?.resetAllProgressBars()
        progressBar?.removeFromSuperview()
        commentsRef?.removeAllObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    func reset() {
        killTimer()
        progressBar?.resetActiveIndicator()
        pauseVideo()
        commentsRef?.removeAllObservers()
        infoView.backgroundBlur.isHidden = true
        infoView.backgroundBlur.removeAnimation()
    }
    
    func playVideo() {
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    var looping = false
    
    func resumeStory() {
        if !keyboardUp {
           looping = false
        }
    }
    
    func pauseStory() {
        looping = true
    }
    
    func focusItem() {
        UIView.animate(withDuration: 0.15, animations: {
            self.commentsView.alpha = 0.0
            self.authorOverlay.alpha = 0.0
            self.infoView.alpha = 0.0
            self.commentBar.alpha = 0.0
            self.progressBar?.alpha = 0.0
        })
    }
    
    func unfocusItem() {
        UIView.animate(withDuration: 0.2, animations: {
            self.commentsView.alpha = 1.0
            self.authorOverlay.alpha = 1.0
            self.infoView.alpha = 1.0
            self.commentBar.alpha = 1.0
            self.progressBar?.alpha = 1.0
        })
    }
    
    
    func killTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func prepareForTransition(isPresenting:Bool) {
        content.isHidden = false
        videoContent.isHidden = true
        if isPresenting {
            
        } else {
            killTimer()
            resetVideo()
            progressBar?.resetActiveIndicator()
        }
    }

    
    func tapped(gesture:UITapGestureRecognizer) {
        guard let _ = item else { return }
        if keyboardUp {
            commentBar.textField.resignFirstResponder()
        } else {
            let tappedPoint = gesture.location(in: self)
            let width = self.bounds.width
            if tappedPoint.x < width * 0.25 {
                prevItem()
                prevView.alpha = 1.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.prevView.alpha = 0.0
                })
            } else {
                nextItem()
            }
        }
    }

    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    var keyboardUp = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(gradientView)
        contentView.addSubview(authorOverlay)
        contentView.addSubview(prevView)
        
        
        commentBar.textField.delegate = self
        contentView.addSubview(commentBar)
        
        /*
         Comments view
         */
        commentsView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - commentsView.frame.height,width: commentsView.frame.width,height: commentsView.frame.height)
        contentView.addSubview(commentsView)
        
        /*
         Info view
         */
        infoView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - infoView.frame.height,width: self.frame.width,height: infoView.frame.height)
        infoView.backgroundBlur.isHidden = true
        contentView.addSubview(infoView)
        
        /*
         Activity view
         */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballScaleRipple, color: UIColor.white, padding: 1.0, speed: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
    }
    
    func keyboardWillAppear(notification: NSNotification){

        keyboardUp = true
        looping = true
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.commentBar.likeButton.isUserInteractionEnabled = false
        self.commentBar.moreButton.isUserInteractionEnabled = false
        self.commentBar.sendButton.isUserInteractionEnabled = true
        self.commentsView.showTimeLabels(visible: true)
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            
            self.commentsView.frame = CGRect(x: 0,y: self.getCommentsViewOriginY(),width: self.commentsView.frame.width,height: self.commentsView.frame.height)
            
            let infoFrame = self.infoView.frame
            let infoY = textViewY - infoFrame.height
            self.infoView.frame = CGRect(x: infoFrame.origin.x,y: infoY, width: infoFrame.width, height: infoFrame.height)
            
            self.commentBar.likeButton.alpha = 0.0
            self.commentBar.moreButton.alpha = 0.0
            self.commentBar.sendButton.alpha = 1.0
            self.progressBar?.alpha = 0.0
            self.authorOverlay.alpha = 0.0

        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
        looping = false
        
        self.commentBar.likeButton.isUserInteractionEnabled = true
        self.commentBar.moreButton.isUserInteractionEnabled = true
        self.commentBar.sendButton.isUserInteractionEnabled = false
        self.commentsView.showTimeLabels(visible: false)
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewStart = height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)
            
            self.commentsView.frame = CGRect(x: 0,y: self.getCommentsViewOriginY(),width: self.commentsView.frame.width,height: self.commentsView.frame.height)

            let infoFrame = self.infoView.frame
            let infoY = height - textViewFrame.height - infoFrame.height
            self.infoView.frame = CGRect(x: infoFrame.origin.x,y: infoY, width: infoFrame.width, height: infoFrame.height)
            
            self.commentBar.likeButton.alpha = 1.0
            self.commentBar.moreButton.alpha = 1.0
            self.commentBar.sendButton.alpha = 0.0
            self.progressBar?.alpha = 1.0
            self.authorOverlay.alpha = 1.0

        })
        
    }
    
    func viewsTapped() {
        viewsTappedHandler?()
    }

    func closeTapped(button:UIButton) {
        storyCompleteHandler?()
    }
    
    public lazy var content: UIImageView = {
        let view: UIImageView = UIImageView(frame: self.contentView.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let frame = CGRect(x:0,y:0,width:width,height: height + 0)
        let view: UIImageView = UIImageView(frame: frame)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public lazy var gradientView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: self.bounds.height * 0.3, width: self.bounds.width, height: self.bounds.height * 0.7))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        let dark = UIColor(white: 0.0, alpha: 0.55)
        gradient.colors = [UIColor.clear.cgColor , dark.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    public lazy var prevView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width * 0.4, height: self.bounds.height))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        let dark = UIColor(white: 0.0, alpha: 0.42)
        gradient.colors = [dark.cgColor, UIColor.clear.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        view.isUserInteractionEnabled = false
        view.alpha = 0.0
        return view
    }()
    
    lazy var authorOverlay: PostAuthorView = {
        let margin:CGFloat = 2.0
        var authorView = UINib(nibName: "PostAuthorView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostAuthorView
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        authorView.frame = CGRect(x: margin, y: margin + 8.0, width: width, height: authorView.frame.height)
        return authorView
    }()
    
    lazy var commentsView: CommentsView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        return CommentsView(frame: CGRect(x: 0, y: height / 2, width: width, height: height * 0.32 ))
    }()
   
    lazy var infoView: StoryInfoView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var view: StoryInfoView = UINib(nibName: "StoryInfoView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! StoryInfoView
        return view
    }()
    
    lazy var commentBar: CommentBar = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var view: CommentBar = UINib(nibName: "CommentBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentBar
        view.frame = CGRect(x: 0, y: height - 50.0, width: width, height: 50.0)
        return view
    }()
}
extension StoryViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if !text.isEmpty {
                textField.text = ""
                sendComment(text)
            }
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 140 // Bool
    }
}
extension StoryViewController: UITextViewDelegate {
//    public func textViewDidChange(_ textView: UITextView) {
//        updateTextAndCommentViews()
//    }
//    
//    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//
//        if(text == "\n") {
//            if textView.text.characters.count > 0 {
//                sendComment(comment: textView.text)
//            }
//            return false
//        }
//        return textView.text.characters.count + (text.characters.count - range.length) <= 140
//    }
}
