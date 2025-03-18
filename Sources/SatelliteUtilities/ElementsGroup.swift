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

@available(macOS 12.0, tvOS 15.0, *)
public extension ElementsGroup {

    /// Populates an `ElementGroup` from a link to a TLE file ..
    /// - Parameters:
    ///   - tlesLink: the link to the network TLE file
    ///   - groupName: a name for the group
    ///   - usingCache: whether to cache the downloaded elements (default: false)
    mutating func downloadTLEs(_ tlesLink: String,
                               named: String,
                               store: ElementsStore? = nil) async {
        storeLogger.notice("•  Group.TLE ← \(tlesLink, privacy: .public)")
        guard let url = URL(string: tlesLink) else { return }
        
        let (elements, date) = await fetchFrom(url)

        self = ElementsGroup(tlesData(elements))
        self.named = named
        self.dated = date ?? Date()
    }
}

func tlesData(_ data: Data) -> [Elements] {
    parseData(data) { rawData in
        try preProcessTLEs(String(data: rawData, encoding: .utf8)!)
            .map { try Elements($0.0, $0.1, $0.2) }
    } ?? []
}

//func tlesData(_ data: Data) -> [Elements] {
//    do {
//        return try preProcessTLEs(String(data: data, encoding: .utf8)!)
//            .map { try Elements($0.0, $0.1, $0.2) }
//    } catch let error {
//        storeLogger.error("×   tlesData ← elements preprocessing error: '\(error)'")
//        return [Elements]()
//    }
//}

@available(macOS 12.0, tvOS 15.0, *)
public extension ElementsGroup {

/// Populates an `ElementGroup` from a link to a JSON text file ..
/// - Parameters:
///   - jsonLink: the URL where the satellite JSON TLEs will be found
///   - group: the name of the `ElementsGroup`
    mutating func downloadJSON(_ jsonLink: String,
                               named: String,
                               store: ElementsStore? = nil) async {
        storeLogger.notice("•  Group.JSN ← \(jsonLink, privacy: .public)")
        guard let url = URL(string: jsonLink) else { return }

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │                                                                             .. go to the network │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
        let (elements, date) = await fetchFrom(url)
        self = ElementsGroup(jsonData(elements),
                             named: named,
                             dated: date ?? Date())
        if let store {
            store.insertElements(groupName: named,
                                 groupJSON: self)
        }
    }
}

func jsonData(_ data: Data) -> [Elements] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
    return parseData(data) { rawData in
        return try decoder.decode([Elements].self, from: rawData)
    } ?? []
}

//public func jsonData(_ data: Data) -> [Elements] {
//	let decoder = JSONDecoder()
//	decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
//
//	return try! decoder.decode([Elements].self, from: data)
//}

@available(macOS 12.0, tvOS 15.0, *)
public extension ElementsGroup {

/// ```
///  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
///  ┃  functions of ElementsGroup which populate the 'table' ┃
///  ┃      downloadXMLs: from link to a XML text file ..     ┃
///  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
/// ```
/// download a XML file of satellite elements
/// - Parameters:
///   - xmlLink: the URL where the satellite XML TLEs will be found
///   - group: the name of the `ElementsGroup`
    mutating func downloadXMLs(_ xmlLink: String,
                               named: String,
                               store: ElementsStore? = nil) async {
        storeLogger.notice("•  Group.XML ← \(xmlLink, privacy: .public)")
        guard let url = URL(string: xmlLink) else { return }

        let (elements, date) = await fetchFrom(url)

        self = ElementsGroup(xmlData(elements))
        self.named = named
        self.dated = date ?? Date()
    }
}

