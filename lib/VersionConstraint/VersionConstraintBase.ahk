class VersionConstraintBase {
    _prettyString := ""

    PrettyString {
        get {
            if (this._prettyString != "") {
                return this._prettyString
            }

            return String(this)
        }

        set {
            this._prettyString = value
        }
    }

    Matches(provider) {
        throw MethodNotImplementedException("VersionConstraintBase", "Matches")
    }

    GetUpperBound() {
        throw MethodNotImplementedException("VersionConstraintBase", "GetUpperBound")
    }

    GetLowerBound() {
        throw MethodNotImplementedException("VersionConstraintBase", "GetLowerBound")
    }

    ToString() {
        throw MethodNotImplementedException("VersionConstraintBase", "ToString")
    }
}
