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

//        XCTAssertEqual(elementsGroup.table.count, 158)
        guard let issElements = elementsGroup.norad(25544)
                                        else { print("no elements with norad# 25544"); return }
        print(issElements.debugDescription())
    }

    func testDownloadTLEs() async {
        var elementsGroup = ElementsGroup()

        print("\n↓↓ \(Date.now)")
        await elementsGroup.downloadTLEs(
            from: "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle", 
            for: "visual-tles-net")
        print("↑↑ \(Date.now)")

//        XCTAssertEqual(elementsGroup.table.count, 158)
        guard let issElements = elementsGroup.norad(25544)
                                        else { print("no elements with norad# 25544"); return }
        print(issElements.debugDescription())

        print(elementsGroup.prettyPrint())
    }

    func testDownloadJSON() async {
        var elementsGroup = ElementsGroup()

        print("\n↓↓ \(Date.now)")
        await elementsGroup.downloadJSON(
            from: "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=json", 
            for: "visual-json-net")
        print("↑↑ \(Date.now)")

//        XCTAssertEqual(elementsGroup.table.count, 158)
        guard let issElements = elementsGroup.norad(25544)
                                        else { print("no elements with norad# 25544"); return }
        print(issElements.debugDescription())
    }

    func testDownloadXMLs() async {
        var elementsGroup = ElementsGroup()

        print("\n↓↓ \(Date.now)")
        await elementsGroup.downloadXMLs(
            from: "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=xml", 
            for: "visual-xml-net")
        print("↑↑ \(Date.now)")

//        XCTAssertEqual(elementsGroup.table.count, 158)
        guard let issElements = elementsGroup.norad(25544)
                                        else { print("no elements with norad# 25544"); return }
        print(issElements.debugDescription())
    }

    func testDownloadCSVs() async {
        var elementsGroup = ElementsGroup()

        print("\n↓↓ \(Date.now)")
        await elementsGroup.downloadCSVs(
            from: "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=csv", 
            for: "visual-csv-net")
        print("↑↑ \(Date.now)")

//        XCTAssertEqual(elementsGroup.table.count, 158)
        print(elementsGroup.prettyPrint())

        guard let issElements = elementsGroup.norad(25544) 
                                        else { print("no elements with norad# 25544"); return }
        print(issElements.debugDescription())
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
