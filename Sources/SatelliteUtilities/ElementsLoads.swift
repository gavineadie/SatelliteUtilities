//
//  File.swift
//  SatelliteUtilities
//
//  Created by Gavin Eadie on 3/18/25.
//

import Foundation

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
        self = ElementsGroup(tlesData(elements),
                             named: named,
                             dated: date ?? Date())
        if let store { store.insertElements(self, named: named) }
    }
}

func tlesData(_ data: Data) -> [Elements] {
    parseData(data) { rawData in
        try preProcessTLEs(String(data: rawData, encoding: .utf8)!)
            .map { try Elements($0.0, $0.1, $0.2) }
    } ?? []
}

@available(macOS 12.0, tvOS 15.0, *)

/// Populates an `ElementGroup` from a link to a JSON text file ..
/// - Parameters:
///   - jsonLink: the URL where the satellite JSON TLEs will be found
///   - group: the name of the `ElementsGroup`
public func downloadJSON(_ jsonLink: String,
                         named: String,
                         store: ElementsStore? = nil) async -> ElementsGroup? {
    storeLogger.notice("•  Group.JSN ← \(jsonLink, privacy: .public)")
    guard let url = URL(string: jsonLink) else { return nil }

    /*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
     │                                                                             .. go to the network │
     └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    let (elements, date) = await fetchFrom(url)
    let group = ElementsGroup(jsonData(elements),
                              named: named,
                              dated: date ?? Date())
    if let store { store.insertElements(group, named: named) }

    return group

    func jsonData(_ data: Data) -> [Elements] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
        return parseData(data) { rawData in
            return try decoder.decode([Elements].self, from: rawData)
        } ?? []
    }

}

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
        self = ElementsGroup(xmlData(elements),
                             named: named,
                             dated: date ?? Date())
        if let store { store.insertElements(self, named: named) }
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
        self = ElementsGroup(csvData(elements),
                             named: named,
                             dated: date ?? Date())
        if let store { store.insertElements(self, named: named) }
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


