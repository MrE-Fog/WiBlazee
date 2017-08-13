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
import SystemConfiguration

class ViewController: UIViewController, UINavigationControllerDelegate, WKNavigationDelegate, UITextFieldDelegate, SideMenuTableViewDelegate {

    let defaults = UserDefaults.standard
    
    var webView: WKWebView!
    var sourceCode: String! = ""

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
        
        addressBar.delegate = self
        var homepageURL: String!
        
        // Set Placeholder Style
        addressBar.attributedPlaceholder = NSAttributedString(string:" Search or type URL", attributes: [NSForegroundColorAttributeName: UIColor.gray])
        
        // Set Homepage
        if defaults.bool(forKey: "customHomepage") {
            
            if let homepageURL = defaults.string(forKey: "homepageURL") {
                // Custom Homepage is Enabled
                let webURL = URL(string: homepageURL)
                let webRequest = URLRequest(url: webURL!)
                webView.load(webRequest)
                print("Load Custom Homepage:", homepageURL)
                
            } else {
                // No Custom Homepage, Load Default
                homepageURL = "https://google.com"
                let webURL = URL(string: homepageURL)
                let webRequest = URLRequest(url: webURL!)
                webView.load(webRequest)
            }
            
        } else {
            // No Custom Homepage, Load Default
            homepageURL = "https://google.com"
            let webURL = URL(string: homepageURL)
            let webRequest = URLRequest(url: webURL!)
            webView.load(webRequest)
        }
        
        // Configure User Agent
        let phoneUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1"
        //let padUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1"
        
        // Custom User Agent
        webView.customUserAgent = phoneUserAgent
        
        // Set WebKit Load Configurations
        webView.allowsBackForwardNavigationGestures = true
        
        // Setup Menu Controller
        let menuRightNavigationController = UISideMenuNavigationController()
        SideMenuManager.menuRightNavigationController = menuRightNavigationController
        SideMenuManager.menuBlurEffectStyle = .dark
        SideMenuManager.menuPresentMode = .menuSlideIn
        
