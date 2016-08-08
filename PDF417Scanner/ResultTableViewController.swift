//
//  ResultTableViewController.swift
//  PDF417Scanner
//
//  Created by Sylvain Bouchard on 2016-07-27.
//  Copyright © 2016 Solutions Waizu inc. All rights reserved.
//

import UIKit

class ResultTableViewController: UITableViewController {
    
    var driverLicData :[String: String] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.driverLicData.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dataCell", forIndexPath: indexPath)
        
        let desc = Array(self.driverLicData.keys)[indexPath.row]
        
        if let value = self.driverLicData[desc]{
            cell.textLabel?.text = desc + " = " + value
        }
        
        return cell
    }
    
}