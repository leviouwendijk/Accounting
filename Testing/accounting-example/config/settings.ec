settings {
    entry {
        default_timezone = Europe/Amsterdam // utc + 1:00
    }

    statement_data {
        company {
            name = "Example"
            legal_form = "V.O.F."
            kvk = "88888888"
            rsin = nil
            btw = nil

            address {
                street = "Streetline"
                number = "18"
                area_code = "1818 NN"
                city = "Amsterdam"
            }

            contact = "contact@example.nl"
        }

        equity {
            preset = equity_full

            view {
                use alias equity_full

                section { standard }
            }
        }
    }

    aggregation {
        chart {
            find rgs
            version {
                major = 3
                minor = 8
            }
        }
            
        include_previous_periods = true // may deprecate this, due to 'instant' and 'duration'
    }
}
