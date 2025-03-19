# SatelliteUtilities
## Beware: under construction .. API will change)

### SatelliteKit

This package requires [`SatelliteKit`](https://github.com/gavineadie/SatelliteKit.git), a library, 
written in Swift, implementing the SGP4/SDP4 earth-orbiting satellite propagation algorithms first 
published in the SpaceTrack Report #3 and later refined by Vallado et al in Revisiting Spacetrack 
Report #3. 

`SatelliteKit` propagates the path of an earth-orbiting satellite based on information provided in
a standard form read from a file or network source.  That provides the satellite's an approximation
of the seven classical orbital elements, plus additional data need to cope with perturbations to 
that classical orbit caused by atmospheric drag.  In `SatelliteKit` these elements are:

```swift
    public let t₀: Double                   // the t=0 epoch time
    public let e₀: Double                   // Eccentricity
    public let i₀: Double                   // Inclination (radians).
    public let ω₀: Double                   // Argument of perigee (radians).
    public let Ω₀: Double                   // Right Ascension of Ascending node (radians).
    public let M₀: Double                   // Mean anomaly (radians).
    public var n₀: Double = 0.0             // Mean motion (radians/min)
```
A `Satellite` is created from these `Elements` and that is what is propagated  by `SatelliteKit`.
___

### SatelliteUtilities

`SatelliteKit` is dedicated to propagation, but more is need to ease its use.

The data for `Elements` is often obtained from the [Celestrak](celestrak.com), a source of such data,
now a website, that had been in operation for forty years.  That data is available for various groups
of satellites in various formats. `SatelliteUtilities` provides ways to access that information and
make it available for in `SatelliteKit`.  

#### ElementsGroup

For example:
```swift
    let elementsGroup = await elementsGroup.downloadTLEs(
        from: "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle", 
        for: "visual-tles-celestrak")
    guard let issElements = elementsGroup.norad(25544)
                                    else { print("no elements with norad# 25544"); . . . }
    print(issElements.debugDescription())
```
A `TLE` (two line element) file from the Celestrak group called "visual" contains elements for the 
100-plus brightest satellites.  The code above:
* creates an `ElementsGroup` to contain multiple `Elements`
* call the `downloadTLEs` function to read the data from the website
* extracts the `Elements` for the International Space Station (Norad ID: 25544)
* prints a summary of the ISS `Elements`
A `Satellite` can be constructed from the `Elements`
```swift
   let issSatellite = Satellite(issElements)
```
and propagated with `SatelliteKit` functions.

#### ElementsGroup

Well behaved applications will not want to reach out to Celestrak every time satellite information
is needed.  First, the Celestrak data is refreshed only a few times a day so it's very unlikely to change over 
minutes or even a few hours and, secondly, Celestrak is a widely used resource and it's only polite
to not hit it more than necessary.

To this end, `SatelliteUtilities` provides a way to keep a local store of download files.
```swift
    let store = ElementsStore()                         
    store.insertElements(elementsGroup,
                         named: "visual-tles-net")        

    let elements = store.extractElements(named: "visual-tles-net")     
```
* creates an `ElementsStore` 
* call the `insertElements` function to write `Elements` into the store
* and reads them back.
