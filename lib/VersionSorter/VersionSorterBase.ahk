class VersionSorterBase {
    static Sort(versions) {
        List.Sort(versions, ObjBindMethod(this, "Compare"))
    }

    static IsOutdated(versionToCheck, latestVersion) {
        return this.Compare(versionToCheck, latestVersion) < 0
    }

    static Compare(version1, version2) {
        throw MethodNotImplementedException("VersionSorterBase", "Compare")
    }
}
