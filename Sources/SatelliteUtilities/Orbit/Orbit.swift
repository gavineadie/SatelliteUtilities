/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ Orbit.swift                                                                   SatelliteUtilities ║
  ║ Created by Mathis Gaignet on Mars27/25  Copyright © 2025 Ramsay Consulting. All rights reserved. ║
  ║──────────────────────────────────────────────────────────────────────────────────────────────────║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import SatelliteKit
import CoreLocation

public struct Orbit {
    
/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ Return satellite's orbit path to use it on a map (like MapKit)                                   │
  │ Most of observable satellite are in low earth orbit, which means they complete an orbit in       │
  │ roughly 90 minutes. However, if we need to track satellites in higher orbits; especially         │
  │ those that require the SDP4 model; it's also possible to extend the prediction duration          │
  │ accordingly.                                                                                     │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    
    public static func calculateOrbitPaths(for satellite: Satellite) throws -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        do {
            let startDate = Date()
            for minute in 0...90 {
                let futureDate = startDate.addingTimeInterval(Double(minute) * 60)
                let position = try satellite.geoPosition(julianDays: futureDate.julianDate)
                let coordinate = CLLocationCoordinate2D(
                    latitude: position.lat,
                    longitude: position.lon - floor((position.lon + 180) / 360) * 360
                )
                coordinates.append(coordinate)
            }
            return coordinates
        } catch {
            throw Errors.orbitPath
        }
    }
}
