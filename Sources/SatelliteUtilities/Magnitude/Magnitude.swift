/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ Magnitude.swift                                                               SatelliteUtilities ║
  ║ Created by Mathis Gaignet on Mars27/25  Copyright © 2025 Ramsay Consulting. All rights reserved. ║
  ║──────────────────────────────────────────────────────────────────────────────────────────────────║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import Foundation
import SatelliteKit


/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ This formula is a simplified approximation based on the intrinsic magnitude of the satellite.    │
  │ It typically corresponds to a reference altitude around 1000 km and about 50% illumination.      │
  │ Unlike the more precise version, which accounts for albedo, cross-sectional area, and            │
  │ phase angle, this method provides a rough estimate to get a general idea of the                  │
  │ satellite's brightness.                                                                          │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/

//MARK: - SIMPLIFIED VERSION

@available(iOS 13.0.0, *)
public struct Magnitude {
    
    @MainActor
    public static func calculateMagnitudeAtDate(
        satellite: Satellite,
        date: Date,
        observer: LatLonAlt
    ) throws -> Double {
        
        let julianDays = date.julianDate
        let sunPosition = solarCel(julianDays: julianDays)
        let satellitePosition = (try? satellite.position(julianDays: julianDays)) ?? Vector(0.0, 0.0, 0.0)
        let observerPosition = geo2eci(julianDays: julianDays, geodetic: observer)
        let satloc = eci2geo(julianDays: julianDays, celestial: satellitePosition)
        print("sat pos is \(satloc)")
        
        let observerToSatellite = satellitePosition - observerPosition
        let sunToSatellite = satellitePosition - sunPosition
        let phaseAngleRadians = separation(observerToSatellite, sunToSatellite) * deg2rad
        let distanceKm = observerToSatellite.magnitude()
        
        let phaseCorrection = (1 + cos(phaseAngleRadians)) / 2
        let satelliteInfo = SatellitesInfos(rawValue: "\(satellite.noradIdent)")
        guard let intrinsicMag = satelliteInfo?.intrinsicMag else {
            throw Errors.intrinsicMagnitudeNotFound
        }
        print("intrinsic mag is \(intrinsicMag)")
        print("distance km is \(distanceKm)")
        let finalMagnitude = intrinsicMag + 5 * log10(distanceKm / 1000.0) - 2.5 * log10(phaseCorrection)
        
        return finalMagnitude
    }

    
    /// Range version when it's needed to calculate all the magnitude during the satellite's pass
    /// The step interval can be modified

    @MainActor
    public static func calculateMagnitudeRange(
        satellite: Satellite,
        riseTime: Date,
        setTime: Date,
        observer: LatLonAlt
    ) throws -> [ApparentMagnitude] {
        
        let latLonAltCalc = observer
        
        var magnitudeRange = [ApparentMagnitude]()
        
        var currentTime = riseTime
        let endTime = setTime
        let stepInterval: TimeInterval = 60
        
        while currentTime <= endTime {
            let julianDays = currentTime.julianDate
            let sunPosition = solarCel(julianDays: julianDays)
            let satellitePosition = (try? satellite.position(julianDays: julianDays)) ?? Vector(0.0, 0.0, 0.0)
            let observerPosition = geo2eci(julianDays: julianDays, geodetic: latLonAltCalc)
            
            let observerToSatellite = satellitePosition - observerPosition
            let sunToSatellite = satellitePosition - sunPosition
            let phaseAngleRadians = separation(observerToSatellite, sunToSatellite) * deg2rad
            let distanceKm = observerToSatellite.magnitude()
            
            let phaseCorrection = (1 + cos(phaseAngleRadians)) / 2
            let satelliteInfo = SatellitesInfos(rawValue: "\(satellite.noradIdent)")
            guard let intrinsicMag = satelliteInfo?.intrinsicMag else {
                throw Errors.intrinsicMagnitudeNotFound
            }
            let finalMagnitude = intrinsicMag + 5 * log10(distanceKm / 1000.0) - 2.5 * log10(phaseCorrection)
            
            let newApparent = ApparentMagnitude(date: currentTime, magnitude: finalMagnitude)
            magnitudeRange.append(newApparent)
            
            currentTime = currentTime.addingTimeInterval(stepInterval)
        }
        return magnitudeRange
    }
    
    //MARK: - PRECISE VERSION

    /*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
      │ This is the precise method for computing satellite apparent magnitude. It calculates the         │
      │ brightness using the satellite’s cross-sectional area and albedo. This method provides           │
      │ physically meaningful values that take into account lighting                                     │
      │ geometry and surface reflectivity, rather than relying on simplified magnitude presets.          │
      └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
    public static func calculatePreciseMagnitude(satellite: Satellite, observer: LatLonAlt, date: Date) throws -> Double {
        let julianDays = date.julianDate
        let sunPosition = solarCel(julianDays: julianDays)
        let satellitePosition = (try? satellite.position(julianDays: julianDays)) ?? Vector(0, 0, 0)
        let observerPosition = geo2eci(julianDays: julianDays, geodetic: observer)
        
        let observerToSatellite = satellitePosition - observerPosition
        let sunToSatellite = satellitePosition - sunPosition
        let phaseAngleRadians = separation(observerToSatellite, sunToSatellite) * deg2rad
        
        let satelliteInfo = SatellitesInfos(rawValue: "\(satellite.noradIdent)")
        guard let area = satelliteInfo?.area,
              let albedo = satelliteInfo?.albedo else {
            throw Errors.areaAndAlbedoNotFound
        }

        // Phase function F(φ)
        let pi = Double.pi
        let factor = 2.0 / (3.0 * pi * pi)
        let phaseFunction = factor * ((pi - phaseAngleRadians) * cos(phaseAngleRadians) + sin(phaseAngleRadians))

        // Area is supposed to be in square meters but the results only made sense in km2
        let reflectedComponent = area * albedo * phaseFunction
        let distanceKm = observerToSatellite.magnitude()
        print("distance in km to satellite is \(distanceKm)")
        let magnitude = -26.7 - 2.5 * log10(reflectedComponent) + 5.0 * log10(distanceKm)

        return magnitude
    }
}

/// result for the range version

public struct ApparentMagnitude: Identifiable, Hashable, Codable, Sendable {
    public let date: Date?
    public let magnitude: Double?
    
    public var id = UUID()
    
    public init(date: Date?, magnitude: Double?) {
        self.date = date
        self.magnitude = magnitude
    }
}
