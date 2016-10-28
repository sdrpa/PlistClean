
// Created by Sinisa Drpa on 10/27/16.

import Cocoa

struct Package {
    let url: URL
    let bundleIdentifier: String
}

final class PlistChecker {
    
    static var orphans: [String]? {
        let plistDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let plistDirectoryURL = URL(fileURLWithPath: plistDirectory[0], isDirectory: true)
        guard let plists = self.plists(directory: plistDirectoryURL.appendingPathComponent("Preferences")) else {
            return nil
        }
        
        let applicationDirectory = "/Applications"
        let applicationDirectoryURL = URL(fileURLWithPath: applicationDirectory, isDirectory: true)
        guard let applications = self.applications(directory: applicationDirectoryURL) else {
            return nil
        }
        
        return self.orphansComparing(plists: plists, applications: applications)
    }
    
    private static func orphansComparing(plists: [URL], applications: [URL]) -> [String]? {
        let plistArray = plists.reduce([String]()) { acc, url in
            return acc + [url.lastPathComponent]
        }
        let plistSet = Set(plistArray)
        
        let bundleIdentifierArray = applications.reduce([String]()) { acc, url in
            guard let bundleIdentifier = self.bundleIdentifierForApplication(url: url) else {
                return acc
            }
            return acc + [bundleIdentifier]
        }
        
        let subarray = Array(plistSet.subtracting(bundleIdentifierArray)).sorted(by: { $0 < $1 })
        let filtered = subarray.filter { !$0.hasPrefix("com.apple") } // Ignore com.apple.* plists
        
        return filtered.reduce([String]()) { acc, bundleIdentifier in
            // If system can't find the absolutePathForApplication it's probably been deleted/uninstalled
            guard let _ = NSWorkspace.shared().absolutePathForApplication(withBundleIdentifier: bundleIdentifier) else {
                return acc + [bundleIdentifier]
            }
            return acc
        }
    }
    
    private static func plists(directory url: URL) -> [URL]? {
        let fileManager = FileManager.default
        let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        return contents?.filter { $0.pathExtension == "plist" }.map { $0.deletingPathExtension() }
    }
    
    private static func applications(directory url: URL) -> [URL]? {
        let localFileManager = FileManager.default
        
        let resourceKeys = [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey]
        let directoryEnumerator = localFileManager.enumerator(at: url, includingPropertiesForKeys: resourceKeys, options: [], errorHandler: nil)!
        
        var applications: [URL] = []
        for case let fileURL as NSURL in directoryEnumerator {
            if fileURL.pathExtension == "app" {
                applications.append(fileURL as URL)
                directoryEnumerator.skipDescendants()
            }
        }
        return applications
    }
    
    private static func bundleIdentifierForApplication(url: URL) -> String? {
        let workspace = NSWorkspace.shared()
        guard let appPath = workspace.fullPath(forApplication: url.path) else {
            return nil
        }
        let appBundle = Bundle(path: appPath)
        return appBundle?.bundleIdentifier
    }
}
