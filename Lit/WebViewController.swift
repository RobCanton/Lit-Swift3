//
//  WebViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    var webView:WKWebView!
    
    var urlString:String!
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.white]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.black
        webView.allowsBackForwardNavigationGestures = true
        let url = URL(string: urlString)!
        webView.load(URLRequest(url: url))
        webView.frame = view.frame
        view.addSubview(webView)
    }
    
}
