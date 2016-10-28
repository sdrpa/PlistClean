
// Created by Sinisa Drpa on 10/27/16.

import Cocoa

class TableView: NSTableView {
    
    var deleteBackward: (() -> Void)?
    
    override func deleteBackward(_ sender: Any?) {
        if self.selectedRow == -1 {
            super.deleteBackward(sender)
            return
        }
        self.deleteBackward?()
    }
    
    override func keyDown(with event: NSEvent) {
        self.interpretKeyEvents([event])
    }
}


