class VersionSanitizerTest extends TestBase {
    versionSanitizerInstance := ""

    CreateTestInstances() {
        this.versionSanitizerInstance := VersionSanitizer()
    }

    TestProcessSingleValue() {
        upperVersion := "9999.9999.9999"

        this.AssertEquals(
            this.versionSanitizerInstance.Process("0.0.0.0"),
            upperVersion,
            "0.0.0.0 should filter to " . upperVersion
        )

        this.AssertEquals(
            this.versionSanitizerInstance.Process("0.0.0.0"),
            upperVersion,
            "{{VERSION}} should filter to " . upperVersion
        )

        for , version in [
            "1.2.3.4",
            "0.1-beta1",
            "99",
            "1",
            "0",
            "24.1.5.6.0.4.23"
        ] {
            this.AssertEquals(
                this.versionSanitizerInstance.Process(version),
                version,
                version . " should filter to itself"
            )
        }
    }
}
