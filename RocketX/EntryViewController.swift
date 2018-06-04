//
//  EntryViewController.swift
//  RocketX
//
//  Created by chunning on 2018/6/1.
//  Copyright © 2018年 NTUMPP. All rights reserved.
//

import UIKit

class EntryViewController: UIViewController {

    @IBOutlet weak var gameTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        gameTitle.alpha = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Change the font size of the backBarButton for child views
        let backBarButton = UIBarButtonItem.init()
        backBarButton.title = " Menu"
        let font:UIFont = UIFont.systemFont(ofSize: 26.0);
        backBarButton.setTitleTextAttributes([NSAttributedStringKey.font: font, NSAttributedStringKey.baselineOffset: -2], for: UIControlState.normal);
        self.navigationItem.backBarButtonItem = backBarButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        func fadeViewIn(view : UIView) {
            // Fade in the title label
            let animationDuration = 8.0
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                view.alpha = 1
            })
        }
        
        fadeViewIn(view: gameTitle)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        // prepare scores to ScoreTableView
        if segue.identifier == "scoreTableSegue" {
            let destinationViewController = segue.destination as! ScoreTableViewController
            let scoreArray = UserDefaults.standard.object(forKey: "scoreArray") as? [Int] ?? [Int]()
            destinationViewController.scores = scoreArray
            destinationViewController.tableView.reloadData()
        }
    }
}
