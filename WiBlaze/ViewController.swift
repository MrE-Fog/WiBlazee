//
//  ViewController.swift
//  WiBlaze
//
//  Created by Justin Bush on 2017-01-15.
//  Copyright © 2017 Justin Bush. All rights reserved.
//

import UIKit
import WebKit
import ActivityNavigationBar
import SideMenu

protocol MainViewControllerDelegate {
    func refresh()
}

class ViewController: UIViewController, UINavigationControllerDelegate, WKNavigationDelegate, MainViewControllerDelegate {

    var webView: WKWebView!
    
    @IBOutlet var addressBar: UITextField!
    @IBOutlet var backButton: UIBarButtonItem!
    
    // App Screen Bounds
    var appScreenRect: CGRect {
        let appWindowRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
        return appWindowRect
    }
    
    override func loadView() {
        // Setup WebKit
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webConfiguration.preferences.javaScriptEnabled = true
        self.view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Placeholder Style
        addressBar.attributedPlaceholder = NSAttributedString(string:" Search or type URL", attributes: [NSForegroundColorAttributeName: UIColor.gray])
        
        // Set WebKit Load Configurations
        let webURL = URL(string: "https://google.ca")
        let webRequest = URLRequest(url: webURL!)
        webView.load(webRequest)
        webView.allowsBackForwardNavigationGestures = true
        
        // Setup Menu Controller
        let menuRightNavigationController = UISideMenuNavigationController()
        SideMenuManager.menuRightNavigationController = menuRightNavigationController
        SideMenuManager.menuBlurEffectStyle = .dark
        SideMenuManager.menuPresentMode = .menuSlideIn
        
        // Set Menu Width (eg. * 0.65 = 65%)
        SideMenuManager.menuWidth = max(round(min((appScreenRect.width), (appScreenRect.height)) * 0.65), 240)
    }
    
    // Toggle Back Button
    func checkBack() {
        if webView.canGoBack {
            backButton.isEnabled = true
        } else {
            backButton.isEnabled = false
        }
    }
    
    // WebView Called for Navigation
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityNavigationBar?.startActivity(andWaitAt: 0.8)
    }
    
    // WebView Started Downloading Content
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        checkBack()
        
        if webView.estimatedProgress < 0.8 {
            activityNavigationBar?.finishActivity(withDuration: 0.8)
        } else {
            activityNavigationBar?.finishActivity(withDuration: webView.estimatedProgress)
        }
    }
    
    // WebView Finished Loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityNavigationBar?.reset()
    }
    
    // Setup Activity Navigation
    var activityNavigationBar: ActivityNavigationBar? {
        return navigationController?.navigationBar as? ActivityNavigationBar
    }
    
    // Set Status Bar Style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func goBack(sender: AnyObject) {
        webView.goBack()
    }
    
    func refresh() {
        webView.reload()
        print("Refresh Page")
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
        if let vc = segue.destination as? SideMenuTableView {
            vc.delegate = self
        }
    }
}
