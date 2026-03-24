import Foundation

extension StatementHTMLRenderer {
    public struct Company: Sendable {
        public var name: String?
        public var legalForm: String?
        public var kvk: String?
        public var rsin: String?
        public var btw: String?
        public var address: Address?
        public var contact: String?

        public init(
            name: String? = nil,
            legalForm: String? = nil,
            kvk: String? = nil,
            rsin: String? = nil,
            btw: String? = nil,
            address: Address? = nil,
            contact: String? = nil
        ) {
            self.name = name
            self.legalForm = legalForm
            self.kvk = kvk
            self.rsin = rsin
            self.btw = btw
            self.address = address
            self.contact = contact
        }

        public init(_ settings: StatementCompanySettings) {
            self.init(
                name: settings.name,
                legalForm: settings.legalForm,
                kvk: settings.kvk,
                rsin: settings.rsin,
                btw: settings.btw,
                address: settings.address.map(StatementHTMLRenderer.Company.Address.init),
                contact: settings.contact
            )
        }

        public struct Address: Sendable {
            public var street: String? = nil
            public var number: String? = nil
            public var areaCode: String? = nil
            public var city: String? = nil
            
            public init(
                street: String? = nil,
                number: String? = nil,
                areaCode: String? = nil,
                city: String? = nil
            ) {
                self.street = street
                self.number = number
                self.areaCode = areaCode
                self.city = city
            }

            public init(_ settings: StatementCompanyAddressSettings) {
                self.init(
                    street: settings.street,
                    number: settings.number,
                    areaCode: settings.areaCode,
                    city: settings.city
                )
            }

            public var string: String {
                if let s = street, let n = number, let ac = areaCode, let c = city {
                    return "\(s) \(n)\n\(ac)\n\(c)"
                } else {
                    return ""
                }
            }

            public var stringNoReturn: String {
                if let s = street, let n = number, let ac = areaCode, let c = city {
                    return "\(s) \(n), \(ac) \(c)"
                } else {
                    return ""
                }
            }
        }
    }
}
