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
        
        self.view.layer.sublayerTransform = CATransform3DMakeTranslation(30, 5, 0);
        self.tableView.rowHeight = 44.0
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
        return scores.count + 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath)
        cell.textLabel!.font = UIFont(name: "Menlo", size: cell.textLabel!.font.pointSize)
        
        if indexPath.row == 0 {
            cell.textLabel!.text = "Rank\t\t\t\t\t\tScore"
        } else if indexPath.row <= scores.count {
            cell.textLabel!.text = String(format: " %02d \t\t\t\t\t\t %d", indexPath.row, scores[indexPath.row-1])
        } else {
            cell.textLabel!.text = ""
        }
        return cell
    }
}
