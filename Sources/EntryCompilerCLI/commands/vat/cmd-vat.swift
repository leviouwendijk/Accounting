import Arguments

enum VATCommand: ArgumentCommand {
    static let name = "vat"
    static let defaultChild = Overview.self

    static let children: [ArgumentCommandType] = [
        Overview.self,
        Audit.self,
        Status.self,
        Filing.self,
    ]
}
