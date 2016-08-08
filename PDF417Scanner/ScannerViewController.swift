//
//  ViewController.swift
//  PDF417Scanner
//
//  Created by Sylvain Bouchard on 2016-07-27.
//  Copyright © 2016 Solutions Waizu inc. All rights reserved.
//

import UIKit
import AVFoundation


class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var rightHandleImageView: UIImageView!
    @IBOutlet weak var leftHandleImageView: UIImageView!
    
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var stillImageOutput = AVCaptureStillImageOutput()
    var barcodesHandler: ((Array<AVMetadataMachineReadableCodeObject>) -> Void)?
    var driverLicData: [String: String] = Dictionary()
    var barDetectedFrameView:UIView?
    
    let codeLookup = ["DCS":"Lastname",
                      "DAC":"Firstname",
                      "DAG":"Address",
                      "DAI":"City",
                      "DAJ":"State",
                      "DAK":"Postal code",
                      "DCG":"Country",
                      "DBB":"Date of birth"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            
            let input: AnyObject! = try AVCaptureDeviceInput(device: captureDevice) as AVCaptureDeviceInput
            let captureMetadataOutput = AVCaptureMetadataOutput()
            
            self.captureSession = AVCaptureSession()
            if let session = self.captureSession{
                session.addInput(input as! AVCaptureInput)
                session.addOutput(captureMetadataOutput)
            }
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypePDF417Code]
            
            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            if let videoPreview = self.videoPreviewLayer{
                videoPreview.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreview.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                videoPreview.frame = self.view.layer.frame
                self.view.layer.addSublayer(videoPreview)
            }
            
            view.bringSubviewToFront(rightHandleImageView)
            view.bringSubviewToFront(leftHandleImageView)
            
            // Initialize QR Code Frame to highlight the QR code
            barDetectedFrameView = UIView()
            
            if let barDetectedFrameView = barDetectedFrameView {
                barDetectedFrameView.layer.borderColor = UIColor.greenColor().CGColor
                barDetectedFrameView.layer.borderWidth = 2
                view.addSubview(barDetectedFrameView)
                view.bringSubviewToFront(barDetectedFrameView)
            }
            
        }catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let session = self.captureSession{
            barDetectedFrameView?.frame = CGRectZero
            turnTorchOn()
            session.startRunning()
            
        }
        
        self.rightHandleImageView.hidden = false;
        self.leftHandleImageView.hidden = false;
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let session = self.captureSession{
            session.stopRunning()
        }
        
    }
    
    func turnTorchOn() {
        do {
            try self.captureDevice.lockForConfiguration()
            try self.captureDevice.setTorchModeOnWithLevel(1.0)
            self.captureDevice.unlockForConfiguration()
        }catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            barDetectedFrameView?.frame = CGRectZero
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObjectTypePDF417Code {
            
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
            barDetectedFrameView?.frame = barCodeObject!.bounds
            
            if let session = self.captureSession{
                session.stopRunning()
            }
            
            self.parseMetadata(metadataObj)
            self.animateCapture()
        }
    }
    
    
    func parseMetadata( metadataObj: AVMetadataMachineReadableCodeObject){
        
        self.driverLicData = Dictionary()
        
        if metadataObj.type == AVMetadataObjectTypePDF417Code {
            
            print(metadataObj)
            
            let contents = NSString(string: metadataObj.stringValue);
            
            contents.enumerateLinesUsingBlock({ (line, stop) -> () in
                
                if line.rangeOfString("ANSI") == nil{
                    if line.characters.count > 3 {
                        let endIndex = line.startIndex.advancedBy(3)
                        let cle = line.substringWithRange(line.startIndex..<endIndex)
                        if let code = self.codeLookup[cle]{
                            let value = line.substringWithRange(line.startIndex.advancedBy(3)..<line.endIndex)
                            self.driverLicData[code] = value
                        }
                    }
                }
            })
        }
    }
    
    func animateCapture(){
        
        let originalCrochetGaucheFrame = self.leftHandleImageView.frame
        let originalCrochetDroitFrame = self.rightHandleImageView.frame
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
            
            var newCrochetGaucheFrame = originalCrochetGaucheFrame
            newCrochetGaucheFrame.origin.x = originalCrochetGaucheFrame.origin.x - 15
            newCrochetGaucheFrame.origin.y = originalCrochetGaucheFrame.origin.y - 15
            newCrochetGaucheFrame.size.width = originalCrochetGaucheFrame.width + 30
            newCrochetGaucheFrame.size.height = originalCrochetGaucheFrame.height + 30
            
            var newCrochetDroitFrame = originalCrochetDroitFrame
            newCrochetDroitFrame.origin.x = originalCrochetDroitFrame.origin.x + 15
            newCrochetDroitFrame.origin.y = originalCrochetDroitFrame.origin.y - 15
            newCrochetDroitFrame.size.width = originalCrochetDroitFrame.width + 30
            newCrochetDroitFrame.size.height = originalCrochetDroitFrame.height + 30
            
            self.leftHandleImageView.frame = newCrochetGaucheFrame
            self.rightHandleImageView.frame = newCrochetDroitFrame
            
            }, completion: { (finished: Bool) -> Void in
                
                UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                    
                    self.leftHandleImageView.frame = originalCrochetGaucheFrame
                    self.rightHandleImageView.frame = originalCrochetDroitFrame
                    
                    }, completion: { (finished: Bool) -> Void in
                        
                        let succesView = SuccessView.init(frame: self.view.bounds)
                        self.view.addSubview(succesView)
                        succesView.animateCircle(1.0)
                        succesView.animateCheckMark(1.0)
                        
                        UIView.animateWithDuration(0.7, delay: 0.5, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                            self.leftHandleImageView.hidden = true;
                            self.rightHandleImageView.hidden = true;
                            
                            
                            }, completion: { (finished: Bool) -> Void in
                                // Data
                                
                                let triggerTime = (Int64(NSEC_PER_SEC) * 2)
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, triggerTime), dispatch_get_main_queue(), { () -> Void in
                                    // Afficher l'ecran des resultats
                                    self.performSegueWithIdentifier("showResult", sender: nil)
                                    succesView.removeFromSuperview()
                                })
                        })
                })
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "showResult" {
            let resultViewcontroller = segue.destinationViewController as! ResultTableViewController
            resultViewcontroller.driverLicData = self.driverLicData
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        var orientation = AVCaptureVideoOrientation.Portrait
        
        print(UIDevice.currentDevice().orientation )
        
        switch UIDevice.currentDevice().orientation{
        case .LandscapeLeft:
            orientation = AVCaptureVideoOrientation.LandscapeRight
        case .LandscapeRight:
            orientation = AVCaptureVideoOrientation.LandscapeLeft
        default:
            orientation = AVCaptureVideoOrientation.Portrait
        }
        
        if let videoPreview = self.videoPreviewLayer{
            
            var frame = videoPreview.frame
            frame.size = size
            videoPreview.frame=frame;
            
            videoPreview.connection.videoOrientation = orientation
        }
    }
}

