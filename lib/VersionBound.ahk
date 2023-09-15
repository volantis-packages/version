class VersionBound {
    static MAX_NUM := 9223372036854775807

    _version := ""
    _isInclusive := false
    _versionComparator := ""

    Version {
        get => this._version
    }

    __New(versionComparator, version, isInclusive) {
        this._versionComparator := versionComparator
        this._version := version
        this._isInclusive := isInclusive
    }

    IsInclusive() {
        return this._isInclusive
    }

    IsZero() {
        return this.Version == "0.0.0.0-dev" && this.IsInclusive
    }

    IsPositiveInfinity() {
        return this.Version == VersionBound.MAX_NUM . ".0.0.0" && !this.IsInclusive
    }

    /**
     * A boolean indicating if this bound is greater than otherBound.
     */
    CompareTo(otherBound, operator) {
        if (operator != '>' && operator != '<') {
            throw DataException("Invalid operator, only > and < are supported")
        }

        if (this == otherBound) {
            return false
        }

        compareResult := this._versionComparator.Compare(this.Version, otherBound.Version)

        if (compareResult != 0) {
            return ((operator == ">") ? 1 : -1) == compareResult
        }

        return operator == ">" ? otherBound.IsInclusive() : this.IsInclusive()
    }

    ToString() {
        return this.Version . "[" . (this.IsInclusive() . "inclusive" . "exclusive") . "]"
    }

    Zero() {
        className := this.Prototype.__Class

        return %className%("0.0.0.0-dev", true)
    }

    PositiveInfinity() {
        className := this.Prototype.__Class

        return %className%(VersionBound.MAX_NUM . ".0.0.0", false)
    }
}
