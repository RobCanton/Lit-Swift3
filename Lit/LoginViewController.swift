//
//  ViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-30.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import ActiveLabel
import AVFoundation

class LoginViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState


    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var legal: ActiveLabel!
    
    var dict:[String : AnyObject]!
    
    var activityIndicator:UIActivityIndicatorView!
    
    func newState(state:AppState) {

        if state.supportedVersion && state.userState.isAuth && state.userState.user != nil {
            
            self.performSegue(withIdentifier: "showLit", sender: self)
        }
    }
    
    let splashKey = "splashVideo.mp4"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Login view did load")

        
        self.deactivateLoginButton()
        
        loginButton.layer.borderWidth = 2.0
        loginButton.layer.borderColor = UIColor.white.cgColor
        
        let customType = ActiveType.custom(pattern: "\\sTerms of Use.") //Regex that looks for "with"
        legal.enabledTypes = [customType]
        legal.text = "By logging in you agree to the Terms of Use."
        
        legal.customColor[customType] = UIColor.white
        legal.customSelectedColor[customType] = UIColor.lightGray
        
        legal.handleCustomTap(for: customType) { element in
            print("Custom type tapped: \(element)")
            self.performSegue(withIdentifier: "showTerms", sender: self)
        }
        
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.center = CGPoint(x: view.center.x, y: loginButton.center.y)
        self.view.addSubview(activityIndicator)


    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTerms" {
            let nav = segue.destination as! UINavigationController
            let controller = nav.viewControllers[0] as! WebViewController
            controller.urlString = "https://getlit.site/terms.html"
            controller.title = "Terms of Use"
            controller.addDoneButton()
            
        }
    }
    
     func downloadSplashVideo(completion: @escaping (_ data:Data?)->()) {
        let videoRef = FIRStorage.storage().reference().child("brand/splashVideo.mp4")
        
        videoRef.data(withMaxSize: 50 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                print("Error - \(error!.localizedDescription)")
                completion(nil)
            } else {
                return completion(data!)
            }
        }
    }
    
    func writeVideoToFile(video:Data) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(splashKey))
        try! video.write(to: fileURL, options: [.atomic])
        return fileURL
    }
    
    func readVideoFromFile() -> URL? {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(splashKey))
        do {
            let _ = try Data(contentsOf: fileURL)
            
            return fileURL
        } catch let error as Error{
            print("ERROR: \(error.localizedDescription)")
            return nil
        }
    }
    
    func retrieveVideo(completion: @escaping (_ videoUrl:URL?, _ fromFile:Bool)->()) {

        if let data = readVideoFromFile() {
            completion(data, true)
        } else {
            downloadSplashVideo(completion: { data in
                if data != nil {
                    let url = self.writeVideoToFile(video: data!)
                    completion(url, false)
                }
                completion(nil, false)
            })
        }
    }
    


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        if !mainStore.state.supportedVersion {
            checkVersionSupport({ supported in
                if supported {
                    mainStore.dispatch(SupportedVersion())
                    self.setupLoginScreen()
                } else {
                    self.showUpdateAlert()
                }
            })
        } else {
           self.setupLoginScreen()
        }
        if playerLayer == nil {
            retrieveVideo(completion: { videoURL, fromFile in
                if videoURL != nil {
                    self.setupVideoBackground(videoURL: videoURL!)
                }
            })
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        activityIndicator.stopAnimating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        playerLayer?.player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        videoView?.removeFromSuperview()

    }
    
    func setupLoginScreen() {
        print("setupLoginScreen")
        if let user = FIRAuth.auth()?.currentUser {
            print("user already authenticated.")
            
            checkUserAgainstDatabase({ success in
                if success {
                    UserService.getUser(user.uid, completion: { user in
                        if user != nil {
                            UserService.login(user!)
                        } else {
                            UserService.logoutOfFirebase()
                            self.activateLoginButton()
                        }
                    })
                } else {
                    UserService.logoutOfFirebase()
                    self.activateLoginButton()
                }
            })
            
        } else {
            print("user not authenticated.")
            UserService.logoutOfFirebase()
            self.activateLoginButton()
        }
    }
    
    func activateLoginButton() {
        loginButton.isEnabled = true
        loginButton.isHidden = false
        legal.isEnabled = true
        legal.isHidden = false
    }
    
    func deactivateLoginButton() {
        loginButton.isEnabled = false
        loginButton.isHidden = true
        legal.isEnabled = false
        legal.isHidden = true
    }

    @IBAction func handleLoginButton(_ sender: Any) {
        loginButton.isEnabled = false
        
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email", "user_friends"], from: self) { (result, error) in
            if (error == nil){
                let fbloginresult : FBSDKLoginManagerLoginResult = result!
                if fbloginresult.grantedPermissions != nil {
                    if(fbloginresult.grantedPermissions.contains("public_profile"))
                    {
                        self.getFBUserData()
                        
                    } else {
                        self.removeFbData()
                        self.activateLoginButton()
                    }
                } else {
                    self.removeFbData()
                    self.activateLoginButton()
                }
            }
        }
    }
        

    
    func getFBUserData(){
        if FBSDKAccessToken.current() == nil {
            self.removeFbData()
            self.activateLoginButton()
        } else {
            
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! [String : AnyObject]
                    print(result!)
                    print(self.dict)
                    
                    let accessToken = FBSDKAccessToken.current().tokenString
                    let facebook_id = self.dict ["id"] as! String
                    
                    let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken!)
                    
                    self.signIntoFirebaseWithCredential(credential, facebook_id: facebook_id)
                    
                }
            })
        }
    }
    
    
    
    func signIntoFirebaseWithCredential(_ credential: FIRAuthCredential, facebook_id: String) {

        deactivateLoginButton()
        
        activityIndicator.startAnimating()
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (firUser, error) in
            
            if error == nil && firUser != nil {
                UserService.getUser(firUser!.uid, completion: { user in
                    print("fetched user: \(user)")
                    if user != nil {
                        UserService.login(user!)
                    } else {
                        self.performSegue(withIdentifier: "showCreateProfile", sender: self)
                    }
                })
            } else {
                print("error")
                UserService.logoutOfFirebase()
                self.removeFbData()
                return
            }
        })
    }
    
    func removeFbData() {
        //Remove FB Data
        let fbManager = FBSDKLoginManager()
        fbManager.logOut()
        FBSDKAccessToken.setCurrent(nil)
    }
    
    func checkUserAgainstDatabase(_ completion: @escaping (_ success:Bool) -> Void) {
        guard let currentUser = FIRAuth.auth()?.currentUser else { return }
        currentUser.getTokenForcingRefresh(true, completion: {(token, error) in
            completion(error == nil)
        })
        
    }
    
    func checkVersionSupport(_ completion: @escaping ((_ supported:Bool)->())) {
        activityIndicator.startAnimating()
        let infoDictionary = Bundle.main.infoDictionary!
        let appId = infoDictionary["CFBundleShortVersionString"] as! String
        
        let currentVersion = Int(appId.replacingOccurrences(of: ".", with: ""))!
        
        let versionRef = UserService.ref.child("config/client/minimum_supported_version")
        print("Observing current version")
        versionRef.observeSingleEvent(of: .value, with: { snapshot in
            let versionString = snapshot.value as! String
            let minimum_supported_version = Int(versionString.replacingOccurrences(of: ".", with: ""))!
            print("current_version: \(currentVersion) | minimum_supported_version: \(minimum_supported_version)")
            self.activityIndicator.stopAnimating()
            completion(currentVersion >= minimum_supported_version)
        })
    }
    
    func showUpdateAlert() {
        let alert = UIAlertController(title: "This version is no longer supported.", message: "Please update Lit on the Appstore.", preferredStyle: .alert)
        
        let update = UIAlertAction(title: "Got it", style: .default, handler: nil)
        alert.addAction(update)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool
        {
        get{
            return true
        }
    }
    

    var videoView:UIView?
    var playerLayer: AVPlayerLayer?
    func setupVideoBackground(videoURL:URL) {
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        videoView = UIView(frame: self.view.bounds)
        self.view.insertSubview(videoView!, at: 0)
        
        let videoPlayer = AVPlayer()
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        playerLayer!.frame = self.view.bounds
        videoView!.layer.addSublayer(playerLayer!)
        let item = AVPlayerItem(url: videoURL)
        videoPlayer.replaceCurrentItem(with: item)
        videoPlayer.play()
        loopVideo(videoPlayer: videoPlayer)
        
    }
    
    func loopVideo(videoPlayer: AVPlayer) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            videoPlayer.seek(to: kCMTimeZero)
            videoPlayer.play()
        }
    }
    

}

