class MatchAllVersionConstraint extends VersionConstraintBase {
    Matches(provider) {
        return true
    }

    GetUpperBound() {
        return VersionBound.PositiveInfinity()
    }

    GetLowerBound() {
        return VersionBound.Zero()
    }

    ToString() {
        return "*"
    }
}
