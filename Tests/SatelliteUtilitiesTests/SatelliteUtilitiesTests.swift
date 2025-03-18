import Testing
import SatelliteKit
@testable import SatelliteUtilities

@Suite(.serialized) struct GroupTests {

    @Test mutating func groupCreate() async throws {

        var group = ElementsGroup()
        print(group.prettyPrint())


        do {
            group = try ElementsGroup("elements text")
        } catch {
            print(error.localizedDescription)
        }
        print(group.prettyPrint())


        await group.downloadJSON(
            "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=json",
            named: "brightest.jsn")
        print(group.prettyPrint())

        await group.downloadXMLs(
            "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=xml",
            named: "brightest.xml")
        print(group.prettyPrint())

        await group.downloadTLEs(
            "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle",
            named: "brightest.tle")
        print(group.prettyPrint())

        await group.downloadCSVs(
            "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=csv",
            named: "brightest.csv")
        print(group.prettyPrint())

        let celestrackGroup = try! await fetchFromCelestak()

        print(celestrackGroup.prettyPrint())

        print(celestrackGroup.norad(25544)!.debugDescription())

    }
}

@Suite(.serialized) struct StoreTests {

    let line0 = "AEOLUS"
    let line1 = "1 43600U 18066A   22284.46945825  .00152878  00000+0  58141-3 0  9997"
    let line2 = "2 43600  96.7345 288.3479 0007589 105.2673 254.9439 15.87150682239523"

    @Test mutating func storeCreate() async throws {

        let store = ElementsStore(storeName: "com.ramsaycons.SatelliteUtilities.test")

        print(store.prettyPrint())

        #expect(store.directoryURL.path == "/Users/gavin/Library/Caches/com.ramsaycons.SatelliteUtilities.test")
        #expect(store.storeName == "com.ramsaycons.SatelliteUtilities.test")

    }

    @Test mutating func storeInsert() async throws {

        var group = ElementsGroup()
        let store = ElementsStore(storeName: "com.ramsaycons.SatelliteUtilities.test")

        store.insertElements(groupName: "ZERO", groupJSON: ElementsGroup()) // [Elements(line0, line1, line2)])
        print(store.prettyPrint())

        store.insertElements(groupName: "more", groupJSON: ElementsGroup([try Elements(line0, line1, line2)]))
        print(store.prettyPrint())

        await group.downloadJSON(
            "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=json",
            named: "brightest.jsn",
            store: store)

        group = store.extractElements(groupName: "more")
        print(group.prettyPrint())

        print(store.prettyPrint())

        store.deleteElements(groupName: "test")

        print(store.prettyPrint())

    }
}
