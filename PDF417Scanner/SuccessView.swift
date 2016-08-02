//
//  SuccessView.swift
//  PDF417Scanner
//
//  Created by Sylvain Bouchard on 2016-07-28.
//  Copyright © 2016 Sylvain Bouchard. All rights reserved.
//

import UIKit
import GLKit

class SuccessView: UIView{
    
    let circleLayer: CAShapeLayer = CAShapeLayer()
    var imageView: UIImageView?
    let color = UIColor(red:0.016, green:0.639, blue:0.392, alpha:1.00)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: 75, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor.whiteColor().CGColor
        circleLayer.strokeColor = color.CGColor
        circleLayer.lineWidth = 5.0;
        circleLayer.strokeEnd = 0.0
        
        layer.addSublayer(circleLayer)
    }
    
    func animateCircle(duration: NSTimeInterval) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        animation.duration = duration
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        circleLayer.strokeEnd = 1.0
        circleLayer.addAnimation(animation, forKey: "strokeEnd")
    }

    func animateCheckMark(duration: NSTimeInterval) {
        
        let centerPoint = CGPoint(x: (frame.size.width / 2.0)-35, y: (frame.size.height / 2.0))
        let path: UIBezierPath = UIBezierPath()
        path.moveToPoint(CGPointMake(centerPoint.x, centerPoint.y))
        let secondPoint = CGPoint(x: centerPoint.x+20, y: centerPoint.y+20)
        path.addLineToPoint(secondPoint)
        let lastPoint = CGPoint(x: secondPoint.x+50, y: secondPoint.y-50)
        path.addLineToPoint(lastPoint)
        
        let pathLayer: CAShapeLayer = CAShapeLayer()
        pathLayer.frame = self.bounds
        pathLayer.path = path.CGPath
        pathLayer.strokeColor = color.CGColor
        pathLayer.fillColor = nil
        pathLayer.lineWidth = 5.0
        pathLayer.lineJoin = kCALineJoinBevel

        self.layer.addSublayer(pathLayer)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = 0.0
        animation.toValue = 1.0

        pathLayer.addAnimation(animation, forKey: "strokeEnd")
    }
    
    
}