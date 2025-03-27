/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ Errors.swift                                                                  SatelliteUtilities ║
  ║ Created by Mathis Gaignet on Mar27/25    Copyright 2025 Ramsay Consulting.   All rights reserved.║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation

enum Errors: LocalizedError {
    case intrinsigMagnitudeNotFound
    case areaAndAlbedoNotFound
    case orbitPath
    
    var errorDescription: String? {
        switch self {
        case .intrinsigMagnitudeNotFound:
            return "No intrinsig magnitude found for your satellite"
        case .areaAndAlbedoNotFound:
            return "No area and albedo found for your satellite"
        case .orbitPath:
            return "Couldn't calculate orbit path"
        }
    }
}
