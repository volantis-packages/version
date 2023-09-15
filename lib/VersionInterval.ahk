class VersionInterval {
    _start := ""
    _end := ""

    Start {
        get => this._start
    }

    End {
        get => this._end
    }

    __New(startConstraint, endConstraint) {
        this._start = startConstraint
        this._end = endConstraint
    }

    static FromZero() {
        static zeroConstraint := ""

        if (zeroConstraint == "") {
            zeroConstraint := StandardVersionConstraint(">=", "0.0.0.0-dev")
        }

        return zeroConstraint
    }

    static UntilPositiveInfinity() {
        static positiveInfinityConstraint := ""

        if (positiveInfinityConstraint == "") {
            positiveInfinityConstraint := StandardVersionConstraint("<", VersionBound.MAX_NUM . ".0.0.0")
        }

        return positiveInfinityConstraint
    }

    static Any() {
        return VersionInterval(VersionInterval.FromZero(), VersionInterval.UntilPositiveInfinity())
    }

    static AnyDev() {
        return Map(
            "names", [],
            "exclude", true
        )
    }

    static NoDev() {
        return Map(
            "names", [],
            "exclude", false
        )
    }
}