func xmlData(_ data: Data) -> [Elements] {
/*╭╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╮
  ┆ divide the XML data (as String) into an array of strings: "<segment>...</segment>" ..            ┆
  ┆         .. 1) spilt at "</body>" to get strings ending "</segment>"                              ┆
  ┆         .. 2) spilt at "<body>" to get strings starting "<segment>"                              ┆
  ┆                 (gives two strings .. throw away the first one leaving "<segment>...</segment>"  ┆
  ┆                                                                                                  ┆
  ┆     "<segment>                                                                                   ┆
  ┆         <metadata>                                                                               ┆
  ┆             <OBJECT_NAME>THOR AGENA D R/B</OBJECT_NAME>                                          ┆
  ┆             <OBJECT_ID>1964-002A</OBJECT_ID>                                                     ┆
  ┆             <CENTER_NAME>EARTH</CENTER_NAME>                                                     ┆
  ┆             <REF_FRAME>TEME</REF_FRAME>                                                          ┆
  ┆             <TIME_SYSTEM>UTC</TIME_SYSTEM>                                                       ┆
  ┆             <MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY>                                      ┆
  ┆         </metadata>                                                                              ┆
  ┆         <data>                                                                                   ┆
  ┆             <meanElements>                                                                       ┆
  ┆                 <EPOCH>2023-11-12T11:55:41.193120</EPOCH>                                        ┆
  ┆                 <MEAN_MOTION>14.32956936</MEAN_MOTION>                                           ┆
  ┆                 <ECCENTRICITY>.0032906</ECCENTRICITY>                                            ┆
  ┆                 <INCLINATION>99.0437</INCLINATION>                                               ┆
  ┆                 <RA_OF_ASC_NODE>271.0086</RA_OF_ASC_NODE>                                        ┆
  ┆                 <ARG_OF_PERICENTER>206.5810</ARG_OF_PERICENTER>                                  ┆
  ┆                 <MEAN_ANOMALY>153.3687</MEAN_ANOMALY>                                            ┆
  ┆             </meanElements>                                                                      ┆
  ┆             <tleParameters>                                                                      ┆
  ┆                 <EPHEMERIS_TYPE>0</EPHEMERIS_TYPE>                                               ┆
  ┆                 <CLASSIFICATION_TYPE>U</CLASSIFICATION_TYPE>                                     ┆
  ┆                 <NORAD_CAT_ID>733</NORAD_CAT_ID>                                                 ┆
  ┆                 <ELEMENT_SET_NO>999</ELEMENT_SET_NO>                                             ┆
  ┆                 <REV_AT_EPOCH>11677</REV_AT_EPOCH>                                               ┆
  ┆                 <BSTAR>.19664E-3</BSTAR>                                                         ┆
  ┆                 <MEAN_MOTION_DOT>.493E-5</MEAN_MOTION_DOT>                                       ┆
  ┆                 <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>                                           ┆
  ┆             </tleParameters>                                                                     ┆
  ┆         </data>                                                                                  ┆
  ┆     </segment>"                                                                                  ┆
  ╰╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╯*/
    parseData(data) { rawData in
        let string = String(data: rawData, encoding: .utf8)!
        let stringArray = string.components(separatedBy: "</body>")
            .compactMap { $0.components(separatedBy: "<body>").last }

        return stringArray.dropLast().map { Elements(xmlData: $0.data(using: .utf8)!) }
    } ?? []
}

//func xmlData(_ data: Data) -> [Elements] {
//    let string = String(data: data, encoding: .utf8)!
//	var stringArray = string.components(separatedBy: "</body>")
//	stringArray = stringArray.map { $0.components(separatedBy: "<body>").last! }
//
//	return stringArray.dropLast().map { Elements(xmlData: $0.data(using: .utf8)!) }
//}

@available(macOS 12.0, tvOS 15.0, *)
public extension ElementsGroup {

    /// download a CSV file of satellite elements
    /// - Parameters:
    ///   - csvLink: the URL where the satellite XML TLEs will be found
    ///   - group: the name of the `ElementsGroup`
    mutating func downloadCSVs(_ csvLink: String,
                               named: String,
                               store: ElementsStore? = nil) async {
        storeLogger.notice("•  Group.CSV ← \(csvLink, privacy: .public)")
        guard let url = URL(string: csvLink) else { return }

        let (elements, date) = await fetchFrom(url)

        self = ElementsGroup(csvData(elements))
        self.named = named
        self.dated = date ?? Date()
    }
}

func csvData(_ data: Data) -> [Elements] {
    parseData(data) { rawData in
        let csvText = String(data: rawData, encoding: .utf8)!
        let csvRecords = csvText.replacingOccurrences(of: "\r", with: "").split(separator: "\n")

        guard let csvHeaders = csvRecords.first?.split(separator: ","),
              csvHeaders == [
                "OBJECT_NAME", "OBJECT_ID", "EPOCH", "MEAN_MOTION", "ECCENTRICITY", "INCLINATION",
                "RA_OF_ASC_NODE", "ARG_OF_PERICENTER", "MEAN_ANOMALY", "EPHEMERIS_TYPE",
                "CLASSIFICATION_TYPE", "NORAD_CAT_ID", "ELEMENT_SET_NO", "REV_AT_EPOCH",
                "BSTAR", "MEAN_MOTION_DOT", "MEAN_MOTION_DDOT"
              ] else {
            storeLogger.error("CSV headers do not match expected format")
            return []
        }

        return csvRecords.dropFirst().map { row in
            let csvItems = row.split(separator: ",")
            return Elements(
                commonName: String(csvItems[0]),
                noradIndex: UInt(String(csvItems[11]))!,
                launchName: String(csvItems[1]),
                t₀: DateFormatter.iso8601Micros.date(from: String(csvItems[2]))!,
                e₀: Double(String(csvItems[4]))!,
                i₀: Double(String(csvItems[5]))!,
                ω₀: Double(String(csvItems[7]))!,
                Ω₀: Double(String(csvItems[6]))!,
                M₀: Double(String(csvItems[8]))!,
                n₀: Double(String(csvItems[3]))!,
                ephemType: Int(String(csvItems[9]))!,
                tleClass: String(csvItems[10]),
                tleNumber: Int(String(csvItems[12]))!,
                revNumber: Int(String(csvItems[13]))!,
                dragCoeff: Double(String(csvItems[14]))!
            )
        }
    } ?? []
}

