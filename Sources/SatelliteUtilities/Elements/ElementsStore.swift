/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ ElementsStore.swift                                                           SatelliteUtilities ║
  ║ Created by Gavin Eadie on Jan20/16 ... Copyright 2016-25 Ramsay Consulting. All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import SatelliteKit
import OSLog

let storeLogger = Logger(subsystem: "com.ramsaycons.SatelliteUtilities", category: "main")

/// a Store is a file directory in '~/Library/Cache/' that stores `ElementsGroup`.
/// The name of the cache is `baseName` (com.ramsaycons.SatelliteUtilities by default)
/// and the stored files are referred to with a `groupName` (eg: "visual").
/// The file contains JSON version of the `ElementsGroup` ..
public struct ElementsStore {
    
    let fm = FileManager.default
    let directoryURL: URL
    let storeName: String
    let logging: Bool

    /// Creates an `ElementsStore`
    /// - Parameters:
    ///   - storeName: the name of the directory (the store) in '~/Library/Cache/'
    ///   - logging: enables logging store actions (defaults `true`)
    public init(storeName: String = "com.ramsaycons.SatelliteUtilities", logging: Bool = false) {
        self.storeName = storeName
        self.logging = logging

        let cacheURLs = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        if let cacheURL = cacheURLs.first?.appendingPathComponent(self.storeName) {
            do {
                try fm.createDirectory(at: cacheURL,
                                       withIntermediateDirectories: true)
            } catch let error {
                if logging { storeLogger.info("× Store.init| \(error.localizedDescription)") }
            }
            if logging { storeLogger.info("• Store.init| \(cacheURL.path)") }
            self.directoryURL = cacheURL
        } else {                                                // no cache directory (unusual)
            fatalError("× Store.init| No '~/Library/Caches/\(self.storeName)' directory")
        }
    }

    /// An `ElementsStore` contains a collection `ElementsGroup`s in named files.
    /// an entry is also dated so it can be aged
    /// - Parameters:
    ///   - group: an `ElementsGroup`
    ///   - named: a String naming this entry
    ///   - dated: a `Date` (defaults to now) used to set the file modification date of the entry's file.
    public func insertElements(_ group: ElementsGroup,
                               named: String,
                               dated: Date = Date()) {
        let groupFileURL = self.directoryURL.appendingPathComponent(named.lowercased())
        do {
            let groupData = try JSONEncoder().encode(group)
            try groupData.write(to: groupFileURL)
        } catch let error {
            if logging { storeLogger.info("×  Store.ins| \(error.localizedDescription)") }
        }
        setElementsDate(groupName: named.lowercased(), date: dated)
        if logging { storeLogger.info("•  Store.add| '\(groupFileURL.lastPathComponent)' @ \(dated)") }
    }

    /// get an elements group out of the elements store [EXTENSION]
    ///
    /// - Parameters:
    ///   - fileKey: the name of the elements group
    ///
    /// - Returns: the elements group contents or nil
    public func extractElements(named: String) -> ElementsGroup? {
        let groupFileURL = self.directoryURL.appendingPathComponent(named.lowercased())

        do {
//          decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
            let data = try Data(contentsOf: groupFileURL)
            return try JSONDecoder().decode(ElementsGroup.self, from: data)
        } catch let error {
            if logging { storeLogger.info("×  Store.ext| \(error.localizedDescription)") }
            return nil
        }
    }
    
    public func deleteElements(groupName: String) {
        let groupFileURL = self.directoryURL.appendingPathComponent(groupName.lowercased())

        if fm.fileExists(atPath: groupFileURL.path) {
            do {
                try fm.removeItem(at: groupFileURL)
                if logging { storeLogger.info("•  Store.del| '\(groupFileURL.lastPathComponent)' - Deleted") }
            } catch {
                storeLogger.error("×  Store.del| Failed to delete '\(groupName)': \(error.localizedDescription)")
            }
        } else {
            storeLogger.warning("×  Store.del| '\(groupName)' does not exist")
        }
    }

    public func deleteAllElements() {

        do {
            for groupFileURL in try fm.contentsOfDirectory(at: self.directoryURL,
                                                           includingPropertiesForKeys: nil) {
                try fm.removeItem(at: groupFileURL)
            }
            if logging { storeLogger.info("•  Store.emp| Store emptied ..") }
        } catch {
            if logging { storeLogger.info("×  Store.emp| Error emptying store: \(error.localizedDescription)") }
        }

    }

