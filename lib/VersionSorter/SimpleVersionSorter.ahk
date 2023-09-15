class SimpleVersionSorter extends VersionSorterBase {
    static VERSION_MAP := Map(
        "dev", -6,
        "alpha", -5,
        "a", -5,
        "beta", -4,
        "b", -4,
        "RC", -3,
        "rc", -3,
        "#" , -2,
        "p", -1,
        "pl", -1
    )

    static VERSION_NON_NUMERIC := -7
    static VERSION_LOWEST := -8

    static PrepareVersion(version) {
        version := StrReplace(version, "_", ".")
        version := StrReplace(version, "-", ".")
        version := StrReplace(version, "+", ".")
        version := RegExReplace(version, "([^\d\.]+)", ".$1.")
        version := Trim(version, ".")
        version := RegExReplace(version, "\.+", ".")

        if (version == "") {
            return [this.VERSION_LOWEST]
        }

        return StrSplit(version, ".")
    }

    static PartToNumber(versionPart) {
        versionNum := 0

        if (versionPart) {
            if (!IsNumber(versionPart)) {
                if (this.VERSION_MAP.Has(versionPart)) {
                    versionNum := this.VERSION_MAP[versionPart]
                } else {
                    versionNum := this.VERSION_NON_NUMERIC
                }
            } else {
                versionNum := Integer(versionPart)
            }
        }

        return versionNum
    }

    static Compare(version1, version2) {
        version1 := this.PrepareVersion(version1)
        version2 := this.PrepareVersion(version2)
        compare := 0

        Loop Max(version1.Length, version2.Length) {
            val1 := version1.Has(A_Index) ? version1[A_Index] : 0
            val2 := version2.Has(A_Index) ? version2[A_Index] : 0

            if (val1 == val2) {
                continue
            }

            version1[A_Index] := this.PartToNumber(val1)
            version2[A_Index] := this.PartToNumber(val2)

            if (val1 < val2) {
                compare := -1
                break
            } else if (val1 > val2) {
                compare := 1
                break
            }
        }

        return compare
    }
}
