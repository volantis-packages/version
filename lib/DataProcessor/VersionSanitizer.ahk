class VersionSanitizer extends DataProcessorBase {
    ProcessSingleValue(version) {
        version := StrReplace(version, "-", ".")
        version := StrReplace(version, " ", ".")
        version := RegExReplace(version, "^v([0-9.]+.*)", "$1")

        if (version == "0.0.0.0" || version == "{{VERSION}}") {
            version := "9999.9999.9999"
        }

        return version
    }
}