        // Set Menu Width (eg. * 0.65 = 65%)
        SideMenuManager.menuWidth = max(round(min((appScreenRect.width), (appScreenRect.height)) * 0.65), 240)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("RefreshNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("GoHomeNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("RequestDesktopNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShowSourceCodeNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        noNetworkConnection()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveRefreshNotification(notification:)), name: NSNotification.Name("RefreshNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveGoHomeNotification(notification:)), name: NSNotification.Name("GoHomeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveRequestDesktopNotification(notification:)), name: NSNotification.Name("RequestDesktopNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveShowSourceCodeNotification(notification:)), name: NSNotification.Name("ShowSourceCodeNotification"), object: nil)
    }
    
    // User Began Editing Address Bar
    func textFieldDidBeginEditing(_ addressBar: UITextField) {
        print("User began editing address bar")
        addressBar.selectedTextRange = addressBar.textRange(from: addressBar.beginningOfDocument, to: addressBar.endOfDocument)
    }
    
    // User Returned Address Bar, Setup Address Bar
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addressBar.resignFirstResponder()
        print("User Requested:", addressBar.text!)
        loadURL(address: addressBar.text!)
        return true
    }
    
    // Clean Address Bar
    func cleanAddress(address: String) {
        let currentURL = (webView.url)!
        let hostURL = URL(string: "/", relativeTo: currentURL)?.absoluteURL
        var cleanURL = (hostURL?.absoluteString)!
        if cleanURL.hasSuffix("/") {
            cleanURL = String(cleanURL.characters.dropLast())
        }
        addressBar.text = cleanURL
        print("Clean URL:", cleanURL)
    }

    // Toggle Back Button
    func checkBack() {
        if webView.canGoBack {
            backButton.isEnabled = true
        } else {
            backButton.isEnabled = false
        }
    }
    
    // Validate URL
    func validateURL(urlString: String) -> Bool {
        let urlRegEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: urlString)
    }
    
    // Format URL Scheme
    func formatURL(userRequest: String) -> String {
        
        var formattedURL: String
        
        // Check if userRequest only contains URL prefixes
        let prefixes = ["http://", "https://", "www.", "http://www.", "https://www."]
        
        if validateURL(urlString: userRequest) {
            // userRequest is a valid URL
            if prefixes.contains(userRequest) {
                // URL does have prefix
                formattedURL = userRequest
            } else {
                // Format URL and add prefix
                formattedURL = "http://" + userRequest
            }
            
            print("Load URL:", formattedURL)
            return formattedURL
            
        } else {
            
            // userRequest is not a valid URL, load search query
            let searchQuery = userRequest.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
            let searchEngine = "https://google.com/#q="
            let searchURL = searchEngine + searchQuery
            print("Load Search:", searchURL)
            return searchURL
        }
    }
    
    // Load URL in the WebView
    func loadURL(address: String) {
        if (webView.customUserAgent != "") {
            webView.customUserAgent = ""
        }
        let address = formatURL(userRequest: address)
        let webURL = URL(string: address)
        let webRequest = URLRequest(url: webURL!)
        webView.load(webRequest)
    }
    
    // Called when user is not connected to a network
    func noNetworkConnection() {
        if isConnectedToNetwork() == false {
            print("No Network Connection")
            activityNavigationBar?.reset()
            let alert = UIAlertController(title: "Network Error", message: "You are currently not connected to a network. Please connect and try again.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // WebView Called for Navigation
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityNavigationBar?.startActivity(andWaitAt: 0.8)
        noNetworkConnection()
        
        //if webView.url?.absoluteString.hasPrefix("https://")
        activityNavigationBar?.activityBarColor = UIColor.white
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
        addressBar.text = webView.url?.absoluteString
        activityNavigationBar?.reset()
        print("Successfully Loaded:", addressBar)
    }
    
    // Setup Activity Navigation
    var activityNavigationBar: ActivityNavigationBar? {
        return navigationController?.navigationBar as? ActivityNavigationBar
    }
    
    // Set Status Bar Style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // Go Back to Previous WebPage
    @IBAction func goBack(sender: AnyObject) {
        webView.goBack()
        print("Load Previous URL")
    }
    
    // Refresh WebView Content
    func receiveRefreshNotification(notification: Notification) {
        webView.reload()
        print("Refresh Page")
    }
    
    func receiveGoHomeNotification(notification: Notification) {
        var homepageURL: String!
        
        // Set Homepage
        if defaults.bool(forKey: "customHomepage") {
            
            if let homepageURL = defaults.string(forKey: "homepageURL") {
                // Custom Homepage is Enabled
                let webURL = URL(string: homepageURL)
                let webRequest = URLRequest(url: webURL!)
                webView.load(webRequest)
                print("Load Custom Homepage:", homepageURL)
                
            } else {
                // No Custom Homepage, Load Default
                homepageURL = "https://google.com"
                let webURL = URL(string: homepageURL)
                let webRequest = URLRequest(url: webURL!)
                webView.load(webRequest)
            }
            
        } else {
            // No Custom Homepage, Load Default
            homepageURL = "https://google.com"
            let webURL = URL(string: homepageURL)
            let webRequest = URLRequest(url: webURL!)
            webView.load(webRequest)
        }
    }
    
    func receiveRequestDesktopNotification(notification: Notification) {
        // Set Desktop UserAgent
        let desktopAgent: String! = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/602.3.12 (KHTML, like Gecko) Version/10.0.2 Safari/602.3.12"
        webView.customUserAgent = desktopAgent
        print("Request URL with UserAgent:", webView.customUserAgent!)
        webView.reload()
    }
    
    func receiveShowSourceCodeNotification(notification: Notification) {
        performSegue(withIdentifier: "showSource", sender: nil)
    }
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
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
        if let vc = segue.destination as? UISideMenuNavigationController {
            vc.delegate = self
        }
        
        if segue.identifier == "showSource" {
            
            let jCode = "document.documentElement.outerHTML.toString()"
            webView.evaluateJavaScript(jCode, completionHandler: { (html: Any?, Error: Error?) in
                let webCode = html
                let code = webCode as! String
                let codeController = segue.destination as! SourceViewController
                codeController.code = code
            })
        }
    }
}
