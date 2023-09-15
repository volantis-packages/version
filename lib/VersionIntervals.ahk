class VersionIntervals {
    static _intervalsCache := Map()

    static _opSortOrder := Map(
        ">=", -3,
        "<", -2,
        ">", 2,
        "<=", 3
    )

    static Clear() {
        VersionIntervals._intervalsCache := Map()
    }

    static IsSubsetOf(candidate, constraint) {
        if (constraint.HasBase(MatchAllVersionConstraint.Prototype)) {
            return true
        }

        if (candidate.HasBase(MatchNoneVersionConstraint.Prototype) || constraint.HasBase(MatchNoneVersionConstraint.Prototype)) {
            return false
        }

        intersectionIntervals := VersionIntervals.Get(MultiVersionConstraint([candidate, constraint], true))
        candidateIntervals := VersionIntervals.Get(candidate)

        if (intersectionIntervals["numeric"].Length != candidateIntervals["numeric"].Length) {
            return false
        }

        for index, interval in intersectionIntervals["numeric"] {
            if (!candidateIntervals["numeric"].Has(index)) {
                return false
            }

            if (String(candidateIntervals["numeric"][index].Start) != String(interval.Start)) {
                return false
            }

            if (String(candidateIntervals["numeric"][index].End) != String(interval.End)) {
                return false
            }
        }

        if (intersectionIntervals["branches"]["exclude"] != candidateIntervals["branches"]["exclude"]) {
            return false
        }

        if (intersectionIntervals["branches"]["names"].Length != candidateIntervals["branches"]["names"].Length) {
            return false
        }

        for index, name in intersectionIntervals["branches"]["names"] {
            if (!candidateIntervals["branches"]["names"].Has(index)) {
                return false
            }

            if (candidateIntervals["branches"]["names"][index] != name) {
                return false
            }
        }

        return true
    }

    static HaveIntersections(constraint1, constraint2) {
        if (constraint1.HasBase(MatchAllVersionConstraint.Prototype) || constraint2.HasBase(MatchAllVersionConstraint.Prototype)) {
            return true
        }

        if (constraint1.HasBase(MatchNoneVersionConstraint.Prototype) || constraint2.HasBase(MatchNoneVersionConstraint.Prototype)) {
            return false
        }

        intersectionIntervals := VersionIntervals._GenerateIntervals(MultiVersionConstraint([constraint1, constraint2], true))

        return (
            intersectionIntervals["numeric"].Length > 0 ||
            intersectionIntervals["branches"]["exclude"] ||
            intersectionIntervals["branches"]["names"].Length > 0
        )
    }

    static CompactConstraint(constraint) {
        if (!constraint.HasBase(MultiVersionConstraint.Prototype)) {
            return constraint
        }

        intervals := VersionIntervals._GenerateIntervals(constraint)
        constraints := []
        hasNumericMatchAll := false

        if (
            intervals["numeric"].Length == 1 &&
            String(intervals["numeric"][1].Start) == String(VersionInterval.FromZero()) &&
            String(intervals["numeric"][1].End) == String(VersionInterval.UntilPositiveInfinity())
        ) {
            constraints.Push(intervals["numeric"][1].Start)
            hasNumericMatchAll := true
        } else {
            unEqualConstraints := []
            numericCount := intervals["numeric"].Length

            for , interval in intervals["numeric"] {
                if (interval.End.Operator == "<" && (A_Index + 1) < numericCount) {
                    nextInterval := intervals["numeric"][A_Index + 1]

                    if (interval.End.Version == nextInterval.Start.Version && nextInterval.Start.Operator == '>') {
                        if unEqualConstraints.Length == 0 && String(interval.Start) != String(VersionInterval.FromZero()) {
                            unEqualConstraints.Push(interval.Start)
                        }

                        unEqualConstraints.Push(SimpleVersionConstraint("!=", interval.End.Version))
                        continue
                    }
                }

                if (unEqualConstraints.Length > 0) {
                    if (String(interval.End) != String(VersionInterval.UntilPositiveInfinity())) {
                        unEqualConstraints.Push(interval.End)
                    }

                    if (unequalConstraints.Length > 1) {
                        constraints.Push(MultiVersionConstraint(unEqualConstraints, true))
                    } else {
                        constraints.Push(unEqualConstraints[1])
                    }

                    unEqualConstraints := []
                    continue
                }

                if (interval.Start.Version == interval.End.Version && interval.Start.Operator == ">=" && interval.End.Operator == "<=") {
                    constraints.Push(StandardVersionConstraint("==" interval.Start.Version))
                    continue
                }

                if (String(interval.Start) == String(VersionInterval.FromZero())) {
                    constraints.Push(interval.End)
                } else if (String(interval.End) == String(VersionInterval.UntilPositiveInfinity())) {
                    constraints.Push(interval.Start)
                } else {
                    constraints.Push(MultiVersionConstraint([interval.Start, interval.End], true))
                }
            }
        }

        devConstraints := []

        if (intervals["branches"]["names"].Length == 0) {
            if (intervals["branches"]["exclude"]) {
                return MatchAllVersionConstraint()
            }
        } else {
            for , branchName in intervals["branches"]["names"] {
                if (intervals["branches"]["exclude"]) {
                    devConstraints.Push(SimpleVersionConstraint("!=" branchName))
                } else {
                    devConstraints.Push(SimpleVersionConstraint("==" branchName))
                }
            }

            if (intervals["branches"]["exclude"]) {
                if (constraints.Length > 1) {
                    constraints := [MultiVersionConstraint(constraints, false)]

                    for , devConstraint in devConstraints {
                        constraints.Push(devConstraint)
                    }

                    return MultiVersionConstraint(constraints, true)
                }

                if (constraints.Length == 1 && String(constraints[1] == String(VersionInterval.FromZero()))) {
                    if (devConstraints.Length > 1) {
                        return MultiVersionConstraint(devConstraints, true)
                    }

                    return devConstraints[1]
                }

                for , devConstraint in devConstraints {
                    constraints.Push(devConstraint)
                }

                return MultiVersionConstraint(constraints, true)
            }

            for , devConstraint in devConstraints {
                constraints.Push(devConstraint)
            }
        }

        if (constraints.Length > 1) {
            return MultiVersionConstraint(constraints, true)
        }

        if (constraints.Length == 1) {
            return constraints[1]
        }

        return MatchNoneVersionConstraint()
    }

    static Get(constraint) {
        key := String(constraint)

        if (!VersionIntervals._intervalsCache.Has(key)) {
            VersionIntervals._intervalsCache[key] := VersionIntervals._GenerateIntervals(constraint)
        }

        return VersionIntervals._intervalsCache[key]
    }

    static _GenerateIntervals(constraint, stopOnFirstValidInterval := false) {
        if (constraint.HasBase(MatchAllVersionConstraint.Prototype)) {
            return Map(
                "numeric", [VersionInterval(VersionInterval.FromZero(), VersionInterval.UntilPositiveInfinity())],
                "branches", VersionInterval.AnyDev()
            )
        }

        if (constraint.HasBase(MatchNoneVersionConstraint.Prototype)) {
            return Map(
                "numeric", [],
                "branches", VersionInterval.NoDev()
            )
        }

        if (constraint.HasBase(SimpleVersionConstraint.Prototype)) {
            return VersionIntervals._GenerateSingleConstraintIntervals(constraint)
        }

        if (!constraint.HasBase(MultiVersionConstraint.Prototype)) {
            throw DataException("Invalid constraint instance, should be one of MatchAllVersionConstraint, SimpleVersionConstraint or MultiVersionConstraint")
        }

        constraints := constraint.Constraints
        numericGroups := []
        constraintBranches := []

        for innerConstraint in constraints {
            res := VersionIntervals.Get(innerConstraint)
            numericGroups.Push(res["numeric"])
            constraintBranches.Push(res["branches"])
        }

        if (constraint.IsDisjunctive()) {
            branches := VersionInterval.NoDev()

            for , constraintBranch in constraintBranches {
                if (constraintBranch["exclude"]) {
                    if (branches["exclude"]) {
                        branches["names"] := List.Intersect(branches["names"], constraintBranch["names"])
                    } else {
                        branches["exclude"] := true
                        branches["names"] := List.Diff(constraintBranch["names"], branches["names"])
                    }
                } else {
                    if (branches["exclude"]) {
                        branches["names"] := List.Diff(branches["names"], constraintBranch["names"])
                    } else {
                        branches["names"] := List.Merge(branches["names"], constraintBranch["names"], false)
                    }
                }
            }
        } else {
            branches := VersionInterval.AnyDev()

            for , constraintBranch in constraintBranches {
                if (constraintBranch["exclude"]) {
                    if (branches["exclude"]) {
                        branches["names"] := List.Merge(branches["names"], constraintBranch["names"], false)
                    } else {
                        branches["names"] := List.Diff(branches["names"], constraintBranch["names"])
                    }
                } else {
                    if (branches["exclude"]) {
                        branches["names"] := List.Diff(constraintBranch["names"], branches["names"])
                        branches["exclude"] := false
                    } else {
                        branches["names"] := List.Intersect(branches["names"], constraintBranch["names"])
                    }
                }
            }
        }

        branches["names"] := List.Unique(branches["names"])

        if (numericGroups.Length == 1) {
            return Map(
                "numeric", numericGroups[1],
                "branches", branches
            )
        }

        borders := []

        for , group in numericGroups {
            for , interval in group {
                borders.Push(Map(
                    "version", interval.Start.Version,
                    "operator", interval.Start.Operator,
                    "side", "start"
                ))

                borders.Push(Map(
                    "version", interval.End.Version,
                    "operator", interval.End.Operator,
                    "side", "end"
                ))
            }
        }

        opSortOrder := VersionIntervals._opSortOrder
        borders := List.Sort(borders, ObjBindMethod(this, "_BorderCompare"))
        activeIntervals := 0
        intervals := []
        index := 0
        activationThreshold := constraint.IsConjunctive ? numericGroups.Length : 1
        start := ""

        for , border in borders {
            if (border["side"] == "start") {
                activeIntervals++
            } else {
                activeIntervals--
            }

            if (!start && activeIntervals >= activationThreshold) {
                start := SimpleVersionConstraint(border["operator"], border["version"])
            } else if (start && activeIntervals < activationThreshold) {
                if (
                    VersionComparator.Compare(start.Version, "=", border.version) && (
                        (start.Operator == ">" && border["operator"] == "<=") ||
                        (start.Operator == ">=" && border["operator"] == "<")
                    )
                ) {
                    intervals.RemoveAt(index)
                } else {
                    intervals.InsertAt(index, VersionInterval(start, SimpleVersionConstraint(border["operator"], border["version"])))
                    index++

                    if (stopOnFirstValidInterval) {
                        break
                    }
                }

                start := ""
            }
        }

        return Map(
            "numeric", intervals,
            "branches", branches
        )
    }

    static _BorderCompare(value1, value2) {
        order := SimpleVersionSorter.Compare(value1["version"], value2["version"])

        if (order == 0) {
            return this._opSortOrder[value1["operator"]] - this._opSortOrder[value2["operator"]]
        }

        return order
    }

    static GenerateSingleConstraintIntervals(constraint) {
        op := constraint.Operator

        if (SubStr(constraint.Version, 1, 4) == "-dev") {
            intervals := []
            branches := Map(
                "names", [],
                "exclude", false
            )

            if (op == "!=") {
                intervals.Push(VersionInterval(VersionInterval.FromZero(), VersionInterval.UntilPositiveInfinity()))
                branches := Map(
                    "names", [constraint.Version],
                    "exclude", true
                )
            } else if (op == "==") {
                branches["names"].Push(constraint.Version)
            }

            return Map(
                "numeric", intervals,
                "branches", branches
            )
        }

        if (op[1] == ">") {
            return Map(
                "numeric", [VersionInterval(constraint, VersionInterval.UntilPositiveInfinity())],
                "branches", VersionInterval.NoDev()
            )
        }

        if (op[1] == "<") {
            return Map(
                "numeric", [VersionInterval(VersionInterval.FromZero(), constraint)],
                "branches", VersionInterval.NoDev()
            )
        }

        if (op == "!=") {
            return Map(
                "numeric", [
                    VersionInterval(VersionInterval.FromZero(), SimpleVersionConstraint("<", constraint.Version)),
                    VersionInterval(SimpleVersionConstraint(">", constraint.Version), VersionInterval.UntilPositiveInfinity())
                ],
                "branches", VersionInterval.AnyDev()
            )
        }

        return Map(
            "numeric", [VersionInterval(SimpleVersionConstraint(">=", constraint.Version)), Constraint("<=", constraint.Version)],
            "branches", VersionInterval.NoDev()
        )
    }
}
