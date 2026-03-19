# Structure:

    (root)/...
        _archive/ -> old implementations (should not be active)

    Sources/Accounting/...
        _previous-system-migration/ -> for migrating old legacy system to this library system
        account-compiler/ -> for account roll up and aggregation
        entry-compiler/ -> for entry compiler parsing and logic
        primitives/ -> type primitives 
        renderers/ -> rendering outputs for compiled data (html, etc.)
