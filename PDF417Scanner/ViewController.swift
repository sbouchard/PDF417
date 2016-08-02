//
//  ViewController.swift
//  PDF417Scanner
//
//  Created by Sylvain Bouchard on 2016-07-27.
//  Copyright © 2016 Sylvain Bouchard. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var barcodesHandler: ((Array<AVMetadataMachineReadableCodeObject>) -> Void)?
    var permisData: [String: String] = Dictionary()
    var imageView: UIImageView = UIImageView()
    
    let codeLookup = ["DCS":"Nom", "DAC":"Prenom", "DAG": "Adresse", "DAI": "Ville", "DAJ":"Province",
                      "DAK":"Code Postal", "DCG":"Pays", "DBB":"Date de naissance"]
    
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
                videoPreview.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
                videoPreview.frame = self.view.layer.frame
                self.view.layer.addSublayer(videoPreview)
            }
            
            self.imageView = UIImageView(image: UIImage(named:"crochet"))
            view.addSubview(self.imageView)
            self.imageView.center = view.center
            view.bringSubviewToFront(self.imageView)
        
        }catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let session = self.captureSession{
            turnTorchOn()
            session.startRunning()
            
        }
        
        self.imageView.hidden = false;
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
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        parseMetadata(metadataObj)

    }


    func parseMetadata( metadataObj: AVMetadataMachineReadableCodeObject){
        
        self.permisData = Dictionary()
        
        if metadataObj.type == AVMetadataObjectTypePDF417Code {
            
            print(metadataObj.stringValue + "\n")
            
            let originalFrame = self.imageView.frame
        
            if let session = self.captureSession{
                session.stopRunning()
            }
            
            UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                
                var newFrame = self.imageView.frame
                newFrame.origin.x = newFrame.origin.x - 15
                newFrame.origin.y = newFrame.origin.y - 15
                newFrame.size.width = newFrame.width + 30
                newFrame.size.height = newFrame.height + 30
                
                self.imageView.frame = newFrame
                
                }, completion: { (finished: Bool) -> Void in
                    
                    UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                        
                        self.imageView.frame = originalFrame
                        
                    }, completion: { (finished: Bool) -> Void in
                        if metadataObj.stringValue != nil {
                        
                            let succesView = SuccessView.init(frame: self.view.bounds)
                            self.view.addSubview(succesView)
                            succesView.animateCircle(1.0)
                            succesView.animateCheckMark(1.0)
                            
                            UIView.animateWithDuration(0.7, delay: 0.5, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                                self.imageView.hidden = true;

                                
                            }, completion: { (finished: Bool) -> Void in
                                
                                let contents = NSString(string: metadataObj.stringValue);
                                // Print all lines.
                                contents.enumerateLinesUsingBlock({ (line, stop) -> () in

                                    if line.rangeOfString("ANSI") == nil{
                                        if line.characters.count > 3 {
                                            let endIndex = line.startIndex.advancedBy(3)
                                            let cle = line.substringWithRange(line.startIndex..<endIndex)
                                            if let code = self.codeLookup[cle]{
                                                let value = line.substringWithRange(line.startIndex.advancedBy(3)..<line.endIndex)
                                                self.permisData[code] = value
                                            }
                                        }
                                    }
                                })

                                print(self.permisData)

                                let triggerTime = (Int64(NSEC_PER_SEC) * 2)
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, triggerTime), dispatch_get_main_queue(), { () -> Void in
                                    // Afficher l'ecran des resultats
                                    self.performSegueWithIdentifier("showResult", sender: nil)
                                    succesView.removeFromSuperview()
                                })
                            })

                        

                        
                        }
                    })
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "showResult" {
            let resultViewcontroller = segue.destinationViewController as! ResultTableViewController
            resultViewcontroller.permisDataDict = self.permisData
        }
    }
    

}

