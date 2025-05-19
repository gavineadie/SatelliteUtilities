/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ ElementsGroupTests.swift                                                                         ║
  ║                                                                                                  ║
  ║ Created by Gavin Eadie on Oct12/22     Copyright 2022-25 Ramsay Consulting. All rights reserved. ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

import XCTest
@testable import SatelliteUtilities

class ThreeLineElementTests: XCTestCase {
    
    func testReadText() throws {
        let elementsGroup = try ElementsGroup(tleTestText)
        print(elementsGroup.prettyPrint())
        for elements in Array(elementsGroup.table.values) { print(elements.debugDescription()) }
    }
    
    func testNorad() throws {
        let elementsGroup1 = try ElementsGroup(tleTestText)
        XCTAssertNil(elementsGroup1.norad(0), "elements struct with norad# 0 missing (as it should be)")

        let elementsGroup2 = try ElementsGroup(tleTestText)
        XCTAssertNotNil(elementsGroup2.norad(43641), "elements struct with norad# 43641 missing")

        let elements = elementsGroup2.norad(43641)
        print(elements.debugDescription)
    }

    func testReadFile() throws {
        let elementsTLEs = try String(contentsOfFile: 
                                "/Users/gavin/Library/Application Support/com.ramsaycons.tle/visual.txt")
        let elementsGroup = try ElementsGroup(elementsTLEs)

        guard let issElements = elementsGroup.norad(25544)
                                        else { print("no elements with norad# 25544"); return }
        print(issElements.debugDescription())
    }

    func testDownloadTLEs() async throws {
        if let elementsGroup = await downloadTLEs(
            "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle",
            named: "brightest.tle") {
            guard let issElements = elementsGroup.norad(25544)
                            else { print("no elements with norad# 25544"); return }
            print(issElements.debugDescription())
        }
    }

    func testCelestrakTLE() async {
        do {
            let elementsArray = try await fetchFromCelestak(group: "visual", format: "tle")
            print(elementsArray.prettyPrint())
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    func testCelestrakJSON() async {
        do {
            let elementsArray = try await fetchFromCelestak(group: "visual", format: "json")
            print(elementsArray.prettyPrint())
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    func testCelestrakXML() async {
        do {
            let elementsArray = try await fetchFromCelestak(group: "visual", format: "xml")
            print(elementsArray.prettyPrint())
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    func testCelestrakCSV() async {
        do {
            let elementsArray = try await fetchFromCelestak(group: "visual", format: "csv")
            print(elementsArray.prettyPrint())
        } catch {
            print("\(error.localizedDescription)")
        }
    }
}

let line0 = "AEOLUS"
let line1 = "1 43600U 18066A   22284.46945825  .00152878  00000+0  58141-3 0  9997"
let line2 = "2 43600  96.7345 288.3479 0007589 105.2673 254.9439 15.87150682239523"

let tleTestText = """
        AEOLUS
        1 43600U 18066A   22284.46945825  .00152878  00000+0  58141-3 0  9997
        2 43600  96.7345 288.3479 0007589 105.2673 254.9439 15.87150682239523
        SAOCOM 1A
        1 43641U 18076A   22284.79847383  .00000741  00000+0  99640-4 0  9990
        2 43641  97.8890 109.8412 0001345  85.0542 275.0827 14.82165765216963
        SAOCOM 1B
        1 46265U 20059A   22284.82961417  .00000752  00000+0  10095-3 0  9996
        2 46265  97.8884 108.9320 0001360  82.4383 277.6991 14.82166892114363
        CSS (TIANHE)
        1 48274U 21035A   22284.85984020  .00036888  00000+0  41780-3 0  9995
        2 48274  41.4737 228.0269 0000989  91.3347   0.1704 15.61668898 83017
        """

