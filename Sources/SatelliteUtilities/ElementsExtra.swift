/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ ElementsExtra.swift                                                           SatelliteUtilities ║
  ║ Created by Gavin Eadie on Mar16/25  ...  Copyright 2025 Ramsay Consulting.  All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import SatelliteKit

func fetchFromCelestak(group: String = "visual",
                       format: String = "json") async throws -> ElementsGroup {

    guard let celestrakURL = URL(string:
                    "https://celestrak.org/NORAD/elements/gp.php?GROUP=\(group)&FORMAT=\(format)")
    else { fatalError("Celestrak URL failure ..") }

    let (data, response) = try await URLSession.shared.data(for: URLRequest(url: celestrakURL))

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ Note: Celestrak seems to respond with a "200" http status regardless of what's thrown at it!     │
  │       There's some logic to this if the response data is an error message, but would a "4xx"     │
  │       response be more appropriate?  Since the http request is generated programmatically, it    │
  │       is much less likely to cause errors, so catching any here is rudimentary ..                │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else { fatalError("Celestrak response failure ..") }

    let dataType = httpResponse.value(forHTTPHeaderField: "Content-Type")!.split(separator: "/")
    guard dataType.count > 1 else { fatalError("Celestrak Content-Type '\(dataType[0])' failure ..") }

    var elementsArray = [Elements]()

    if dataType[1].starts(with: "json") {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
        elementsArray = try decoder.decode([Elements].self, from: data)
    } else if dataType[1].starts(with: "xml") {
        var stringArray = String(data: data, encoding: .utf8)!.components(separatedBy: "</body>")
        stringArray = stringArray.map { $0.components(separatedBy: "<body>").last! }
        elementsArray =  stringArray.dropLast().map { Elements(xmlData: $0.data(using: .utf8)!) }
    } else if dataType[1].starts(with: "csv") {
        // FIXME: needs to be completed
    } else {
        elementsArray =  try preProcessTLEs(String(data: data, encoding: .utf8)!)
            .map { try Elements($0.0, $0.1, $0.2) }
    }

    return ElementsGroup(elementsArray, named: group+format)
}
