class MultiVersionConstraint extends VersionConstraintBase {
    _constraints := ""
    _conjunctive := ""
    _lowerBound := ""
    _upperBound := ""
    _prettyString := ""

    Constraints {
        get => this._constraints
    }

    IsConjunctive {
        get => this._conjunctive
    }

    IsDisjunctive {
        get => !this._conjunctive
    }

    __New(constraints, conjunctive := true) {
        if (constraints.Length < 2) {
            throw DataException("Must provide at least two constraints for a MultiVersionConstraint.")
        }

        this._constraints = constraints
        this._conjunctive = conjunctive
    }

    static Create(constraints, conjunctive := true) {
        if (constraints.Length == 0) {
            return MatchAllVersionConstraint()
        }

        if (constraints.Length == 1) {
            return constraints[1]
        }

        optimized := MultiVersionConstraint.OptimizeConstraints(constraints, conjunctive)

        if (optimized) {
            constraints := optimized[1]
            conjunctive := optimized[2]

            if (constraints.Length == 1) {
                return constraints[1]
            }
        }

        return MultiVersionConstraint(constraints, conjunctive)
    }

    Matches(provider) {
        if (!this.IsConjunctive) {
            for , constraint in this.Constraints {
                if (provider.Matches(constraint)) {
                    return true
                }
            }

            return false
        }

        if (provider.HasBase(MultiVersionConstraint.Prototype) && provider.IsDisjunctive) {
            return provider.Matches(this)
        }

        for , constraint in this.Constraints {
            if (!provider.Matches(constraint)) {
                return false
            }
        }

        return true
    }

    GetUpperBound() {
        this.ExtractBounds()

        if (!this._upperBound) {
            throw DataException("Couldn't properly determine upper bound.")
        }

        return this._upperBound
    }

    GetLowerBound() {
        this.ExtractBounds()

        if (!this._lowerBound) {
            throw DataException("Couldn't properly determine lower bound.")
        }

        return this._lowerBound
    }

    ToString() {
        if (this._prettyString == "") {
            prettyString := "["

            for index, constraint in this.Constraints {
                prettyString .= constraint.ToString()

                if (index != this.Constraints.Length) {
                    prettyString .= this.IsConjunctive ? " " : " || "
                }
            }

            prettyString .= "]"

            this._prettyString := prettyString
        }

        return this._prettyString
    }

    static OptimizeConstraints(constraints, conjunctive) {
        if (!conjunctive) {
            left := constraints[1]
            mergedConstraints := []
            optimized := false

            left0 := left.Constraints[1].ToString()
            left1 := left.Constraints[2].ToString()

            for index, constraint in constraints {
                if (index == 1) {
                    continue
                }

                right := constraints[index]
                right0 := right.Constraints[1].ToString()
                right1 := right.Constraints[2].ToString()

                if (
                    left.HasBase(MultiVersionConstraint.Prototype) &&
                    left.IsConjunctive &&
                    right.HasBase(MultiVersionConstraint.Prototype) &&
                    right.IsConjunctive &&
                    left.Constraints.Length == 2 &&
                    right.Constraints.Length == 2 &&
                    left0 && left0[1] == ">" && left0[2] == "=" &&
                    left1 && left1[1] == "<" &&
                    right0 && right0[1] == ">" && right0[2] == "=" &&
                    right1 && right1[1] == "<" &&
                    SubStr(left1, 2) == SubStr(right0, 3)
                ) {
                    optimized := true
                    left := MultiVersionConstraint([left.Constraints[1], right.Constraints[2]], true)
                } else {
                    mergedConstraints.Push(left)
                    left := right
                }
            }

            if (optimized) {
                mergedConstraints.Push(left)
                return [mergedConstraints, false]
            }
        }

        return false
    }

    ExtractBounds() {
        if (this._lowerBound != "") {
            return
        }

        for , constraint in this.Constraints {
            if (this._lowerBound == "" || this._upperBound == "") {
                this._lowerBound := constraint.GetLowerBound()
                this._upperBound := constraint.GetUpperBound()
                continue
            }

            if (constraint.GetLowerBound().CompareTo(this._lowerBound, this.IsConjunctive ? ">" : "<")) {
                this._lowerBound := constraint.GetLowerBound()
            }

            if (constraint.GetUpperBound().CompareTo(this._upperBound, this.IsConjunctive ? "<" : ">")) {
                this._upperBound := constraint.GetUpperBound()
            }
        }
    }
}
