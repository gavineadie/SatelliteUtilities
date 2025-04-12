//
//  ElementsLoads.swift
//  SatelliteUtilities
//
//  Created by Gavin Eadie on 3/18/25.
//

import Foundation
import SatelliteKit


/// Creates an `ElementGroup` from a link to a TLE file ..
/// - Parameters:
///   - tlesLink: the link to the network TLE file
///   - named: a name for the group
///   - store: where/whether to cache the downloaded elements (default: nil)
public func downloadTLEs(_ tlesLink: String,
                         named: String,
                         store: ElementsStore? = nil) async -> ElementsGroup? {
    storeLogger.notice("•  Group.TLE ← \(tlesLink, privacy: .public)")
    guard let url = URL(string: tlesLink) else { return nil }

    let (elements, date) = await fetchFrom(url)
    let group = ElementsGroup(tlesData(elements),
                              named: named,
                              dated: date ?? Date())
    if let store { store.insertElements(group, named: named) }

    return group

    func tlesData(_ data: Data) -> [Elements] {
        parseData(data) { rawData in
            try preProcessTLEs(String(data: rawData, encoding: .utf8)!)
                .map { try Elements($0.0, $0.1, $0.2) }
        } ?? []
    }
}


/// Creates an `ElementGroup` from a link to a JSON text file ..
/// - Parameters:
///   - jsonLink: the URL where the satellite JSON TLEs will be found
///   - named: a name for the group
///   - store: where/whether to cache the downloaded elements (default: nil)
public func downloadJSON(_ jsonLink: String,
                         named: String,
                         store: ElementsStore? = nil) async -> ElementsGroup? {
    storeLogger.notice("•  Group.JSN ← \(jsonLink, privacy: .public)")
    guard let url = URL(string: jsonLink) else { return nil }

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


/// Creates an `ElementGroup` from a link to a XML text file ..
/// - Parameters:
///   - xmlLink: the URL where the satellite XML TLEs will be found
///   - named: a name for the group
///   - store: where/whether to cache the downloaded elements (default: nil)
public func downloadXMLs(_ xmlLink: String,
                         named: String,
                         store: ElementsStore? = nil) async -> ElementsGroup? {
    storeLogger.notice("•  Group.XML ← \(xmlLink, privacy: .public)")
    guard let url = URL(string: xmlLink) else { return nil }

    let (elements, date) = await fetchFrom(url)
    let group = ElementsGroup(xmlData(elements),
                              named: named,
                              dated: date ?? Date())
    if let store { store.insertElements(group, named: named) }

    return group

    func xmlData(_ data: Data) -> [Elements] {
        parseData(data) { rawData in
            let string = String(data: rawData, encoding: .utf8)!
            let stringArray = string.components(separatedBy: "</body>")
                .compactMap { $0.components(separatedBy: "<body>").last }

            return stringArray.dropLast().map { Elements(xmlData: $0.data(using: .utf8)!) }
        } ?? []
    }
}


/// Creates an `ElementGroup` from a link to a CSV text file ..
/// - Parameters:
///   - csvLink: the URL where the satellite XML TLEs will be found
///   - named: a name for the group
///   - store: where/whether to cache the downloaded elements (default: nil)
public func downloadCSVs(_ csvLink: String,
                         named: String,
                         store: ElementsStore? = nil) async -> ElementsGroup? {
    storeLogger.notice("•  Group.CSV ← \(csvLink, privacy: .public)")
    guard let url = URL(string: csvLink) else { return nil }

    let (elements, date) = await fetchFrom(url)
    let group = ElementsGroup(csvData(elements),
                              named: named,
                              dated: date ?? Date())
    if let store { store.insertElements(group, named: named) }

    return group

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
}

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
