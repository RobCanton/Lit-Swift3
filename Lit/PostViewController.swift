import UIKit
import AVFoundation
import Firebase
import NVActivityIndicatorView

public class PostViewController: UICollectionViewCell, ItemDelegate, StoryHeaderProtocol,  CommentBarProtocol {
    
    
    var tap:UITapGestureRecognizer!
    var playerLayer:AVPlayerLayer?
    var activityView:NVActivityIndicatorView!
    
    var commentsRef:FIRDatabaseReference?
    
    var keyboardUp = false
    
    var delegate:PopupProtocol?
    
    func showOptions() {
        pauseVideo()
        delegate?.showOptions()
    }
    
    var shouldPlay = false
    
    var flagLabel:UILabel?
    
    func addFlagLabel() {
        flagLabel?.removeFromSuperview()
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        
        let str = "⚠️ Flagged as Inappropriate\n\nSelect 'Allow Flagged Content' in the settings menu to unblock."
        flagLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: 60))
        flagLabel!.textAlignment = .center
        flagLabel!.center = CGPoint(x: width/2, y: height/2)
        flagLabel!.numberOfLines = 0
        
        let font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightRegular)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : UIColor(white: 1.0, alpha: 0.65)
        ]
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        if let range = str.range(of: "⚠️ Flagged as Inappropriate") {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightRegular),//UIFont(name: "AvenirNext-Medium", size: 16)!,
                NSForegroundColorAttributeName : UIColor.white
            ]
            title.addAttributes(a, range: NSRange(location: index, length: "⚠️ Flagged as Inappropriate".characters.count + 1))
        }
        
        flagLabel!.attributedText = title
        
        contentView.addSubview(flagLabel!)
        
    }
    
    
    var storyItem:StoryItem! {
        didSet {
            storyItem.delegate = self
            shouldPlay = false
            infoView.authorTappedHandler = showUser
            authorOverlay.delegate = self
            commentBar.delegate = self
            commentsView.userTapped = showUser
            setItem()
            
            NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
    }
    
    func showUser(_ uid: String) {
        print("SHOW USER: \(uid)")
        delegate?.showUser(uid)
    }
    
    func showViewers() {
        guard let item = self.storyItem else { return }
        if item.authorId == mainStore.state.userState.uid {
            delegate?.showUsersList(item.getViewsList(), "Views")
        }
    }
    
    func showLikes() {
        guard let item = self.storyItem else { return }
        delegate?.showUsersList(item.getLikesList(), "Likes")
    }
    
    func more() {
        delegate?.showOptions()
    }
    
    func sendComment(_ comment: String) {
        guard let item = self.storyItem else { return }
        UploadService.addComment(post: item, comment: comment)
    }
    
    func toggleLike(_ like: Bool) {
        guard let item = self.storyItem else { return }
        
        if like {
            UploadService.addLike(post: item)
            item.addLike(mainStore.state.userState.uid)
        } else {
            UploadService.removeLike(postKey: item.getKey())
            item.removeLike(mainStore.state.userState.uid)
        }
        authorOverlay.setViews(post: item)
        authorOverlay.setLikes(post: item)
    }
    var animateInitiated = false
    
    var shouldAnimate = false
    func animateIndicator() {
        shouldAnimate = true
        if !animateInitiated {
            animateInitiated = true
            DispatchQueue.main.async {
                if self.shouldAnimate {
                    self.activityView.startAnimating()
                }
            }
        }
    }
    
    func stopIndicator() {
        shouldAnimate = false
        if activityView.animating {
            DispatchQueue.main.async {
                self.activityView.stopAnimating()
                self.animateInitiated = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.authorOverlay)
        self.contentView.addSubview(self.commentsView)
        
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        enableTap()
        videoContent.isHidden = true
        
        commentBar.textField.delegate = self
        contentView.addSubview(commentBar)
        
        commentsView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - commentsView.frame.height,width: commentsView.frame.width,height: commentsView.frame.height)
        
        
        /*
         Info view
         */
        infoView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - infoView.frame.height,width: self.frame.width,height: infoView.frame.height)
        infoView.backgroundBlur.isHidden = true
        contentView.addSubview(infoView)
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballScaleRipple, color: UIColor.white, padding: 1.0, speed: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
    }
    
    func setItem() {
        guard let item = storyItem else { return }

        flagLabel?.removeFromSuperview()
        
        if item.shouldBlock() {
            addFlagLabel()
            content.alpha = 0.0
            videoContent.alpha = 0.0
        } else {
            content.alpha = 1.0
            videoContent.alpha = 1.0
        }
        
        
        if let image = storyItem.image {
            stopIndicator()
            self.content.image = image
        } else {
            NotificationCenter.default.removeObserver(self)
            animateIndicator()
            storyItem.download()
        }
        
        if item.contentType == .video {
            
            if let videoURL = UploadService.readVideoFromFile(withKey: item.getKey()) {
                stopIndicator()
                createVideoPlayer()
                let asset = AVAsset(url: videoURL)
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
                animateIndicator()
                storyItem.download()
            }
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
            size =  UILabel.size(withText: caption, forWidth: width, withFont: UIFont(name: "AvenirNext-Medium", size: 15.0)!).height + 34
            infoView.isHidden = false
        } else {
            infoView.isHidden = true
        }
        
        infoView.frame = CGRect(x: 0, y: commentBar.frame.origin.y - size, width: frame.width, height: size)
        infoView.authorTappedHandler = showUser
        
        commentsView.setTableComments(comments: item.comments, animated: false)
        commentsView.frame = CGRect(x: 0, y: getCommentsViewOriginY(), width: commentsView.frame.width, height: commentsView.frame.height)
        let uid = mainStore.state.userState.uid
        commentBar.setLikedStatus(item.likes[uid] != nil, animated: false)
        commentBar.likeButton.isHidden = item.authorId == uid
    }
    
    
    func itemDownloaded() {
        //activityView?.stopAnimating()
        setItem()
    }
    
    
    
    func setForPlay(){
        
        if storyItem.needsDownload() {
            shouldPlay = true
            return
        }
        
        shouldPlay = false
        
        if storyItem.contentType == .image {
            videoContent.isHidden = true
            
        } else if storyItem.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            loopVideo()
        }
        
        infoView.phaseInCaption()
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/\(storyItem.getKey())/comments")
        
        if let lastItem = storyItem.comments.last {
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
                    self.storyItem.addComment(comment)
                    self.commentsView.setTableComments(comments: self.storyItem.comments, animated: true)
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
                self.storyItem.addComment(comment)
                self.commentsView.setTableComments(comments: self.storyItem.comments, animated: true)
            })
        }
    }
    
    func loopVideo() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            self.playerLayer?.player?.seek(to: kCMTimeZero)
            self.playerLayer?.player?.play()
        }
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
    
    func playVideo() {
        guard let item = self.storyItem else { return }
        
        if !item.shouldBlock() {
            self.playerLayer?.player?.play()
        }
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    func prepareForTransition(isPresenting:Bool) {
        content.isHidden = false
        videoContent.isHidden = true
    }
    
    func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        content.image = nil
        destroyVideoPlayer()
    }
    
    func reset() {
        content.isHidden = false
        videoContent.isHidden = true
        resetVideo()
        commentsRef?.removeAllObservers()
        infoView.backgroundBlur.isHidden = true
        infoView.backgroundBlur.removeAnimation()
    }
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.isHidden = true
    }
    
    func enableTap() {
        self.addGestureRecognizer(tap)
    }
    
    func disableTap() {
        self.removeGestureRecognizer(tap)
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        if keyboardUp {
            commentBar.textField.resignFirstResponder()
        }
    }
    
    func getCommentsViewOriginY() -> CGFloat {
        return commentBar.frame.origin.y - infoView.frame.height - commentsView.frame.height
    }
    
    func focusItem() {
        UIView.animate(withDuration: 0.15, animations: {
            self.commentsView.alpha = 0.0
            self.authorOverlay.alpha = 0.0
            self.infoView.alpha = 0.0
            self.commentBar.alpha = 0.0
        })
    }
    
    func unfocusItem() {
        UIView.animate(withDuration: 0.2, animations: {
            self.commentsView.alpha = 1.0
            self.authorOverlay.alpha = 1.0
            self.infoView.alpha = 1.0
            self.commentBar.alpha = 1.0
        })
    }
    
    
    func keyboardWillAppear(notification: NSNotification){
        
        keyboardUp = true
        
        
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
            
            self.authorOverlay.alpha = 0.0

        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
        
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
            
            self.authorOverlay.alpha = 1.0

            
        }, completion:  { result in
            
        })
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let margin: CGFloat = 2.0
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let frame = CGRect(x: 0,y: 0,width: width,height: height + 0)
        let view: UIImageView = UIImageView(frame: frame)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var authorOverlay: PostAuthorView = {
        let margin:CGFloat = 2.0
        var authorView = UINib(nibName: "PostAuthorView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostAuthorView
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        authorView.frame = CGRect(x: margin, y: margin, width: width, height: authorView.frame.height)
        return authorView
    }()
    
    lazy var commentsView: CommentsView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var commentsView = CommentsView(frame: CGRect(x: 0, y: height / 2, width: width, height: height * 0.32 ))
        
        return commentsView
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

extension PostViewController: UITextFieldDelegate {
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