    public func deleteStore() {
        
        do {
            try fm.removeItem(at: self.directoryURL)
            if logging { storeLogger.info("•  Store.emp| Store deleted ..") }
        } catch {
            if logging { storeLogger.info("×  Store.emp| Error deleting store: \(error.localizedDescription)") }
        }
        
    }

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ get cache file's last-mod Date (.distantPast if failure)                                         │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    public func getElementsDate(groupName: String) -> Date {
        let groupName = groupName.lowercased()
        do {
            let attrs = try fm.attributesOfItem(
                         atPath: self.directoryURL.appendingPathComponent(groupName).path)
            let date: Date = attrs[FileAttributeKey.modificationDate] as! Date
            if logging { storeLogger.info("•  Store.mod| '\(groupName)' → \(date)") }
            return date
        } catch {
            return Date.distantPast
        }
    }

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    public func setElementsDate(groupName: String, date: Date) {
        let groupName = groupName.lowercased()
        do {
            let attrs = [FileAttributeKey.modificationDate: date]
            try fm.setAttributes(attrs,
                    ofItemAtPath: self.directoryURL.appendingPathComponent(groupName).path)
            if logging { storeLogger.info("•  Store.mod| '\(groupName)' ← \(date)") }
        } catch {
            if logging { storeLogger.warning("×  Store.mod| \(error.localizedDescription)") }
        }
    }
    
/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ get cache file's age (in minutes)                                                                │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    public func ageElements(groupName: String) -> Double? {
        let modificationDate = getElementsDate(groupName: groupName.lowercased())
        if #available(macOS 12, iOS 15, tvOS 16, watchOS 8, *) {
            precondition(Date.now > modificationDate)
        } else {
            precondition(Date() > modificationDate)
        }

        if modificationDate == Date.distantPast { return nil }

        let daysOld = -modificationDate.timeIntervalSinceNow/(24*60*60)
        if daysOld < 7.0 {
            if logging { storeLogger.info("•  Store.age| \(daysOld, format: .fixed(precision: 2)) days") }
        } else {
            if logging { storeLogger.info("•  Store.age| older than a week") }
        }

        return daysOld
    }

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    func prettyPrint() -> String {

        var storePath: String
        if #available(macOS 13.0, iOS 16, tvOS 16, watchOS 9, *) {
            storePath = self.directoryURL.path(percentEncoded: false)
        } else {
            storePath = self.directoryURL.path.removingPercentEncoding ?? "< missing >"
        }

        do {
            let storeUrlArray = try fm.contentsOfDirectory(at: self.directoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: .skipsHiddenFiles)

            return """

            ┌─[ElementsStore]───────────────────────────────────────────────────────
            │  store: \(storePath)
            │  count: \(storeUrlArray.count)
            │  files: \(storeUrlArray.map( { $0.lastPathComponent } ))
            └───────────────────────────────────────────────────────────────────────
            """

        } catch {
            return """

            ┌─[ElementsStore]───────────────────────────────────────────────────────
            │  store: \(self.directoryURL.path) does not exist.
            └───────────────────────────────────────────────────────────────────────
            """
        }
    }
}


extension String {
    
    /// A variation of contentsOf but it doesn't throw
    /// - Parameter url: the URL to read
     init?(urlContents url: URL) {

        do {
            self = try String(contentsOf: url)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        } catch {
            print(error)
            return nil
        }

    }
    
    /// A variation on URL.write that doesn't throw
    /// - Parameters:
    ///   - url: the URL to write
    func writeNoThrow(to url: URL) {

        do {
            try self.write(to: url, atomically: false, encoding: .utf8)

        } catch let error as CocoaError {
            storeLogger.info("CocoaError [\(error.code.rawValue)]: \(error.localizedDescription)")
            if let err = error.underlying {
                storeLogger.info("\(err.localizedDescription)")
            }
            if let path = error.filePath {
                storeLogger.info("File path: \(path)")
            }
            if let url = error.url {
                storeLogger.info("URL: \(url)")
            }
            if let encoding = error.stringEncoding {
                storeLogger.info("String encoding: \(encoding)")
            }
        }

        catch let error as NSError {
            storeLogger.info("NSError: \(error)")
            if let reason = error.localizedFailureReason {
                storeLogger.info("Reason: \(reason)")
            }
            storeLogger.info("Domain: \(error.domain)")
            storeLogger.info("Code: \(error.code)")
            storeLogger.info("User Info: \(error.userInfo)")

        } catch let error {
            storeLogger.info("error: \(error)")
        }
    }

}
