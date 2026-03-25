import Foundation

public enum EntryCompilerToken: Equatable, Sendable {
    case keyword(String)          // entry, for, debit, credit, rm, date, details …
    case ident(String)            // entity, account, people, levi_ouwendijk …
    case number(Decimal)          // 200.00

    case string(String)           // details { … }
    case dateLiteral(String)   // e.g. "2025-02-03" or "03/02/2025"

    // adding enriched semantics:
    case account(String) // account { } / in (Wasdfasdf) {..
    case entity(String) // entity { asdf } / for (owners.levi) {...


    case lBrace                   // {
    case rBrace                   // }
    case lPar                     // (
    case rPar                     // )
    case arrow                    // ->
    case dot                      // .
    case equals                   // =
    case comma                  // , (separations in transactions { ref 1, 2, 3 } block)
    case hash                   // # for entity variants and subvariants
    // case quote                   // "

    case eof
}
