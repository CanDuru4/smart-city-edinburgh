//
//  FAQViewController.swift
//  Asis
//
//  Created by Can Duru on 11.08.2022.
//

//MARK: Import
import UIKit
import WebKit

class FAQViewController: UIViewController, WKNavigationDelegate {

    //MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Set Up
        let webView = WKWebView()
        webView.navigationDelegate = self
        view = webView

        //MARK: Web URL
        let url = URL(string: "https://www.canduru.net/contact")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
    }
}
