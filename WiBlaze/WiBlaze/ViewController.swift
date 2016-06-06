//
//  ViewController.swift
//  WiBlaze
//
//  Created by Justin Bush on 2016-01-23.
//  Copyright © 2016 Justin Bush. All rights reserved.
//

import UIKit
import WebKit
import Foundation

class ViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate {
    
    var webView: WKWebView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var bookmarksButton: UIBarButtonItem!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
        
        UIApplication.sharedApplication().statusBarStyle = .Default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textField.delegate = self
        
        self.backButton.enabled = false
        self.refreshButton.enabled = false
        self.forwardButton.enabled = false
        
        // Load previously saved URL
        if NSUserDefaults.standardUserDefaults().objectForKey("savedURL") != nil {
            let url = NSUserDefaults.standardUserDefaults().objectForKey("savedURL")!
            let request = NSURL(string: url as! String)!
            webView.loadRequest(NSURLRequest(URL: request))
        }

        webView.allowsBackForwardNavigationGestures = true
        
        // Notification observer for device orientation
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDidRotate", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setTextFieldWidth() {
        var frame: CGRect = self.textField.frame
        frame.size.width = self.view.frame.width
        self.textField.frame = frame
    }
    
    func userDidRotate() {
        if(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
            print("Orientation Change: Landscape")
            setTextFieldWidth()
        }
        
        if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            print("Orientation Change: Portrait")
            setTextFieldWidth()
        }
    }
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        textField.resignFirstResponder()
        print("Request:", textField.text!)
        
        let request = textField.text!
        
        // Check if request ONLY contains URL prefixes
        let prefixes = ["http://", "https://", "www.", "http://www.", "https://www."]
        
        if prefixes.contains(request) {
            print("URL does contain prefix")
            // URL ONLY contains prefix
            // Load page error: Not a valid URL
        }
        
        // Check if request contains http:// or https:// + a string
        if (request.lowercaseString.rangeOfString("http://") != nil) || (request.lowercaseString.rangeOfString("https://") != nil) {
            print("String does contain prefix")
            // Replace any spaces with %20
            let request = request.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
            let formattedURL = NSURL(string: request)!
            webView.loadRequest(NSURLRequest(URL: formattedURL))
        }
        
        // Check if request contains a period
        else if request.rangeOfString(".") != nil {
            print("Period exists, add http:// and load request as URL")
            let request = request.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
            let formattedURL = NSURL(string: "http://" + request)!
            webView.loadRequest(NSURLRequest(URL: formattedURL))
            print("Loading URL:", formattedURL)
        }
        
        // Check if request does not pass URL test
        else {
            print("Request does not pass URL test, load as search term")
            let query = request.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            let formattedURL = NSURL(string: "https://google.com/#q=\(query)")!
            webView.loadRequest(NSURLRequest(URL: formattedURL))
            print("Loading URL:", formattedURL)
        }
        
        return true
    }
    
    // WebView has finished loading
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("URL has loaded successfully")
        // Reflect loaded URL in textField
        textField.text = webView.URL?.absoluteString as String!
        
        // Save URL for if application quits or crashes
        let url = textField.text!
        NSUserDefaults.standardUserDefaults().setObject(url, forKey: "savedURL")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Check if request contains https://
        if (textField.text!.lowercaseString.rangeOfString("https://") != nil) {
            print("String is secure https")
            self.textField.textColor = UIColor(red:0.0, green:0.75, blue:0.02, alpha:1.0)
        }
        
        else {
            self.textField.textColor = self.view.tintColor
        }
        
        self.refreshButton.enabled = true
        
        if (self.webView.canGoBack) {
            self.backButton.enabled = true
        } else {
            self.backButton.enabled = false
        }
        
        if (self.webView.canGoForward) {
            self.forwardButton.enabled = true
        } else {
            self.forwardButton.enabled = false
        }
    }
    
    @IBAction func back(sender: AnyObject) {
        if (self.webView.canGoBack) {
            self.webView.goBack()
        }
    }
    
    @IBAction func refresh(sender: AnyObject) {
            self.webView.reload()
    }
    
    @IBAction func forward(sender: AnyObject) {
        if (self.webView.canGoForward) {
            self.webView.goForward()
        }
    }
    
    @IBAction func menu(sender: AnyObject) {
        let kInfoTitle = "Menu"
        let kSubtitle = textField.text!
        let menu = SCLAlertView()
        menu.addButton("Share", target:self, selector:Selector("firstButton"))
        menu.addButton("Set as Homepage", target:self, selector:Selector("firstButton"))
        menu.addButton("Add to Favourites", target:self, selector:Selector("firstButton"))
        menu.addButton("Settings", target:self, selector:Selector("firstButton"))
        menu.showEdit(kInfoTitle, subTitle: kSubtitle)
    }
}