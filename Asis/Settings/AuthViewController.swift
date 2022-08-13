//
//  AuthViewController.swift
//  Asis
//
//  Created by Can Duru on 11.08.2022.
//

//MARK: Import
import UIKit

class AuthViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Create Navigation Controllers
        self.viewControllers = [LoginViewController()]
        
    }
}
