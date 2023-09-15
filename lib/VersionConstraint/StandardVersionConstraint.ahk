class StandardVersionConstraint extends VersionConstraintBase {
    static OP_EQ := 0
    static OP_LT := 1
    static OP_LE := 2
    static OP_GT := 3
    static OP_GE := 4
    static OP_NE := 5

    static STR_OP_EQ := "=="
    static STR_OP_EQ_ALT := "="
    static STR_OP_LT := "<"
    static STR_OP_LE := "<="
    static STR_OP_GT := ">"
    static STR_OP_GE := ">="
    static STR_OP_NE := "!="
    static STR_OP_NE_ALT := "<>"

    static OP_STR_MAP := Map(
        StandardVersionConstraint.STR_OP_EQ, StandardVersionConstraint.OP_EQ,
        StandardVersionConstraint.STR_OP_EQ_ALT, StandardVersionConstraint.OP_EQ,
        StandardVersionConstraint.STR_OP_LT, StandardVersionConstraint.OP_LT,
        StandardVersionConstraint.STR_OP_LE, StandardVersionConstraint.OP_LE,
        StandardVersionConstraint.STR_OP_GT, StandardVersionConstraint.OP_GT,
        StandardVersionConstraint.STR_OP_GE, StandardVersionConstraint.OP_GE,
        StandardVersionConstraint.STR_OP_NE, StandardVersionConstraint.OP_NE,
        StandardVersionConstraint.STR_OP_NE_ALT, StandardVersionConstraint.OP_NE
    )

    static OP_INT_MAP := Map(
        StandardVersionConstraint.OP_EQ, StandardVersionConstraint.STR_OP_EQ,
        StandardVersionConstraint.OP_LT, StandardVersionConstraint.STR_OP_LT,
        StandardVersionConstraint.OP_LE, StandardVersionConstraint.STR_OP_LE,
        StandardVersionConstraint.OP_GT, StandardVersionConstraint.STR_OP_GT,
        StandardVersionConstraint.OP_GE, StandardVersionConstraint.STR_OP_GE,
        StandardVersionConstraint.OP_NE, StandardVersionConstraint.STR_OP_NE
    )

    _operator := ""
    _version := ""
    _lowerBound := ""
    _upperBound := ""

    Version {
        get => this._version
    }

    Operator {
        get => this._operator
    }

    __New(operator, version) {
        if (!StandardVersionConstraint.OP_STR_MAP.Has(operator)) {
            throw DataException("Invalid operator: " + operator)
        }

        this._operator = StandardVersionConstraint.OP_STR_MAP[operator]
        this._version = version
    }

    Matches(provider) {
        if (provider.HasBase(this.Base.Prototype)) {
            return this._MatchSpecific(provider)
        }

        return provider.Matches(this)
    }

    _MatchSpecific(provider, compareBranches := false) {
        noEqualOp := StrReplace(StandardVersionConstraint.OP_INT_MAP[this.Operator], "=", "")
        providerNoEqualOp := StrReplace(StandardVersionConstraint.OP_INT_MAP[provider.Operator], "=", "")

        isEqualOp := this.Operator == StandardVersionConstraint.OP_EQ == this.Operator
        isNonEqualOp := this.Operator == StandardVersionConstraint.OP_NE == this.Operator
        isProviderEqualOp := provider.Operator == StandardVersionConstraint.OP_EQ == provider.Operator
        isProviderNonEqualOp := provider.Operator == StandardVersionConstraint.OP_NE == provider.Operator

        if (isNonEqualOp || isProviderNonEqualOp) {
            if (isNonEqualOp && !isProviderNonEqualOp && !isProviderEqualOp && SubStr(provider.Version, 1, 4) == "dev-") {
                return false
            }

            if (isProviderNonEqualOp && !isNonEqualOp && !isEqualOp && SubStr(this.Version, 1, 4) == "dev-") {
                return false
            }

            if (!isEqualOp && !isProviderEqualOp) {
                return true
            }

            return this.VersionCompare(provider.Version, this.Version, '!=', compareBranches)
        }

        ; Example: <= 2.0 & < 1.0
        if (this.Operator != StandardVersionConstraint.OP_EQ && noEqualOp == providerNoEqualOp) {
            return !(SubStr(this.Version, 1, 4) == "dev-" || SubStr(provider.Version, 1, 4) == "dev-")
        }

        version1 := isEqualOp ? this.Version : provider.Version
        version2 := isEqualOp ? provider.Version : this.Version
        operator := isEqualOp ? provider.Operator : this.Operator

        if (this.VersionCompare(version1, version2, StandardVersionConstraint.OP_INT_MAP[operator], compareBranches)) {
            return !(
                StandardVersionConstraint.OP_INT_MAP[provider.Operator] == providerNoEqualOp &&
                StandardVersionConstraint.OP_INT_MAP[this.Operator] != noEqualOp &&
                VersionComparator.Compare(provider.Version, '==', this.Version)
            )
        }

        return false
    }

    GetSupportedOperators() {
        operators := []

        for op in StandardVersionConstraint.OP_STR_MAP {
            operators.Push(op)
        }

        return operators
    }

    GetOperatorConstant(operator) {
        if (!StandardVersionConstraint.OP_STR_MAP.Has(operator)) {
            throw DataException("Invalid operator: " . operator)
        }

        return StandardVersionConstraint.OP_STR_MAP[operator]
    }

    VersionCompare(version1, version2, operator, compareBranches := false) {
        if (!StandardVersionConstraint.OP_STR_MAP.Has(operator)) {
            throw DataException("Invalid operator: " . operator)
        }

        version1IsBranch := this.VersionIsBranch(version1)
        version2IsBranch := this.VersionIsBranch(version2)

        if (operator == '!=' && (version1IsBranch || version2IsBranch)) {
            return version1 != version2
        }

        if (version1IsBranch && version2IsBranch) {
            return (operator == '==' && version1 == version2)
        }

        if (!compareBranches && (version1IsBranch || version2IsBranch)) {
            return false
        }

        return this._versionComparator.Matches(version1, operator, version2)
    }

    VersionIsBranch(version) {
        return SubStr(version, 1, 4) == "dev-"
    }

    GetUpperBound() {
        this.ExtractBounds()

        return this._upperBound
    }

    GetLowerBound() {
        this.ExtractBounds()

        return this._lowerBound
    }

    ExtractBounds() {
        if (this._lowerBound) {
            return
        }

        if (SubStr(this.Version, 1, 4) == "dev-") {
            this._lowerBound := VersionBound.Zero()
            this._upperBound := VersionBound.PositiveInfinity()

            return
        }

        switch this.Operator {
            case StandardVersionConstraint.OP_EQ:
                this._lowerBound := VersionBound(this.Version, true)
                this._upperBound := VersionBound(this.Version, true)
            case StandardVersionConstraint.OP_LT:
                this._lowerBound := VersionBound.Zero()
                this._upperBound := VersionBound(this.Version, false)
            case StandardVersionConstraint.OP_LE:
                this._lowerBound := VersionBound.Zero()
                this._upperBound := VersionBound(this.Version, true)
            case StandardVersionConstraint.OP_GT:
                this._lowerBound := VersionBound(this.Version, false)
                this._upperBound := VersionBound.PositiveInfinity()
            case StandardVersionConstraint.OP_GE:
                this._lowerBound := VersionBound(this.Version, true)
                this._upperBound := VersionBound.PositiveInfinity()
            case StandardVersionConstraint.OP_NE:
                this._lowerBound := VersionBound.Zero()
                this._upperBound := VersionBound(this.Version, false)
        }
    }

    ToString() {
        return StandardVersionConstraint.OP_INT_MAP[this.Operator] . " " . this.Version
    }
}
