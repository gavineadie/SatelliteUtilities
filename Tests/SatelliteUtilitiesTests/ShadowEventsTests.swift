/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ ShadowEventsTests.swift                                                                          ║
  ║                                                                                                  ║
  ║ Created by Mathis Gaignet on Mar27/25  Copyright 2022-25 Ramsay Consulting. All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import SatelliteKit
import Testing
import Foundation

@testable import SatelliteUtilities

struct Test {

    
    // Old test results may be outdated
    @Test
    func calculateShadowEventsTest_ShouldReturnCorrectTime() async throws {
        let TLE = (
            line0: "",
            line1: "1 25544U 98067A   25086.17192136  .00035516  00000-0  62421-3 0  9999",
            line2: "2 25544  51.6371 353.2392 0003699  54.8873 305.2462 15.50144996502445"
        )
        let elements = try Elements(TLE.0, TLE.1, TLE.2)
        let satellite = Satellite(elements: elements)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Paris")

        let riseTime = dateFormatter.date(from: "2025-03-30T21:12:40")!
        let setTime = dateFormatter.date(from: "2025-03-30T21:24:00")!
        
        let observer = LatLonAlt(48.8589, 2.32, 0)
        
        let shadowTime = try await ShadowEvents.calculateShadowEvents(
            satellite: satellite,
            riseTime: riseTime,
            setTime: setTime,
            observer: observer
        )
        
        let expectedMin = dateFormatter.date(from: "2025-03-30T21:21:00")!
        let expectedMax = dateFormatter.date(from: "2025-03-30T21:21:30")!
        
        print("shadow time is \(shadowTime)", terminator: "\n")
        
        #expect(shadowTime.entry ?? .now >= expectedMin && shadowTime.exit ?? .now <= expectedMax)

    }

}
