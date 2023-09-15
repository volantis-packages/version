class MatchNoneVersionConstraint extends VersionConstraintBase {
    Matches(provider) {
        return false
    }

    GetUpperBound() {
        return VersionBound("0.0.0.0-dev", false)
    }

    GetLowerBound() {
        return VersionBound("0.0.0.0-dev", false)
    }

    ToString() {
        return "[]"
    }
}
