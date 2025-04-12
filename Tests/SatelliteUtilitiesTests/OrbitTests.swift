/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ OrbitTests.swift                                                                                 ║
  ║                                                                                                  ║
  ║ Created by Mathis Gaignet on Mar27/25  Copyright 2022-25 Ramsay Consulting. All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Testing
import Foundation
import SatelliteKit
import CoreLocation
@testable import SatelliteUtilities


struct OrbitTests {
    
    @Test
    func calculateOrbitPath_ShouldReturnPath() throws {
        let TLE = (
            line0: "",
            line1: "1 25544U 98067A   25086.17192136  .00035516  00000+0  62421-3 0  9998",
            line2: "2 25544  51.6371 353.2392 0003699  54.8873 305.2462 15.50144996502445"
        )
        let elements = try Elements(TLE.0, TLE.1, TLE.2)
        let satellite = Satellite(elements: elements)
        
        let path = try Orbit.calculateOrbitPaths(for: satellite)
        
        
        #expect(path.allSatisfy { $0.longitude >= -180.0 && $0.longitude <= 180.0 })

    }
}
