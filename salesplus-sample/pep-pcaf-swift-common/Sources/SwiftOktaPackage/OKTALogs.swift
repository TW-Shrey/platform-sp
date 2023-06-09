//
//  File.swift
//  
//
//  Created by infyuser on 31/08/22.
//

import Foundation

public struct Log: TextOutputStream {

    public func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
}
