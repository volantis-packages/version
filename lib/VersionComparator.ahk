class VersionComparator {
    static GreaterThan(version1, version2) {
        return this.Compare(version1, ">", version2)
    }

    static GreaterThanOrEqualTo(version1, version2) {
        return this.Compare(version1, ">=", version2)
    }

    static LessThan(version1, version2) {
        return this.Compare(version1, "<", version2)
    }

    static LessThanOrEqualTo(version1, version2) {
        return this.Compare(version1, "<=", version2)
    }

    static EqualTo(version1, version2) {
        return this.Compare(version1, "==", version2)
    }

    static NotEqualTo(version1, version2) {
        return this.Compare(version1, "!=", version2)
    }

    static Compare(version1, operator, version2) {
        return StandardVersionConstraint(operator, version2)
            .MatchSpecific(StandardVersionConstraint("==", version1), true)
    }
}