//func csvData(_ data: Data) -> [Elements] {
//    let csvText = String(data: data, encoding: .utf8)!
//	let csvRecords = csvText.replacingOccurrences(of: "\r", with: "").split(separator: "\n")
//
//// ISS (ZARYA),1998-067A,2024-02-15T14:32:18.475296,15.49954571,.0001841,51.6397,202.8387,271.4206,164.9077,0,U,25544,999,43954,.36203E-3,.20226E-3,0
//
//	let csvHeaders = csvRecords[0].split(separator: ",")
//	guard csvHeaders == [
//		"OBJECT_NAME",          //  0
//		"OBJECT_ID",            //  1
//		"EPOCH",                //  2
//		"MEAN_MOTION",          //  3
//		"ECCENTRICITY",         //  4
//		"INCLINATION",          //  5
//		"RA_OF_ASC_NODE",       //  6
//		"ARG_OF_PERICENTER",    //  7
//		"MEAN_ANOMALY",         //  8
//		"EPHEMERIS_TYPE",       //  9
//		"CLASSIFICATION_TYPE",  // 10
//		"NORAD_CAT_ID",         // 11
//		"ELEMENT_SET_NO",       // 12
//		"REV_AT_EPOCH",         // 13
//		"BSTAR",                // 14
//		"MEAN_MOTION_DOT",      // 15
//		"MEAN_MOTION_DDOT"      // 16
//	] else {
//		fatalError("csv headers out of expected sequence")
//	}
//
//	var elementsArray = [Elements]()
//	for csvIndex in 1..<csvRecords.count {
//		let csvItems = csvRecords[csvIndex].split(separator: ",")
//
//		let nextElements = Elements(
//			commonName: String(csvItems[0]),
//			noradIndex: UInt(String(csvItems[11]))!,
//			launchName: String(csvItems[1]),
//					t₀: DateFormatter.iso8601Micros.date(from: String(csvItems[2]))!,
//					e₀: Double(String(csvItems[4]))!,
//					i₀: Double(String(csvItems[5]))!,
//					ω₀: Double(String(csvItems[7]))!,
//					Ω₀: Double(String(csvItems[6]))!,
//					M₀: Double(String(csvItems[8]))!,
//					n₀: Double(String(csvItems[3]))!,
//			 ephemType: Int(String(csvItems[9]))!,
//			  tleClass: String(csvItems[10]),
//			 tleNumber: Int(String(csvItems[12]))!,
//			 revNumber: Int(String(csvItems[13]))!,
//			 dragCoeff: Double(String(csvItems[14]))!)
//
//		elementsArray.append(nextElements)
//	}
//
//	return elementsArray
//}


/// get the string contents of a network URL (not a file URL)
/// - Parameter url: the URL where the satellite TLEs will be found
/// - Returns: the name of the `ElementsGroup`
public func fetchFrom(_ url: URL) async -> (Data, Date?) {

    if url.isFileURL { fatalError("\(#function): doesn't do file URLs ..") }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print(String(decoding: data, as: UTF8.self))
            fatalError("fetchFrom: non-200 net response ..")
        }

        return (data, dateFromHTTPHeaders(response as? HTTPURLResponse))

    } catch {
        fatalError("\(#function) \(error.localizedDescription) ..")
    }

    func dateFromHTTPHeaders(_ response: HTTPURLResponse?) -> Date {
        guard let response else { return Date() }
        guard let dataHeader = response.allHeaderFields["Date"] as? String else {
            storeLogger.warning("•  No HTTP 'Date' header")
            return Date()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss zzz"
        guard let date = dateFormatter.date(from: dataHeader) else {
            storeLogger.warning("•  HTTP 'Date' header malformed: \(dataHeader)")
            return Date()
        }
        return date
    }
}

public extension ElementsGroup {
    
    /// obtains one satellite's `Elements` from the `ElementsGroup`
    /// - Parameter norad: the object's NORAD ID
    /// - Returns: the satellite `Elements`
    func norad(_ norad: UInt) -> Elements? { table[norad] }

}

//MARK: - Pretty Printer

public extension ElementsGroup {

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    func prettyPrint() -> String {

        String("""

            ┌─[ElementsGroup]───────────────────────────────────────────────────────
            │  group: "\(named)"
            │  dated: \(dated)
            │  count: \(table.count) ← number of Elements in the group table
            └───────────────────────────────────────────────────────────────────────
            """)
    }
}

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
                                                                                             chatGPT
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
func parseData<T>(_ data: Data, using parser: (Data) throws -> T) -> T? {
    do {
        return try parser(data)
    } catch {
        storeLogger.error("Parsing error: \(error)")
        return nil
    }
}
