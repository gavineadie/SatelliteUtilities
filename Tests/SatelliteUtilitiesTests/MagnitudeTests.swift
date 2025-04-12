/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ MagnitudeTests.swift                                                                             ║
  ║                                                                                                  ║
  ║ Created by Mathis Gaignet on Mar27/25  Copyright 2022-25 Ramsay Consulting. All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import Testing
import SatelliteKit
@testable import SatelliteUtilities

struct MagnitudeTests {
    
    @MainActor @Test
    func calculateMagnitudeTest_ShouldReturnAverageMagnitude() throws {
        let TLE = (
            line0: "",
            line1: "1 25544U 98067A   25086.17192136  .00035516  00000+0  62421-3 0  9998",
            line2: "2 25544  51.6371 353.2392 0003699  54.8873 305.2462 15.50144996502445"
        )
        let elements = try Elements(TLE.0, TLE.1, TLE.2)
        let satellite = Satellite(elements: elements)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Pacific/Auckland")
//        let riseTime = dateFormatter.date(from: "2025-03-28T20:12:28")!
        let maxTime = dateFormatter.date(from: "2025-04-05T06:40:48")!
//        let setTime = dateFormatter.date(from: "2025-03-28T20:21:13")!
        
        let latLonAlt = LatLonAlt(-36.8521, 174.7632, 0)
            
        let magnitude = try Magnitude.calculateMagnitudeAtDate(satellite: satellite, date: maxTime, observer: latLonAlt)
        
        #expect(magnitude < -2.8)

    }
}
