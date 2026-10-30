// Fictional equipment purchased and commissioned 2026-04-01.
entity {
    use alias demo_equipment
    unit camera {
        details { Synthetic camera fixture; not a real asset. }
        profile {
            acquisition {
                date { year = 2026 month = 4 day = 1 }
                entry = 9950
                account = BMvaMeiAkpIna
                valuation { acquisition_cost { direct = 1200.00 indirect = 0.00 } }
            }
            commission_date { year = 2026 month = 4 day = 1 }
        }
        depreciation {
            method = sl
            useful_life_years = 4
            residual_percent = 20
            account = WAfsAmvMei
            contra = BMvaMeiCaeAfs
        }
    }
}
