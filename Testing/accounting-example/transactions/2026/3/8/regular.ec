// Fictional transactions (split by year / quarter / month).

transaction {
    id = 7808
    date = 2026-08-05
    source = manual

    amount {
        currency = EUR
        gross = 250.00
    }

    details {
        Before-anchor August income
    }
    status = cleared
}

transaction {
    id = 7809
    date = 2026-08-12
    source = manual

    amount {
        currency = EUR
        gross = 75.00
    }

    details {
        Before-anchor August expense
    }
    status = cleared
}

transaction {
    id = 7810
    date = 2026-08-25
    source = manual

    amount {
        currency = EUR
        gross = 500.00
    }

    details {
        After-anchor August income
    }
    status = cleared
}
