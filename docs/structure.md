# Structure:

    (root)/...
        _archive/ -> old implementations (should not be active)

    Sources/Accounting/...
        account-compiler/ -> for account roll up and aggregation
        entry-compiler/ -> for entry compiler parsing and logic
        legacy-sys-migrations/ -> for migrating old legacy system to this library system
        presentations/ -> experimental presentation layer, more or less superseded by projection/
        primitives/ -> type primitives 
        projection/ -> projection layer, dividing balance processing from how it is presented as output
        renderers/ -> rendering outputs for compiled data (html, etc.)
        taxonomy/ -> loading foreign taxonomies (still quite heuristic)
