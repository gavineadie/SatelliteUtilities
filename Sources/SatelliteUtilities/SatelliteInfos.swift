/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ SatelliteInfos.swift                                                          SatelliteUtilities ║
  ║ Created by Mathis Gaignet on Mars27/25  Copyright © 2025 Ramsay Consulting. All rights reserved. ║
  ║──────────────────────────────────────────────────────────────────────────────────────────────────║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation


/// Basic infos for most common satellites. More can be added.
/// Intrinsic mag is used for the simplified version
/// Area and Albedo are used for the precise version -- it can require some minor adjustments

enum SatelltesInfos: String {
    case iss = "25544"
    case hubble = "20580"
    case tiangong = "48274"
    case bluewalker3 = "53807"
    case solarsail = "59588"
    case envisat = "27386"
    
    
    var intrinsicMag: Double {
        switch self {
        case .iss:
            return -1.8
        case .hubble:
            return 2.2
        case .tiangong:
            return 0.0
        case .bluewalker3:
            return 3.5
        case .solarsail:
            return 2.0
        case .envisat:
            return 3.7
        }
    }
    
    var area: Double {
        switch self {
        case .iss:
            return 0.0025
        case .hubble:
            return 0.00003
        case .tiangong:
            return 0.0007
        case .bluewalker3:
            return 0.000012
        case .solarsail:
            return 0.000015
        case .envisat:
            return 0.0001
        }
    }
    
    var albedo: Double {
        switch self {
        case .iss:
            return 0.4
        case .hubble:
            return 0.35
        case .tiangong:
            return 0.45
        case .bluewalker3:
            return 0.65
        case .solarsail:
            return 0.85
        case .envisat:
            return 0.35
        }
    }

}


