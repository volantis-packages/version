; TODO: Uncomment and make it work for SimpleVersionSorter
; class SimpleVersionComparatorTest extends TestBase {
;     versionComparatorInstance := ""

;     versionTestData := Map(
;         "older", Map(
;             "0.9.9", "1.0.0",
;             "0.0.1", "0.5",
;             "1.0.0", "2.0.1",
;             "1.9", "2"
;         ),
;         "newer", Map(
;             "1.0.1", "1.0.0",
;             "2.0.0", "0.9.9.9",
;             "0.0.0.0", "99.9",
;             "{{VERSION}}", "1.0"
;         ),
;         "equivalent", Map(
;             "1.0.0", "1.0.0",
;             "1.0", "1.0.0",
;             "{{VERSION}}", "0.0.0.0",
;             "1.5", "1.5.0",
;             "1.5 beta", "1.5.0-beta"
;         )
;     )

;     CreateTestInstances() {
;         versionSanitizer := VersionSanitizer()
;         versionParser := SimpleVersionParser(versionSanitizer)
;         this.versionComparatorInstance := SimpleVersionComparator(versionParser)
;     }

;     IsOutdated() {
;         for installedVersion, latestVersion in this.versionTestData["older"] {
;             this.AssertTrue(
;                 this.versionComparatorInstance.IsOutdated(installedVersion, latestVersion),
;                 installedVersion . " is outdated compared to version " . latestVersion
;             )
;         }

;         for installedVersion, latestVersion in this.versionTestData["newer"] {
;             this.AssertFalse(
;                 this.versionComparatorInstance.IsOutdated(installedVersion, latestVersion),
;                 installedVersion . " is not outdated compared to version " . latestVersion
;             )
;         }

;         for installedVersion, latestVersion in this.versionTestData["equivalent"] {
;             this.AssertFalse(
;                 this.versionComparatorInstance.IsOutdated(installedVersion, latestVersion),
;                 installedVersion . " is not outdated compared to version " . latestVersion
;             )
;         }
;     }

;     TestCompare() {
;         for installedVersion, latestVersion in this.versionTestData["older"] {
;             this.AssertLessThan(
;                 this.versionComparatorInstance.IsOutdated(installedVersion, latestVersion),
;                 0
;             )
;         }

;         for installedVersion, latestVersion in this.versionTestData["newer"] {
;             this.AssertGreaterThan(
;                 this.versionComparatorInstance.IsOutdated(installedVersion, latestVersion),
;                 0
;             )
;         }

;         for installedVersion, latestVersion in this.versionTestData["equivalent"] {
;             this.AssertEquals(
;                 this.versionComparatorInstance.IsOutdated(installedVersion, latestVersion),
;                 0
;             )
;         }
;     }
; }
