//
//  Extensions.swift
//  WiBlaze
//
//  Created by Justin Bush on 2020-04-28.
//  Copyright © 2020 Justin Bush. All rights reserved.
//

import UIKit
import WebKit


// MARK: WKWebView

// WKWebView Extension
extension WKWebView {
    /// Quick load a URL in the WebView with ease
    func load(_ string: String) {
        if let url = URL(string: string) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
    /// Quick load a URL in the WebView with ease
    func load(_ url: URL) {
        let request = URLRequest(url: url)
        load(request)
    }
    /// Quick load a `file` (without `.html`) and `path` to the directory
    func loadFile(_ name: String, path: String) {
        if let url = Bundle.main.url(forResource: name, withExtension: "html", subdirectory: path) {
            self.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            load(request)
        }
    }
}


// MARK: URL

extension URL {
    /// Converts `URL` to Optional `String`
    func toString() -> String {
        return self.absoluteString
    }
    
    func isSecure() -> Bool {
        let string = self.toString()
        if string.contains("https://") { return true }
        else { return false }
    }
}

// MARK: String
extension String {
    /// Converts `String` to `URL`
    func toURL() -> URL {
        return URL(string: self)!
    }
    /// Get the name of a file, from a `Sring`, without path or file extension
    /// # Usage
    ///     let path = "/dir/file.txt"
    ///     let file = path.fileName()
    /// - returns: `"/dir/file.txt" -> "file"`
    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
    /// Get the extension of a file (`html`, `txt`, etc.), from a `Sring`, without path or name
    /// # Usage
    ///     let name = "index.html"
    ///     let ext = name.fileExtension()
    /// - returns: `"file.txt" -> "txt"`
    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
    /// Get the file name and extension (`file.txt`), from a `Sring`, without path component
    /// # Usage
    ///     let path = "/path/to/file.txt"
    ///     let file = path.removePath()
    /// - returns: `"/path/to/file.txt" -> "file.txt"`
    func removePath() -> String {
        return URL(fileURLWithPath: self).lastPathComponent
    }
    /// Extracts URLs from a `String` and returns them as an `array` of `[URLs]`
    /// # Usage
    ///     let html = [HTML as String]
    ///     let urls = html.extractURLs()
    /// - returns: `["url1", "url2", ...]`
    func extractURLs() -> [URL] {
        var urls : [URL] = []
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            detector.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.count), using: { (result, _, _) in
                if let match = result, let url = match.url {
                    urls.append(url)
                }
            })
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return urls
    }
    /// Returns true if the `String` is either empty or only spaces
    func isBlank() -> Bool {
        if (self.isEmpty) { return true }
        return (self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) == "")
    }
}



