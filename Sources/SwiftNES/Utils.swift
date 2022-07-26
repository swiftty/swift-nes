import Foundation

extension OptionSet {
    mutating func toggle(_ value: Element, to flag: Bool) {
        if flag {
            insert(value)
        } else {
            remove(value)
        }
    }
}
