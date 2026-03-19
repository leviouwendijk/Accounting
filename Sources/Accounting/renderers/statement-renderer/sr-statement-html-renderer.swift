import Foundation

public enum StatementHTMLRenderer {
    public struct Options: Sendable {
        public var title: String = "Financial Statements"
        public var subtitle: String? = nil  
        public var currencySymbol: String = "€"
        public var minAbsIncome: Decimal = 0
        public var includeOtherBucket: Bool = false
        public var omitIncomeLevel1Root: Bool = true
        public var company: Company? = nil

        public init(
            title: String = "Financial Statements",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            minAbsIncome: Decimal = 0,
            includeOtherBucket: Bool = false,
            omitIncomeLevel1Root: Bool = true,
            company: Company? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.minAbsIncome = minAbsIncome
            self.includeOtherBucket = includeOtherBucket
            self.omitIncomeLevel1Root = omitIncomeLevel1Root
            self.company = company
        }
    }

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
            self.name = name; self.legalForm = legalForm; self.kvk = kvk
            self.rsin = rsin; self.btw = btw; self.address = address; self.contact = contact
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

    @inline(__always)
    static func escape(_ s: String) -> String {
        var out = String()
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(ch)
            }
        }
        return out
    }
}
