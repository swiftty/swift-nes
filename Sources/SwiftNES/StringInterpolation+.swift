import Foundation

extension DefaultStringInterpolation {
    mutating func appendInterpolation(hex: some BinaryInteger) {
        var hex = String(hex, radix: 16, uppercase: false)
        if !hex.count.isMultiple(of: 2) {
            hex += "0"
        }
        appendInterpolation("0x" + hex)
    }

    mutating func appendInterpolation(bin: some BinaryInteger, digits: Int = 8) {
        var bin = String(bin, radix: 2)
        if case let c = digits - bin.count, c > 0 {
            bin = String(repeating: "0", count: c) + bin
        }
        appendInterpolation("0b" + bin)
    }
}
