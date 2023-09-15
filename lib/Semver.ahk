class Semver {
    static SORT_ASC := 1
    static SORT_DESC := -1
    static _versionParser := ""

    static Satisfies(version, constraints) {
        if (!this._versionParser) {
            this._versionParser = VersionParser()
        }

        provider := StandardVersionConstraint("==", this._versionParser.Normalize(version))

        return this._versionParser
            .ParseConstraints(constraints)
            .Matches(provider)
    }

    static SatisfiedBy(versions, constraints) {
        versions := List.Filter(versions, ObjBindMethod(this, "_SatisfiesCallback", constraints))

        return List.Values(versions)
    }

    static _SatisfiesCallback(constraints, version) {
        return this.Satisfies(version, constraints)
    }

    static Sort(versions) {
        return this.USort(versions, this.SORT_ASC)
    }

    static RSort(versions) {
        return this.USort(versions, this.SORT_DESC)
    }

    static USort(versions, direction) {
        if (!this._versionParser) {
            this._versionParser = VersionParser()
        }

        normalized := []

        for key, version in versions {
            normalizedVersion := this._versionParser.Normalize(version)
            normalizedVersion := this._versionParser.NormalizeDefaultBranch(normalizedVersion)
            normalized.Push([normalizedVersion, key])
        }

        normalized := List.Sort(normalized, ObjBindMethod(this, "_SortCallback", direction))

        sorted := []

        for , item in normalized {
            sorted.Push(versions[item[1]])
        }

        return sorted
    }

    _SortCallback(direction, left, right) {
        if (left[0] == right[0]) {
            return 0
        }

        if VersionComparator.LessThan(left[0], right[0]) {
            return -direction
        }

        return direction
    }
}
