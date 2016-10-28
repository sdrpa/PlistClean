
// Created by Sinisa Drpa on 10/27/16.

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var arrayController: NSArrayController!
    @IBOutlet weak var tableView: TableView!
    
    dynamic var orphans = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let orphans = PlistChecker.orphans else {
            return
        }
        self.orphans = orphans
        
        self.tableView.deleteBackward = {
            self.deleteSelected()
        }
    }
    
    override func viewDidAppear() {
        self.titleNeedsDisplay()
    }
    
    func deleteSelected() {
        let plistDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let plistDirectoryUrl = URL(fileURLWithPath: plistDirectory[0], isDirectory: true).appendingPathComponent("Preferences")
        
        let selected = self.arrayController.selectedObjects.reduce([URL]()) { acc, bundleIdentifier in
            guard let bundleId = bundleIdentifier as? String else {
                return acc
            }
            let fileUrl = plistDirectoryUrl.appendingPathComponent(bundleId + ".plist")
            return acc + [fileUrl]
        }
        
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to delete \(selected.count) item" + ((selected.count > 1) ? "s" : "")
        alert.informativeText = "This will permanently delete the selected items"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == NSAlertFirstButtonReturn {
            for fileUrl in selected {
                do {
                    try FileManager.default.trashItem(at: fileUrl, resultingItemURL: nil)
                }
                catch (let error) {
                    let alert = NSAlert(error: error)
                    alert.runModal()
                }
            }
            self.arrayController.remove(self)
            self.titleNeedsDisplay()
        }
    }
    
    func titleNeedsDisplay() {
        self.view.window?.title = "\(self.orphans.count) item" + ((self.orphans.count > 1) ? "s" : "")
    }
}
