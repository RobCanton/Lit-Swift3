import UIKit
import AVFoundation
import Firebase

public class PostViewController: UICollectionViewCell, ItemDelegate {
    
    
    var tap:UITapGestureRecognizer!
    var playerLayer:AVPlayerLayer?
    //var activityView:NVActivityIndicatorView!
    
    var commentsRef:FIRDatabaseReference?
    
    var textView:UITextView!
    var commentPlaceHolderLabel:UILabel!
    var keyboardUp = false
    
    var optionsTappedHandler:(()->())?
    
    func showOptions() {
        pauseVideo()
        optionsTappedHandler?()
    }
    
    var shouldPlay = false
    
    var storyItem:StoryItem! {
        didSet {
            shouldPlay = false
            storyItem.delegate = self
            setItem()
            
            NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        
        self.moreButton.addTarget(self, action: #selector(showOptions), for: .touchUpInside)
        
        textView = UITextView(frame: CGRect(x: 0,y: frame.height - 44 ,width: frame.width - 26,height: 44))
        
        textView.font = UIFont(name: "AvenirNext-Medium", size: 16.0)
        textView.textColor = UIColor.white
        textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        textView.isHidden = false
        textView.keyboardAppearance = .dark
        textView.returnKeyType = .send
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = "Send a message"
        textView.delegate = self
        textView.fitHeightToContent()
        textView.text = ""
        
        commentPlaceHolderLabel = UILabel(frame: CGRect(x: 10,y: textView.frame.origin.y,width: textView.frame.width,height: textView.frame.height))
        
        commentPlaceHolderLabel.textColor = UIColor(white: 1.0, alpha: 0.5)
        commentPlaceHolderLabel.text = "Comment"
        commentPlaceHolderLabel.font = UIFont(name: "AvenirNext-Medium", size: 14.0)
        
        self.addSubview(commentPlaceHolderLabel)
        
        self.contentView.addSubview(textView)
        
        commentsView.frame = CGRect(x: 0,y: textView.frame.origin.y - commentsView.frame.height,width: commentsView.frame.width,height: commentsView.frame.height)
        
        self.contentView.addSubview(self.moreButton)
        
        //activityView = NVActivityIndicatorView(frame: CGRectMake(0,0,50,50), type: .BallScaleMultiple)
        //activityView.center = self.center
        //self.contentView.addSubview(activityView)
    }
    
    func setItem() {
        guard let item = storyItem else { return }
        self.authorOverlay.setPostMetadata(post: storyItem)
        if let image = storyItem.image {
            self.content.image = image
        } else {
            NotificationCenter.default.removeObserver(self)
            //activityView?.startAnimating()
            storyItem.download()
        }
        
        if item.contentType == .video {
            
            if let videoData = loadVideoFromCache(key: storyItem.key) {
                createVideoPlayer()
                
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsURL.appendingPathComponent("temp/\(storyItem.key).mp4")
                
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
                //activityView?.startAnimating()
                storyItem.download()
            }
        }
        
        commentsView.setTableComments(comments: item.comments, animated: false)
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/\(item.getKey())/comments")
        
        if let lastItem = item.comments.last {
            let lastKey = lastItem.getKey()
            let ts = lastItem.getDate().timeIntervalSince1970 * 1000
            
            print("LAST COMMENT: \(lastItem.getText())")
            commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childAdded, with: { snapshot in
                
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                if key != lastKey {
                    let author = dict["author"] as! String
                    let text = dict["text"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                    print("ADDING: \(text)")
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
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
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
            dismissKeyboard()
        }
    }
    
    func keyboardWillAppear(notification: NSNotification){
        
        keyboardUp = true
        
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.frame.height
            let textViewFrame = self.textView.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.textView.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            
            let commentLabelFrame = self.commentPlaceHolderLabel.frame
            let commentLabelY = height - keyboardFrame.height - commentLabelFrame.height
            self.commentPlaceHolderLabel.frame = CGRect(x: commentLabelFrame.origin.x,y: commentLabelY,width: commentLabelFrame.width,height: commentLabelFrame.height)
            
            let commentsViewStart = textViewY - self.commentsView.frame.height
            self.commentsView.frame = CGRect(x: 0,y: commentsViewStart,width: self.commentsView.frame.width,height: self.commentsView.frame.height)
            
            let moreButtonFrame = self.moreButton.frame
            let moreButtonY = height - keyboardFrame.height - moreButtonFrame.height
            self.moreButton.frame = CGRect(x: moreButtonFrame.origin.x,y: moreButtonY, width: moreButtonFrame.width, height: moreButtonFrame.height)
            
            self.authorOverlay.alpha = 0.0
            self.commentPlaceHolderLabel.alpha = 0.0
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.frame.height
            let textViewFrame = self.textView.frame
            let textViewStart = height - textViewFrame.height
            self.textView.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)
            
            let commentLabelFrame = self.commentPlaceHolderLabel.frame
            let commentLabelY = height - commentLabelFrame.height
            self.commentPlaceHolderLabel.frame = CGRect(x: commentLabelFrame.origin.x, y: commentLabelY, width: commentLabelFrame.width, height: commentLabelFrame.height)
            
            let commentsViewStart = textViewStart - self.commentsView.frame.height
            self.commentsView.frame = CGRect(x: 0,y: commentsViewStart,width: self.commentsView.frame.width,height: self.commentsView.frame.height)
            
            let moreButtonFrame = self.moreButton.frame
            self.moreButton.frame = CGRect(x: moreButtonFrame.origin.x,y: height - moreButtonFrame.height, width: moreButtonFrame.width, height: moreButtonFrame.height)

            self.authorOverlay.alpha = 1.0
            if !self.commentLabelShouldHide() {
                self.commentPlaceHolderLabel.alpha = 1.0
            }
            
        }, completion:  { result in
            
        })
        
    }
    
    func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    func sendComment(comment:String) {
        
        textView.text = ""
        updateTextAndCommentViews()
        if storyItem != nil {
            UploadService.addComment(postKey: storyItem!.getKey(), comment: comment)
        }
    }
    
    func commentLabelShouldHide() -> Bool {
        if textView.text.isEmpty {
            return false
        } else {
            return true
        }
    }
    var change:CGFloat = 0
    
    func updateTextAndCommentViews() {
        let oldHeight = textView.frame.size.height
        textView.fitHeightToContent()
        change = textView.frame.height - oldHeight
        
        
        textView.center = CGPoint(x: textView.center.x, y: textView.center.y - change)
        
        self.commentsView.frame = CGRect(x: 0,y: textView.frame.origin.y - self.commentsView.frame.height, width: self.commentsView.frame.width, height: self.commentsView.frame.height)
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
    
    lazy var moreButton: UIButton = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let button = UIButton(frame: CGRect(x:width - 40,y: height - 40,width: 40,height: 40))
        button.setImage(UIImage(named: "more2"), for: .normal)
        button.tintColor = UIColor.white
        button.alpha = 1.0
        return button
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
        var commentsView = CommentsView(frame: CGRect(x: 0, y: height / 2, width: width, height: height * 0.42 ))
        
        return commentsView
    }()

}

extension PostViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        updateTextAndCommentViews()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            if textView.text.characters.count > 0 {
                sendComment(comment: textView.text)
            } else {
                //dismissKeyboard()
            }
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}
