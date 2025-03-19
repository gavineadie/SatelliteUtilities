/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ ElementsGroup.swift                                                           SatelliteUtilities ║
  ║ Created by Gavin Eadie on Apr20/17 ... Copyright 2017-25 Ramsay Consulting. All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import SatelliteKit

enum APIError: Error {
    case invalidUrl
    case invalidData
}

/// An `ElementsGroup` is a structure of a processed `Elements` collection.  Each Satellite is
/// indexed by its numeric NORAD ID.  A `Date` property could be the age of the `ElementsGroup`.
/// One ElementsGroup would typically be derived from reading multiple TLEs from one file.
/// ```
///         +------------------------------------------------+
///         |  named: "visual", etc ..                       |
///         |  dated: an arbitrary date stamp                |
///         +-----------+------------------------------------+
///         |           | +--------------------------------+ |
///         | 12345 --> | | commonName, noradIndex,        | |
///         |           | | launchName, t₀, e₀, i₀, ω₀,    | |
///         |           | | Ω₀, M₀, n₀, a₀, ephemType,     | |
///         |           | | tleClass, tleNumber, revNumber | |
///         |           | +--------------------------------+ |
///         +-----------+------------------------------------+
///         |           | +--------------------------------+ |
///         | 43210 --> | | Elements ...                   | |
///         |           | |                                | |
///         |           | +--------------------------------+ |
///         +-----------+------------------------------------+
///         |           |                                    |
/// ```
public struct ElementsGroup: Codable {

    var named: String
    var dated: Date = Date.distantPast
    public var table = [UInt : Elements]()
    
    /// Creates an empty `ElementsGroup` named: "----" and dated: .distantPast
    public init() {
        self.named = "----"
        self.dated = Date.distantPast
    }
    
    /// Creates an `ElementsGroup` containing Satellites extracted from an array of `Elements`,
    /// named: "ELEMENTS" and dated: .now
    /// - Parameter elementsArray: an array of `Elements`
    public init(_ elementsArray: [Elements]) {
        self.init()
        self.named = "ELEMENTS"
        if #available(macOS 12, *, iOS 15, *) {
            self.dated = Date.now
        } else {
            self.dated = Date()
        }
        self.table = Dictionary(uniqueKeysWithValues: elementsArray.map{ (UInt($0.noradIndex), $0) })
    }
    
    /// Creates a named `ElementsGroup` containing Satellites extracted from an array of `Elements`,
    /// named and dated explicitly
    /// - Parameters:
    ///   - elementsArray: an array of `Elements`
    ///   - named: a group name
    ///   - dated: a creation date (default .distantPast)
    public init(_ elementsArray: [Elements],
                named: String,
                dated: Date = .distantPast) {
        self.init(elementsArray)
        self.named = named
        self.dated = dated
    }

    /// Creates an `ElementsGroup` containing Satellites extracted from a TLE `String`
    /// - Parameter tlesText: a `String` containing TLEs
    public init(_ tlesText: String) throws {
        self.init(try preProcessTLEs(tlesText).map { try Elements($0.0, $0.1, $0.2) })
    }
    
}

public extension ElementsGroup {
    
    /// obtains one satellite's `Elements` from the `ElementsGroup`
    /// - Parameter norad: the object's NORAD ID
    /// - Returns: the satellite `Elements`
    func norad(_ norad: UInt) -> Elements? { table[norad] }

}

public extension ElementsGroup {

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    func prettyPrint() -> String {

        String("""

            ┌─[ElementsGroup]───────────────────────────────────────────────────────
            │  named: "\(named)"
            │  dated: \(dated)
            │  count: \(table.count) ← number of Elements in the group table
            └───────────────────────────────────────────────────────────────────────
            """)
    }
}
