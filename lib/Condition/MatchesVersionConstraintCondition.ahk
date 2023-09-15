class MatchesVersionConstraintCondition extends ConditionBase {
    constraint := ""
    versionSanitizer := ""
    versionComparator := ""

    __New(constraint, versionSanitizer, versionComparator, childConditions := "", negate := false) {
        this.versionSanitizer := versionSanitizer
        this.versionComparator := versionComparator
        this.constraint := this.PreprocessConstraints(constraint)
        super.__New(childConditions, negate)
    }

    PreprocessConstraint(constraint) {
        if (constraint == "") {
            constraint := "*"
        }

        constraint := StrReplace(constraint, " ||", "||")
        constraint := StrReplace(constraint, "|| ", "||")
        constraint := StrReplace(constraint, " -", "-")
        constraint := StrReplace(constraint, "- ", "-")
        constraint := StrReplace(constraint, " ", ",")

        return constraint
    }

    EvaluateCondition(version) {
        orGroups := StrSplit(this.constraint, "||")
        version := this.versionSanitizer.Process(version)

        compatible := false

        for , group in orGroups {
            constraintItems := StrSplit(group, ",")
            andMatch := true

            for , constraintItem in constraintItems {
                if (!this.VersionMatchesConstraint(version, Trim(constraintItem))) {
                    andMatch := false

                    break
                }
            }

            if (andMatch) {
                compatible := true
            }
        }

        return compatible
    }

    VersionMatchesConstraint(version, constraint) {
        compatible := true

        if (constraint != "" && constraint != "*" && constraint != version) {
            minVersion := ""
            minEqual := false
            maxVersion := ""
            maxEqual := false
            notVersion := ""
            newConstraints := []

            if (InStr(constraint, "~") == 1 || InStr(constraint, "^") == 1) {
                op := SubStr(constraint, 1, 1)
                minVersion := SubStr(constraint, 2)
                minEqual := true
                versionArr := StrSplit(constraint, "-")
                suffix := versionArr.Length > 1 ? versionArr[2] : ""
                versionArr := StrSplit(versionArr[1], ".")
                incrementIndex := 1

                if (op == "~") {
                    if (versionArr.Length == 1) {
                        versionArr.Push("0")
                    }

                    incrementIndex := versionArr.Length - 1
                } else if (versionArr[1] == "0") {
                    incrementIndex := versionArr.Length
                }

                versionArr[incrementIndex] += 1

                for , part in versionArr {
                    if (maxVersion) {
                        maxVersion := maxVersion . "."
                    }

                    maxVersion := maxVersion . part
                }

                if (suffix) {
                    maxVersion := maxVersion . "-" . suffix
                }
            } else if (InStr(constraint, ">=") == 1) {
                minVersion := SubStr(constraint, 3)
                minEqual := true
            } else if (InStr(constraint, ">") == 1) {
                minVersion := SubStr(constraint, 2)
            } else if (InStr(constraint, "<=") == 1) {
                maxVersion := SubStr(constraint, 3)
                maxEqual := true
            } else if (InStr(constraint, "<") == 1) {
                maxVersion := SubStr(constraint, 2)
            } else if (InStr(constraint, "!=") == 1) {
                notVersion := SubStr(constraint, 3)
            }

            compareResult := this.versionComparator.Compare(version, minVersion)

            if (newConstraints && compatible) {
                compatible := true

                for , newConstraint in newConstraints {
                    if (!this.VersionMatchesConstraint(version, newConstraint)) {
                        compatible := false
                        break
                    }
                }
            }

            if (notVersion && compatible) {
                compatible := compareResult != 0
            }

            if (minVersion && compatible) {
                compatible := (compareResult == 1 || (minEqual && compareResult == 0))
            }

            if (maxVersion && compatible) {
                compatible := (compareResult == -1 || (maxEqual && compareResult == 0))
            }
        }

        return compatible
    }
}
