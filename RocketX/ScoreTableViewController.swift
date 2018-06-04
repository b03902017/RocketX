//
//  ScoreTableViewController.swift
//  RocketX
//
//  Created by chunning on 2018/6/2.
//  Copyright © 2018年 NTUMPP. All rights reserved.
//

import UIKit

class ScoreTableViewController: UITableViewController {
    
    var scores = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.sublayerTransform = CATransform3DMakeTranslation(10, 5, 0);
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return scores.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath)
        
        // Configure the cell...
        if indexPath.row < scores.count {
            cell.textLabel!.text = String(format: "%d", scores[indexPath.row])
        } else {
            cell.textLabel!.text = ""
        }
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
