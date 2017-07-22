//
//  SignInViewController.swift
//  events
//
//  Created by Skyler Ruesga on 7/12/17.
//  Copyright © 2017 fbu-rsx. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.textColor = UIColor(hexString: "#4CB6BE")
        self.logoView.backgroundColor = UIColor(patternImage: UIImage(named: "mapLogo")!)
    }
    
    // Bounce up-and-down animation for photo
    func mapAnimation () {
        UIView.animate(withDuration: 1, delay: 0.25, options: [.autoreverse, .repeat], animations: {
            self.logoView.frame.origin.y -= 10
        })
        self.logoView.frame.origin.y += 10
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        mapAnimation()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
