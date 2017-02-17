//
//  CameraViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreLocation

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var cameraOutputView: UIView!
    @IBOutlet weak var videoCaptureView: UIView!
    @IBOutlet weak var imageCaptureView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    var videoFileOutput: AVCaptureMovieFileOutput?
    var videoUrl: URL?
    var cameraDevice: AVCaptureDevice?
    
    var pinchGesture:UIPinchGestureRecognizer!
    var tapGesture:UITapGestureRecognizer!

    @IBOutlet weak var dismissButton: UIButton!
    
    var flashMode:FlashMode = .Off
    var cameraMode:CameraMode = .Back
    
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    var recordBtn:CameraButton!
    
    var didTakePhoto = false
    
    var uploadCoordinate:CLLocation?
    
    var flashButton:UIButton!
    var switchButton:UIButton!
    
    var flashView:UIView!
    
    var textView:UITextView!
    
    lazy var cancelButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.center = CGPoint(x: button.frame.width * 0.60, y: definiteBounds.height - button.frame.height * 0.60)
        button.tintColor = UIColor.white
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
        
    }()
    
    lazy var sendButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.setImage(UIImage(named: "right_arrow"), for: .normal)
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.75, y: definiteBounds.height - button.frame.height * 0.75)
        button.tintColor = UIColor.black
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    lazy var captionButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.5, y: button.frame.height * 0.5)
        button.setImage(UIImage(named: "type"), for: .normal)
        button.tintColor = UIColor.white
        button.clipsToBounds = true
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let definiteBounds = UIScreen.main.bounds
        
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0

        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        var cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = definiteBounds.height - 140
        cameraBtnFrame.origin.x = self.view.bounds.width/2 - cameraBtnFrame.size.width/2
        recordBtn.frame = cameraBtnFrame
        
        recordBtn.isHidden = true
        recordBtn.tappedHandler = didPressTakePhoto
        recordBtn.pressedHandler = pressed
        recordBtn.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        flashButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        flashButton.setImage(UIImage(named: "flashoff"), for: .normal)
        flashButton.center = CGPoint(x: cameraBtnFrame.origin.x / 2, y: cameraBtnFrame.origin.y + cameraBtnFrame.height / 2)
        flashButton.alpha = 0.75
        flashButton.tintColor = UIColor.white
        flashButton.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        switchButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        switchButton.setImage(UIImage(named: "switchcamera"), for: .normal)
        switchButton.center = CGPoint(x: view.frame.width - cameraBtnFrame.origin.x / 2, y: cameraBtnFrame.origin.y + cameraBtnFrame.height / 2)
        switchButton.alpha = 0.75
        switchButton.tintColor = UIColor.white
        switchButton.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        dismissButton.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        self.view.insertSubview(flashView, aboveSubview: imageCaptureView)
        self.view.addSubview(recordBtn)
        self.view.addSubview(flashButton)
        self.view.addSubview(switchButton)
        
        flashButton.addTarget(self, action: #selector(switchFlashMode), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture))
        self.view.addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
        recordBtn.press.delegate = self
        recordBtn.tap.delegate = self
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture))
        
        
        textView = UITextView(frame: CGRect(x: 0,y: view.frame.height - 84,width: view.frame.width,height: 44))
        
        textView.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        textView.textColor = UIColor.white
        textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        textView.isHidden = false
        textView.keyboardAppearance = .dark
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = "Send a message"
        textView.fitHeightToContent()
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.isUserInteractionEnabled = false
        
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        let dark = UIColor(white: 0.0, alpha: 0.5)
        gradient.colors = [UIColor.clear.cgColor , dark.cgColor]
        gradientView.layer.insertSublayer(gradient, at: 0)
        gradientView.alpha = 0.0

        cameraState = .Initiating

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: 0.6, animations: {
            self.dismissButton.alpha = 0.75
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        destroyVideoPreview()

        UIView.animate(withDuration: 0.3, animations: {
            self.dismissButton.alpha = 0.0
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        destroyCameraSession()
    }
    
    var cameraState:CameraState = .Off
        {
        didSet {
            switch cameraState {
            case .Off:
                break
            case .Initiating:
                reloadCamera()
                break
            case .Running:
                imageCaptureView.image  = nil
                imageCaptureView.isHidden = true
                
                playerLayer?.player?.pause()
                playerLayer?.removeFromSuperlayer()
                playerLayer?.player = nil
                playerLayer = nil
                
                statusBarShouldHide = false
                self.setNeedsStatusBarAppearanceUpdate()
                showCameraOptions()
                hideEditOptions()
                break
            case .DidPressTakePhoto:
                recordBtn.isHidden        = true
                hideCameraOptions()
                break
            case .PhotoTaken:
                resetProgress()
                imageCaptureView.isHidden = false
                videoCaptureView.isHidden = true
                showEditOptions()
                uploadCoordinate        = GPSService.sharedInstance.lastLocation
                statusBarShouldHide = true
                self.setNeedsStatusBarAppearanceUpdate()
                break
            case .Recording:
                hideCameraOptions()
                statusBarShouldHide = true
                self.setNeedsStatusBarAppearanceUpdate()
                break
            case .VideoTaken:
                resetProgress()
                imageCaptureView.isHidden  = true
                videoCaptureView.isHidden  = false
                recordBtn.isHidden         = true
                hideCameraOptions()
                showEditOptions()
                uploadCoordinate        = GPSService.sharedInstance.lastLocation
                break
            }
        }
    }
    
    func reloadCamera() {
        destroyCameraSession()
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset1280x720
        
        if cameraMode == .Front
        {
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            
            for device in videoDevices!{
                if let device = device as? AVCaptureDevice
                {
                    if device.position == AVCaptureDevicePosition.front {
                        cameraDevice = device
                        break
                    }
                }
            }
        }
        else
        {
            cameraDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        let captureTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AutoFocusGesture))
        captureTapGesture.numberOfTapsRequired = 1
        captureTapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(captureTapGesture)
        
        do {
            
            let input = try AVCaptureDeviceInput(device: cameraDevice)
            
            videoFileOutput = AVCaptureMovieFileOutput()
            self.captureSession!.addOutput(videoFileOutput)
            let audioDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            do {
                let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                self.captureSession!.addInput(audioInput)
                
            } catch {
                print("Unable to add audio device to the recording.")
            }
            
            if captureSession?.canAddInput(input) != nil {
                captureSession?.addInput(input)
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                if (captureSession?.canAddOutput(stillImageOutput) != nil) {
                    captureSession?.addOutput(stillImageOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.session.usesApplicationAudioSession = false
                    
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                    previewLayer?.frame = cameraOutputView.bounds
                    cameraOutputView.layer.addSublayer(previewLayer!)
                    captureSession?.startRunning()
                    
                    cameraState = .Running
                }
            }
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    func destroyCameraSession() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        playerLayer?.player = nil
        playerLayer = nil
    }
    
    func destroyVideoPreview() {
        NotificationCenter.default.removeObserver(self)
        playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        
        playerLayer?.removeFromSuperlayer()
        videoUrl = nil
    }
    
    func showCameraOptions() {
        dismissButton.isHidden    = false
        flashButton.isEnabled     = true
        flashButton.isHidden      = false
        switchButton.isEnabled    = true
        switchButton.isHidden     = false
    }
    
    func hideCameraOptions() {
        dismissButton.isHidden    = true
        flashButton.isEnabled     = false
        flashButton.isHidden      = true
        switchButton.isEnabled    = false
        switchButton.isHidden     = true
    }
    
    func showEditOptions() {
        self.view.addSubview(cancelButton)
        self.view.addSubview(sendButton)
        self.view.addSubview(captionButton)
        self.view.addSubview(textView)

        
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        captionButton.addTarget(self, action: #selector(captionButtonTapped), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        view.addGestureRecognizer(tapGesture)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.gradientView.alpha = 1.0
        })
    }
    
    func hideEditOptions() {
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        captionButton.removeFromSuperview()
        
        gradientView.isHidden = true
        textView.text = ""
        updateTextAndCommentViews()
        
        cancelButton.removeTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        textView.removeFromSuperview()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        view.removeGestureRecognizer(tapGesture)
        
        self.gradientView.alpha = 0.0
    }
    
    func sendButtonTapped(sender: UIButton) {
        let upload = Upload()
        if cameraState == .PhotoTaken {
            upload.image = imageCaptureView.image!
        } else if cameraState == .VideoTaken {
            upload.videoURL = videoUrl
        }
        
        upload.caption = textView.text
        
        upload.coordinates = uploadCoordinate
        
        let nav = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "SendNavigationController") as! UINavigationController
        let controller = nav.viewControllers[0] as! SendViewController
        controller.upload = upload
        
        self.present(nav, animated: false, completion: nil)
    }
    
    func cancelButtonTapped(sender: UIButton) {
        
        destroyVideoPreview()
        
        recordBtn.isHidden = false
        
        if captureSession != nil && captureSession!.isRunning {
            cameraState = .Running
        } else {
            cameraState = .Initiating
        }
    }
    
    func didPressTakePhoto()
    {
        if cameraState != .Running { return }
        cameraState = .DidPressTakePhoto
        
        flashView.alpha = 0.0
        UIView.animate(withDuration: 0.025, animations: {
            self.flashView.alpha = 0.75
        }, completion: { result in
            UIView.animate(withDuration: 0.25, animations: {
                self.flashView.alpha = 0.0
            }, completion: { result in })
        })
        
        AudioServicesPlayAlertSound(1108)
        if let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler:{
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    var image:UIImage!
                    image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                    if self.cameraMode == .Front {
                        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                    } else {
                        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    }
                    self.cameraState = .PhotoTaken
                    self.imageCaptureView.image = image
                }
            })
        }
    }
    
    
    let maxDuration = CGFloat(10)
    
    func updateProgress() {
        if progress > 0.99 {
            progressTimer.invalidate()
            videoFileOutput?.stopRecording()
        } else {
            progress = progress + (CGFloat(0.025) / maxDuration)
            recordBtn.updateProgress(progress: progress)
        }
        
    }
    
    func resetProgress() {
        progress = 0
        recordBtn.resetProgress()
    }
    
    
    func pressed(state: UIGestureRecognizerState)
    {
        switch state {
        case .began:
            if cameraState == .Running {
                recordVideo()
            }
            
            break
        case .ended:
            if cameraState == .Recording {
                videoFileOutput?.stopRecording()
            }
            
            break
        default:
            break
        }
    }
    
    func recordVideo() {
        cameraState = .Recording
        progressTimer = Timer.scheduledTimer(timeInterval: 0.025, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
        let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsURL.appendingPathComponent("temp.mp4")//documentsURL.URLByAppendingPathComponent("temp.mp4")
        
        // Do recording and save the output to the `filePath`
        videoFileOutput!.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        progressTimer.invalidate()
        videoUrl = outputFileURL
        
        let item = AVPlayerItem(url: outputFileURL as URL)
        videoPlayer.replaceCurrentItem(with: item)
        playerLayer = AVPlayerLayer(player: videoPlayer)
        
        playerLayer!.frame = self.view.bounds
        self.videoCaptureView.layer.addSublayer(playerLayer!)
        
        playerLayer!.player?.play()
        playerLayer!.player?.actionAtItemEnd = .none
        cameraState = .VideoTaken
        loopVideo()
        return
    }

    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        cameraState = .Recording
        return
    }
    
    func loopVideo() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            self.playerLayer?.player?.seek(to: kCMTimeZero)
            self.playerLayer?.player?.play()
        }
    }

    func endLoopVideo() {
        NotificationCenter.default.removeObserver(NSNotification.Name.AVPlayerItemDidPlayToEndTime, name: nil, object: nil)
    }
    
    func switchFlashMode(sender:UIButton!) {
        if let avDevice = cameraDevice
        {
            // check if the device has torch
            if avDevice.hasTorch {
                // lock your device for configuration
                do {
                    _ = try avDevice.lockForConfiguration()
                } catch {
                }
                switch flashMode {
                case .On:
                    
                    avDevice.flashMode = .auto
                    flashMode = .Auto
                    flashButton.setImage(UIImage(named: "flashauto"), for: .normal)
                    break
                case .Auto:
                    avDevice.flashMode = .off
                    flashMode = .Off
                    flashButton.setImage(UIImage(named: "flashoff"), for: .normal)
                    break
                case .Off:
                    avDevice.flashMode = .on
                    flashMode = .On
                    flashButton.setImage(UIImage(named: "flashon"), for: .normal)
                    break
                }
                // unlock your device
                avDevice.unlockForConfiguration()
            }
        }
        
    }
    
    func switchCamera(sender:UIButton!) {
        switch cameraMode {
        case .Back:
            cameraMode = .Front
            break
        case .Front:
            cameraMode = .Back
            break
        }
        reloadCamera()
    }
    
    var pivotPinchScale:CGFloat!
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === pinchGesture {
            let loc = touch.location(in: view)
            if loc.y > recordBtn.frame.origin.y - 8 {
                return false
            }
        }
        return true
    }
    
    func handlePinchGesture(gesture:UIPinchGestureRecognizer) {

        guard let device = cameraDevice else { return }
        do {
            try device.lockForConfiguration()
            switch gesture.state {
            case .began:
                self.pivotPinchScale = device.videoZoomFactor
            case .changed:
                var factor = self.pivotPinchScale * gesture.scale
                factor = max(1, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = factor
            default:
                break
            }
            device.unlockForConfiguration()
        } catch {
            // handle exception
        }
    }
    
    var animateActivity: Bool!
    func AutoFocusGesture(RecognizeGesture: UITapGestureRecognizer){
        let touchPoint: CGPoint = RecognizeGesture.location(in: self.cameraOutputView)
        //GET PREVIEW LAYER POINT
        let convertedPoint = self.previewLayer!.captureDevicePointOfInterest(for: touchPoint)
        
        //Assign Auto Focus and Auto Exposour
        if let device = cameraDevice {
            do {
                try! device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported{
                    //Add Focus on Point
                    device.focusPointOfInterest = convertedPoint
                    device.focusMode = AVCaptureFocusMode.autoFocus
                }
                
                if device.isExposurePointOfInterestSupported{
                    //Add Exposure on Point
                    device.exposurePointOfInterest = convertedPoint
                    device.exposureMode = AVCaptureExposureMode.autoExpose
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    var statusBarShouldHide = false
    override public var prefersStatusBarHidden: Bool {
        get {
            return statusBarShouldHide
        }
    }
    
    var keyboardUp = false
    
    func keyboardWillAppear(notification: NSNotification){
        
        keyboardUp = true
        
        textView.isUserInteractionEnabled = true
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        captionButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.textView.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.textView.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            self.captionButton.alpha = 0.0
            
            self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
        textView.isUserInteractionEnabled = false
        captionButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.textView.frame
            let textViewStart = height - textViewFrame.height - 84
            self.textView.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)
            self.captionButton.alpha = 1.0
            
            if self.textView.text != "" {
               self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
            } else {
                self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
            }
        })
    }
    
    func handleTapGesture(tap:UITapGestureRecognizer) {
        if keyboardUp {
            textView.resignFirstResponder()
        } else {
            if tap.location(ofTouch: 0, in: view).y < view.frame.height * 0.75 {
              textView.becomeFirstResponder()
            }
        }
    }
    
    func captionButtonTapped(button:UIButton) {
        textView.becomeFirstResponder()
    }
    
    func updateTextAndCommentViews() {
        let oldHeight = textView.frame.size.height
        textView.fitHeightToContent()
        let change = textView.frame.height - oldHeight

        textView.center = CGPoint(x: textView.center.x, y: textView.center.y - change)
    }
}

extension CameraViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        updateTextAndCommentViews()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            dismissKeyboard()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}


enum CameraState {
    case Off, Initiating, Running, DidPressTakePhoto, PhotoTaken, VideoTaken, Recording
}

enum CameraMode {
    case Front, Back
}

enum FlashMode {
    case Off, On, Auto
}

