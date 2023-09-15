class VersionParser {
    static _modifierRegex := "[._-]?(?:(stable|beta|b|RC|alpha|a|patch|pl|p)((?:[.-]?\d+)*+)?)?([.-]?dev)?"
    static _stabilitiesRegex := "stable|RC|beta|alpha|dev"

    static ParseStability(version) {
        version := RegexReplace(version, "{#.+$}")

        if (SubStr(version, 1, 4) == "dev-" || SubStr(version, -4) == "-dev") {
            return "dev"
        }

        if (RegExMatch(StrLower(version), "i)" . this._modifierRegex . "'(?:\+.*)?$", &match)) {
            if (match.Count >= 3 && match[3]) {
                return "dev"
            }

            if (match.Count >= 1 && match[1]) {
                if (match[1] == "beta" || match[1] == "b") {
                    return "beta"
                }

                if (match[1] == "alpha" || match[1] == "a") {
                    return "alpha"
                }

                if (match[1] == "rc") {
                    return "RC"
                }
            }
        }

        return "stable"
    }

    static NormalizeStability(stability) {
        stability := StrLower(stability)
        return stability == "rc" ? "RC" : stability
    }

    Normalize(version, fullVersion := "") {
        version := Trim(version)
        origVersion := version
        index := ""

        if (fullVersion == "") {
            fullVersion := version
        }

        ; Strip off aliasing
        if (RegExMatch(version, "^([^,\s]++) ++as ++([^,\s]++)$", &match)) {
            version := match[1]
        }

        ; Strip off stability flag
        if (RegExMatch(version, "'{@(?:" . this.Prototype._stabilitiesRegex . ")$}i", &match)) {
            version := SubStr(version, 1, StrLen(version) - StrLen(match[0]))
        }

        ; If requirement is branch-like, use the full name
        if ("'i)^dev-" ~= version) {
            return "dev-" . version
        }

        ; Strip off build metadata
        if (RegExMatch(version, "^([^,\s+]++)\+[^\s]++$", &match)) {
            version := match[1]
        }

        ; Match classical versioning
        if (RegExMatch(version, "i)^v?(\d{1,5})(\.\d++)?(\.\d++)?(\.\d++)?" . this.Prototype._modifierRegex . "$", &matches)) {
            version := matches[1] .
                (matches[2] ? matches[2] : ".0") .
                (matches[3] ? matches[3] : ".0") .
                (matches[4] ? matches[4] : ".0")
            index := 5
        } else if (RegExMatch(version, "i)^v?(\d{4}(?:[.:-]?\d{2}){1,6}(?:[.:-]?\d{1,3})?)" . this.Prototype._modifierRegex . "$", &match)) {
            version := RegExReplace(matches[1], "{\D}", ".")
            index := 2
        }

        ; Add version modifiers if a version was matches
        if (index != "") {
            if (matches.Cound >= index) {
                if (matches[index] == "stable") {
                    return version
                }

                version .= "-" . this._ExpandStability(matches[index]) . (matches.Count >= index + 1 && matches[index + 1] ?
                    LTrim(matches[index + 1], ".-") :
                    "")
            }

            if (matches.Count >= index + 2 && matches[index + 2]) {
                version .= "-dev"
            }

            return version
        }

        ; Match dev branches
        if (RegExMatch(version, "i)(.*?)[.-]?dev$", &match)) {
            try {
                normalized := this.NormalizeBranch(match[1])
                if (SubStr(normalized, 1, 4) != "dev-") {
                    return normalized
                }
            } catch Any {
                ; Ignore errors when normalizing
            }
        }

        extraMessage := ""
        ; TODO: Add extra information e.g. https://github.com/composer/semver/blob/fa1ec24f0ab1efe642671ec15c51a3ab879f59bf/src/VersionParser.php#L179

        throw DataException("Invalid version string '" . origVersion . "'" . extraMessage)
    }

    ParseNumericAliasPrefix(branch) {
        if (RegExMatch(branch, "i)^(?P<version>(\d++\\.)*\d++)(?:\.x)?-dev$", &matches)) {
            return matches["version"] . "."
        }

        return ""
    }

    NormalizeBranch(name) {
        name := Trim(name)

        if (RegExMatch(name, "i)^v?(\d++)(\.(?:\d++|[xX*]))?(\.(?:\d++|[xX*]))?(\.(?:\d++|[xX*]))?$", &matches)) {
            version := ""
            numMatches := matches.Count

            Loop 4 {
                version .= numMatches >= A_Index ? StrReplace(matches[A_Index], ["*", "X"], "x") : ".x"
            }

            return StrReplace(version, "x", "9999999") . "-dev"
        }

        return "dev-" . name
    }

    ParseConstraints(constraints) {
        prettyConstraints := String(constraints)

        orConstraints := RegExp.Split(Trim(String(constraints)), "\s*\|\|?\s*")

        if (orConstraints.Length == 0) {
            throw DataException("Could not parse version constraint '" . prettyConstraints . "'")
        }

        orGroups := []

        for , orConstraint in orConstraints {
            andConstraints := RegExp.Split(orConstraint, "(?<!^|as|[=>< ,]) *(?<!-)[, ](?!-) *(?!,|as|$)")

            if (andConstraints.Length == 0) {
                throw DataException("Could not parse version constraint '" . prettyConstraints . "'")
            }

            constraintObjects := []

            if (andConstraints.Length > 1) {
                for , andConstraint in andConstraints {
                    for , parsedAndConstraint in this._ParseConstraint(andConstraint) {
                        constraintObjects.Push(parsedAndConstraint)
                    }
                }
            } else {
                constraintObjects := this._ParseConstraint(andConstraints[1])
            }

            if (constraintObjects.Length == 1) {
                constraint := constraintObjects[1]
            } else {
                constraint := MultiVersionConstraint(constraintObjects)
            }

            orGroups.Push(constraint)
        }

        parsedConstraint := MultiVersionConstraint.Create(orGroups, false)
        parsedConstraint.PrettyString := prettyConstraints

        return parsedConstraint
    }

    _ParseConstraint(constraint) {
        stabilityModifier := ""

        ; Strip off aliasing
        if (RegExMatch(constraint, "^([^,\s]++) ++as ++([^,\s]++)$", &match)) {
            constraint := match[1]
        }

        ; Strip off stability flag and store it
        if (RegExMatch(constraint, "i)^([^,\s]*?)@(" . this.Prototype._stabilitiesRegex . ")$", &match)) {
            constraint := match[1] != "" ? match[1] : "*"

            if (match[2] != "stable") {
                stabilityModifier := match[2]
            }
        }

        ; Strip off #refs since they aren't useful for version parsing
        if (RegExMatch(constraint, "i)^(dev-[^,\s@]+?|[^,\s@]+?\.x-dev)#.+$", &match)) {
            constraint := match[1]
        }

        if (RegExMatch(constraint, "i)^(v)?[xX*](\.[xX*])*$", &match)) {
            if (match[1] != "" && match[2] != "") {
                return [SimpleVersionConstraint(">=", "0.0.0.0-dev")]
            }

            return [MatchAllConstraint()]
        }

        versionRegex := "v?(\d++)(?:\.(\d++))?(?:\.(\d++))?(?:\.(\d++))?(?:" . this.Prototype._modifierRegex . "|\.([xX*][.-]?dev))(?:\+[^\s]+)?"

        ; Convert tilde range to >= match if a stability suffix is added to the constraint
        if (RegExMatch(constraint, "i)^~>?" . versionRegex . "$", &matches)) {
            if (SubStr(constraint, 1, 2) == "~>") {
                throw DataException("Could not parse version constraint '" . constraint . "': Invalid operator '~>'")
            }

            position := 1

            if (matches.Count >= 4 && matches[4] != "") {
                position := 4
            } else if (matches.Count >= 3 && matches[3] != "") {
                position := 3
            } else if (matches.Count >= 2 && matches[2] != "") {
                position := 2
            }

            ; Shift the second or third number for 2.x-dev or 3.0.x-dev versions
            if (matches.Count >= 8 && matches[8]) {
                position++
            }

            ; Calculate stability suffix
            stabilitySuffix := ""

            if (
                (matches.Count < 5 || !matches[5]) &&
                (matches.Count < 7 || !matches[7]) &&
                (matches.Count < 8 || !matches[8])
            ) {
                stabilitySuffix .= "-dev"
            }

            lowVersion := this.Normalize(SubStr(constraint . stabilitySuffix, 1))
            lowerBound := SimpleVersionConstraint(">=", lowVersion)

            highPosition := Max(1, position - 1)
            highVersion := this._ManipulateVersionString(matches, highPosition, 1) . "-dev"
            upperBound := SimpleVersionConstraint("<", highVersion)

            return [lowerBound, upperBound]
        }

        ; Match caret range
        if (RegExMatch(constraint, "i)^\^" . versionRegex . "($)", &matches)) {
            position := 3

            if ((matches.Count < 1 || matches[1] != "0") || (matches.Count < 2 || matches[2] == "")) {
                position := 1
            } else if ((matches.Count < 2 || matches[2] != "0") || (matches.Count < 3 || matches[3] == "")) {
                position := 2
            }

            stabilitySuffix := ""

            if (
                (matches.Count < 5 || !matches[5]) &&
                (matches.Count < 7 || !matches[7]) &&
                (matches.Count < 8 || !matches[8])
            ) {
                stabilitySuffix .= "-dev"
            }

            lowVersion := this.Normalize(SubStr(constraint . stabilitySuffix, 1))
            lowerBound := SimpleVersionConstraint(">=", lowVersion)

            highVersion := this._ManipulateVersionString(matches, position, 1) . "-dev"
            upperBound := SimpleVersionConstraint("<", highVersion)

            return [lowerBound, upperBound]
        }

        ; X range
        if (RegExMatch(constraint, "^v?(\d++)(?:\.(\d++))?(?:\.(\d++))?(?:\.[xX*])++$", &matches)) {
            position := 1

            if (matches.Count >= 3 && matches[3] != "") {
                position := 3
            } else if (matches.Count >= 2 && matches[2] != "") {
                position := 2
            }

            lowVersion := this._ManipulateVersionString(matches, position) . "-dev"
            highVersion := this._ManipulateVersionString(matches, position, 1) . "-dev"

            if (lowVersion == "0.0.0.0-dev") {
                return [SimpleVersionConstraint("<", highVersion)]
            }

            return [
                SimpleVersionConstraint(">=", lowVersion),
                SimpleVersionConstraint("<", highVersion)
            ]
        }

        ; Hyphen range
        if (RegExMatch(constraint, "i)^(?P<from>" . versionRegex . ") +- +(?P<to>" . versionRegex . ")($)", &matches)) {
            lowStabilitySuffix := ""

            if (
                (matches.Count < 6 || !matches[6]) &&
                (matches.Count < 8 || !matches[8]) &&
                (matches.Count < 9 || !matches[9])
            ) {
                lowStabilitySuffix .= "-dev"
            }

            lowVersion := this.Normalize(matches["from"])
            lowerBound := SimpleVersionConstraint(">=", lowVersion . lowStabilitySuffix)

            if (
                (matches.Count >= 12 && matches[12] && matches.Count >= 13 && matches[13]) ||
                (
                    (matches.Count >= 15 && matches[15]) ||
                    (matches.Count >= 17 && matches[17]) ||
                    (matches.Count >= 18 && matches[18])
                )
            ) {
                highVersion := this.Normalize(matches["to"])
                upperBound := SimpleVersionConstraint("<=", highVersion)
            } else {
                highMatch := [
                    "",
                    (matches.Count >= 11 ? matches[11] : ""),
                    (matches.Count >= 12 ? matches[12] : ""),
                    (matches.Count >= 13 ? matches[13] : ""),
                    (matches.Count >= 14 ? matches[14] : "")
                ]

                ; Validate valid to version
                this.Normalize(matches["to"])

                highVersion := this._ManipulateVersionString(highMatch, (matches.Count < 12 || !matches[12]) ? 1 : 2, 1) . "-dev"
                upperBound := SimpleVersionConstraint("<", highVersion)
            }

            return [lowerBound, upperBound]
        }

        ; Parsing hasn't failed yet, but if there is an exception here it needs to append to the failure message.
        message := "Could not parse version constraint " . constraint

        ; Basic comparators
        if (RegExMatch(constraint, "^(<>|!=|>=?|<=?|==?)?\s*(.*)", &matches)) {
            try {
                try {
                    version := this.Normalize(matches[2])
                } catch DataException as ex {
                    ; Recover from an invalid constraint if possible
                    if (SubStr(matches[2], -4) == "-dev" && matches[2] ~= "^[0-9a-zA-Z-./]+$") {
                        version := this.Normalize("dev-" . SubStr(matches[2], 0, -4))
                    } else {
                        throw ex
                    }
                }

                op := matches[1] ? matches[1] : "="

                if (op != "==" && op != "=" && stabilityModifier && this.Prototype.ParseStability(version) == "stable") {
                    version .= "-" . stabilityModifier
                } else if (op == "<" || op == ">=") {
                    if (!StrLower(matches[2]) ~= "/-" . this.Prototype._modifierRegex . "$/") {
                        if (SubStr(matches[2], 0, 4) != "dev-") {
                            version .= "-dev"
                        }
                    }
                }

                return [SimpleVersionConstraint(matches[1] ? matches[1] : "=", version)]
            } catch Any as ex {
                message .= ": " . ex.Message
            }
        }

        throw DataException(message)
    }

    _ManipulateVersionString(matches, position, increment := 0, pad := "0") {
        index := 4

        Loop 4 {
            if (position > index) {
                matches[index] := pad
            } else if (position == index && increment) {
                matches[index] += increment

                if (matches[index] < 0) {
                    matches[index] := pad
                    --position

                    if (index == 1) {
                        return ""
                    }
                }
            }
        }

        return matches[1] . "." . matches[2] . "." . matches[3] . "." . matches[4]
    }

    _ExpandStability(stability) {
        stability := StrLower(stability)

        switch (stability) {
            case "a":
                return "alpha"
            case "b":
                return "beta"
            case "p", "pl":
                return "patch"
            case "rc":
                return "RC"
            default:
                return stability
        }
    }
}
