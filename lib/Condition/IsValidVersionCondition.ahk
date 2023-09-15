class IsValidVersionCondition extends ConditionBase {
    version := ""
    versionSanitizer := ""
    pattern := "^(\d+)\.(\d+)\.(\d+)(\-([0-9A-Za-z\-]+\.)*[0-9A-Za-z\-]+)?(\+([0-9A-Za-z\-]+\.)*[0-9A-Za-z\-]+)?$"

    __New(versionSanitizer, childConditions := "", negate := false) {
        this.versionSanitizer := versionSanitizer
        super.__New(childConditions, negate)
    }

    EvaluateCondition(version) {
        version := this.versionSanitizer.Process(version)
        return !!(version ~= this.pattern)
    }
}
