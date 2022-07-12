import Foundation

extension CPU {
    struct OpCode {
//        var code: UInt8
        var mnemonic: String
        var count: UInt16
        var cycles: UInt8
        var mode: AddressingMode
    }
}

extension CPU.OpCode {
    static let codes: [UInt8: Self] = [
        0x00: .init(mnemonic: "BRK", count: 1, cycles: 7, mode: .none),
        0xaa: .init(mnemonic: "TAX", count: 1, cycles: 2, mode: .none),
        0xe8: .init(mnemonic: "INX", count: 1, cycles: 2, mode: .none),

        0xa9: .init(mnemonic: "LDA", count: 2, cycles: 2, mode: .immediate),
        0xa5: .init(mnemonic: "LDA", count: 2, cycles: 3, mode: .zeroPage),
        0xb5: .init(mnemonic: "LDA", count: 2, cycles: 4, mode: .zeroPageX),
        0xad: .init(mnemonic: "LDA", count: 3, cycles: 4, mode: .absolute),
        0xbd: .init(mnemonic: "LDA", count: 3, cycles: 4, mode: .absoluteX),
        0xb9: .init(mnemonic: "LDA", count: 3, cycles: 4, mode: .absoluteY),
        0xa1: .init(mnemonic: "LDA", count: 2, cycles: 6, mode: .indirectX),
        0xb1: .init(mnemonic: "LDA", count: 2, cycles: 5, mode: .indirectY),

        0x85: .init(mnemonic: "STA", count: 2, cycles: 3, mode: .zeroPage),
        0x95: .init(mnemonic: "STA", count: 2, cycles: 4, mode: .zeroPageX),
        0x8d: .init(mnemonic: "STA", count: 3, cycles: 4, mode: .absolute),
        0x9d: .init(mnemonic: "STA", count: 3, cycles: 5, mode: .absoluteX),
        0x99: .init(mnemonic: "STA", count: 3, cycles: 5, mode: .absoluteY),
        0x81: .init(mnemonic: "STA", count: 2, cycles: 6, mode: .indirectX),
        0x91: .init(mnemonic: "STA", count: 2, cycles: 6, mode: .indirectY)
    ]
}
