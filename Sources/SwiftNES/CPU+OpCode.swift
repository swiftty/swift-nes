import Foundation

extension CPU {
    struct OpCode {
//        var code: UInt8
        var mnemonic: Mnemonic
        var count: UInt16
        var cycles: UInt8
        var mode: AddressingMode
    }
}

extension CPU.OpCode {
    enum Mnemonic: Equatable {
        case BRK
        case NOP
        case ADC
        case SBC
        case AND
        case EOR
        case ORA
        case ASL
        case LSR
        case ROL
        case ROR
        case INC
        case INX
        case INY
        case DEC
        case DEX
        case DEY
        case CMP
        case CPY
        case CPX
        case JMP
        case JSR
        case RTS
        case RTI
        case BCS
        case BCC
        case BEQ
        case BNE
        case BVS
        case BVC
        case BMI
        case BPL
        case BIT
        case LDA
        case LDX
        case LDY
        case STA
        case STX
        case STY
        case CLD
        case CLI
        case CLV
        case CLC
        case SEC
        case SEI
        case SED
        case TAX
        case TAY
        case TSX
        case TXA
        case TXS
        case TYA
        case PHA
        case PLA
        case PHP
        case PLP
    }
}

extension CPU.OpCode {
    static let codes: [UInt8: Self] = [
        0x00: Self.init(mnemonic: .BRK, count: 1, cycles: 7, mode: .none),
        0xea: Self.init(mnemonic: .NOP, count: 1, cycles: 2, mode: .none),

        0x69: Self.init(mnemonic: .ADC, count: 2, cycles: 2, mode: .immediate),
        0x65: Self.init(mnemonic: .ADC, count: 2, cycles: 3, mode: .zeroPage),
        0x75: Self.init(mnemonic: .ADC, count: 2, cycles: 4, mode: .zeroPageX),
        0x6d: Self.init(mnemonic: .ADC, count: 3, cycles: 4, mode: .absolute),
        0x7d: Self.init(mnemonic: .ADC, count: 3, cycles: 4, mode: .absoluteX),
        0x79: Self.init(mnemonic: .ADC, count: 3, cycles: 4, mode: .absoluteY),
        0x61: Self.init(mnemonic: .ADC, count: 2, cycles: 6, mode: .indirectX),
        0x71: Self.init(mnemonic: .ADC, count: 2, cycles: 5, mode: .indirectY),

        0xe9: Self.init(mnemonic: .SBC, count: 2, cycles: 2, mode: .immediate),
        0xe5: Self.init(mnemonic: .SBC, count: 2, cycles: 3, mode: .zeroPage),
        0xf5: Self.init(mnemonic: .SBC, count: 2, cycles: 4, mode: .zeroPageX),
        0xed: Self.init(mnemonic: .SBC, count: 3, cycles: 4, mode: .absolute),
        0xfd: Self.init(mnemonic: .SBC, count: 3, cycles: 4, mode: .absoluteX),
        0xf9: Self.init(mnemonic: .SBC, count: 3, cycles: 4, mode: .absoluteY),
        0xe1: Self.init(mnemonic: .SBC, count: 2, cycles: 6, mode: .indirectX),
        0xf1: Self.init(mnemonic: .SBC, count: 2, cycles: 5, mode: .indirectY),

        0x29: Self.init(mnemonic: .AND, count: 2, cycles: 2, mode: .immediate),
        0x25: Self.init(mnemonic: .AND, count: 2, cycles: 3, mode: .zeroPage),
        0x35: Self.init(mnemonic: .AND, count: 2, cycles: 4, mode: .zeroPageX),
        0x2d: Self.init(mnemonic: .AND, count: 3, cycles: 4, mode: .absolute),
        0x3d: Self.init(mnemonic: .AND, count: 3, cycles: 4, mode: .absoluteX),
        0x39: Self.init(mnemonic: .AND, count: 3, cycles: 4, mode: .absoluteY),
        0x21: Self.init(mnemonic: .AND, count: 2, cycles: 6, mode: .indirectX),
        0x31: Self.init(mnemonic: .AND, count: 2, cycles: 5, mode: .indirectY),

        0x49: Self.init(mnemonic: .EOR, count: 2, cycles: 2, mode: .immediate),
        0x45: Self.init(mnemonic: .EOR, count: 2, cycles: 3, mode: .zeroPage),
        0x55: Self.init(mnemonic: .EOR, count: 2, cycles: 4, mode: .zeroPageX),
        0x4d: Self.init(mnemonic: .EOR, count: 3, cycles: 4, mode: .absolute),
        0x5d: Self.init(mnemonic: .EOR, count: 3, cycles: 4, mode: .absoluteX),
        0x59: Self.init(mnemonic: .EOR, count: 3, cycles: 4, mode: .absoluteY),
        0x41: Self.init(mnemonic: .EOR, count: 2, cycles: 6, mode: .indirectX),
        0x51: Self.init(mnemonic: .EOR, count: 2, cycles: 5, mode: .indirectY),

        0x09: Self.init(mnemonic: .ORA, count: 2, cycles: 2, mode: .immediate),
        0x05: Self.init(mnemonic: .ORA, count: 2, cycles: 3, mode: .zeroPage),
        0x15: Self.init(mnemonic: .ORA, count: 2, cycles: 4, mode: .zeroPageX),
        0x0d: Self.init(mnemonic: .ORA, count: 3, cycles: 4, mode: .absolute),
        0x1d: Self.init(mnemonic: .ORA, count: 3, cycles: 4, mode: .absoluteX),
        0x19: Self.init(mnemonic: .ORA, count: 3, cycles: 4, mode: .absoluteY),
        0x01: Self.init(mnemonic: .ORA, count: 2, cycles: 6, mode: .indirectX),
        0x11: Self.init(mnemonic: .ORA, count: 2, cycles: 5, mode: .indirectY),

        /* Shifts */
        0x0a: Self.init(mnemonic: .ASL, count: 1, cycles: 2, mode: .none),
        0x06: Self.init(mnemonic: .ASL, count: 2, cycles: 5, mode: .zeroPage),
        0x16: Self.init(mnemonic: .ASL, count: 2, cycles: 6, mode: .zeroPageX),
        0x0e: Self.init(mnemonic: .ASL, count: 3, cycles: 6, mode: .absolute),
        0x1e: Self.init(mnemonic: .ASL, count: 3, cycles: 7, mode: .absoluteX),

        0x4a: Self.init(mnemonic: .LSR, count: 1, cycles: 2, mode: .none),
        0x46: Self.init(mnemonic: .LSR, count: 2, cycles: 5, mode: .zeroPage),
        0x56: Self.init(mnemonic: .LSR, count: 2, cycles: 6, mode: .zeroPageX),
        0x4e: Self.init(mnemonic: .LSR, count: 3, cycles: 6, mode: .absolute),
        0x5e: Self.init(mnemonic: .LSR, count: 3, cycles: 7, mode: .absoluteX),

        0x2a: Self.init(mnemonic: .ROL, count: 1, cycles: 2, mode: .none),
        0x26: Self.init(mnemonic: .ROL, count: 2, cycles: 5, mode: .zeroPage),
        0x36: Self.init(mnemonic: .ROL, count: 2, cycles: 6, mode: .zeroPageX),
        0x2e: Self.init(mnemonic: .ROL, count: 3, cycles: 6, mode: .absolute),
        0x3e: Self.init(mnemonic: .ROL, count: 3, cycles: 7, mode: .absoluteX),

        0x6a: Self.init(mnemonic: .ROR, count: 1, cycles: 2, mode: .none),
        0x66: Self.init(mnemonic: .ROR, count: 2, cycles: 5, mode: .zeroPage),
        0x76: Self.init(mnemonic: .ROR, count: 2, cycles: 6, mode: .zeroPageX),
        0x6e: Self.init(mnemonic: .ROR, count: 3, cycles: 6, mode: .absolute),
        0x7e: Self.init(mnemonic: .ROR, count: 3, cycles: 7, mode: .absoluteX),

        0xe6: Self.init(mnemonic: .INC, count: 2, cycles: 5, mode: .zeroPage),
        0xf6: Self.init(mnemonic: .INC, count: 2, cycles: 6, mode: .zeroPageX),
        0xee: Self.init(mnemonic: .INC, count: 3, cycles: 6, mode: .absolute),
        0xfe: Self.init(mnemonic: .INC, count: 3, cycles: 7, mode: .absoluteX),

        0xe8: Self.init(mnemonic: .INX, count: 1, cycles: 2, mode: .none),
        0xc8: Self.init(mnemonic: .INY, count: 1, cycles: 2, mode: .none),

        0xc6: Self.init(mnemonic: .DEC, count: 2, cycles: 5, mode: .zeroPage),
        0xd6: Self.init(mnemonic: .DEC, count: 2, cycles: 6, mode: .zeroPageX),
        0xce: Self.init(mnemonic: .DEC, count: 3, cycles: 6, mode: .absolute),
        0xde: Self.init(mnemonic: .DEC, count: 3, cycles: 7, mode: .absoluteX),

        0xca: Self.init(mnemonic: .DEX, count: 1, cycles: 2, mode: .none),
        0x88: Self.init(mnemonic: .DEY, count: 1, cycles: 2, mode: .none),

        0xc9: Self.init(mnemonic: .CMP, count: 2, cycles: 2, mode: .immediate),
        0xc5: Self.init(mnemonic: .CMP, count: 2, cycles: 3, mode: .zeroPage),
        0xd5: Self.init(mnemonic: .CMP, count: 2, cycles: 4, mode: .zeroPageX),
        0xcd: Self.init(mnemonic: .CMP, count: 3, cycles: 4, mode: .absolute),
        0xdd: Self.init(mnemonic: .CMP, count: 3, cycles: 4, mode: .absoluteX),
        0xd9: Self.init(mnemonic: .CMP, count: 3, cycles: 4, mode: .absoluteY),
        0xc1: Self.init(mnemonic: .CMP, count: 2, cycles: 6, mode: .indirectX),
        0xd1: Self.init(mnemonic: .CMP, count: 2, cycles: 5, mode: .indirectY),

        0xc0: Self.init(mnemonic: .CPY, count: 2, cycles: 2, mode: .immediate),
        0xc4: Self.init(mnemonic: .CPY, count: 2, cycles: 3, mode: .zeroPage),
        0xcc: Self.init(mnemonic: .CPY, count: 3, cycles: 4, mode: .absolute),
        0xe0: Self.init(mnemonic: .CPX, count: 2, cycles: 2, mode: .immediate),
        0xe4: Self.init(mnemonic: .CPX, count: 2, cycles: 3, mode: .zeroPage),
        0xec: Self.init(mnemonic: .CPX, count: 3, cycles: 4, mode: .absolute),

        0x4c: Self.init(mnemonic: .JMP, count: 3, cycles: 3, mode: .none),
        0x6c: Self.init(mnemonic: .JMP, count: 3, cycles: 5, mode: .none),

        0x20: Self.init(mnemonic: .JSR, count: 3, cycles: 6, mode: .none),
        0x60: Self.init(mnemonic: .RTS, count: 1, cycles: 6, mode: .none),

        0x40: Self.init(mnemonic: .RTI, count: 1, cycles: 6, mode: .none),

        0xd0: Self.init(mnemonic: .BNE, count: 2, cycles: 2, mode: .none),
        0x70: Self.init(mnemonic: .BVS, count: 2, cycles: 2, mode: .none),
        0x50: Self.init(mnemonic: .BVC, count: 2, cycles: 2, mode: .none),
        0x30: Self.init(mnemonic: .BMI, count: 2, cycles: 2, mode: .none),
        0xf0: Self.init(mnemonic: .BEQ, count: 2, cycles: 2, mode: .none),
        0xb0: Self.init(mnemonic: .BCS, count: 2, cycles: 2, mode: .none),
        0x90: Self.init(mnemonic: .BCC, count: 2, cycles: 2, mode: .none),
        0x10: Self.init(mnemonic: .BPL, count: 2, cycles: 2, mode: .none),

        0x24: Self.init(mnemonic: .BIT, count: 2, cycles: 3, mode: .zeroPage),
        0x2c: Self.init(mnemonic: .BIT, count: 3, cycles: 4, mode: .absolute),

        /* Stores, Loads */
        0xa9: Self.init(mnemonic: .LDA, count: 2, cycles: 2, mode: .immediate),
        0xa5: Self.init(mnemonic: .LDA, count: 2, cycles: 3, mode: .zeroPage),
        0xb5: Self.init(mnemonic: .LDA, count: 2, cycles: 4, mode: .zeroPageX),
        0xad: Self.init(mnemonic: .LDA, count: 3, cycles: 4, mode: .absolute),
        0xbd: Self.init(mnemonic: .LDA, count: 3, cycles: 4, mode: .absoluteX),
        0xb9: Self.init(mnemonic: .LDA, count: 3, cycles: 4, mode: .absoluteY),
        0xa1: Self.init(mnemonic: .LDA, count: 2, cycles: 6, mode: .indirectX),
        0xb1: Self.init(mnemonic: .LDA, count: 2, cycles: 5, mode: .indirectY),

        0xa2: Self.init(mnemonic: .LDX, count: 2, cycles: 2, mode: .immediate),
        0xa6: Self.init(mnemonic: .LDX, count: 2, cycles: 3, mode: .zeroPage),
        0xb6: Self.init(mnemonic: .LDX, count: 2, cycles: 4, mode: .zeroPageY),
        0xae: Self.init(mnemonic: .LDX, count: 3, cycles: 4, mode: .absolute),
        0xbe: Self.init(mnemonic: .LDX, count: 3, cycles: 4, mode: .absoluteY),

        0xa0: Self.init(mnemonic: .LDY, count: 2, cycles: 2, mode: .immediate),
        0xa4: Self.init(mnemonic: .LDY, count: 2, cycles: 3, mode: .zeroPage),
        0xb4: Self.init(mnemonic: .LDY, count: 2, cycles: 4, mode: .zeroPageX),
        0xac: Self.init(mnemonic: .LDY, count: 3, cycles: 4, mode: .absolute),
        0xbc: Self.init(mnemonic: .LDY, count: 3, cycles: 4, mode: .absoluteX),

        0x85: Self.init(mnemonic: .STA, count: 2, cycles: 3, mode: .zeroPage),
        0x95: Self.init(mnemonic: .STA, count: 2, cycles: 4, mode: .zeroPageX),
        0x8d: Self.init(mnemonic: .STA, count: 3, cycles: 4, mode: .absolute),
        0x9d: Self.init(mnemonic: .STA, count: 3, cycles: 5, mode: .absoluteX),
        0x99: Self.init(mnemonic: .STA, count: 3, cycles: 5, mode: .absoluteY),
        0x81: Self.init(mnemonic: .STA, count: 2, cycles: 6, mode: .indirectX),
        0x91: Self.init(mnemonic: .STA, count: 2, cycles: 6, mode: .indirectY),

        0x86: Self.init(mnemonic: .STX, count: 2, cycles: 3, mode: .zeroPage),
        0x96: Self.init(mnemonic: .STX, count: 2, cycles: 4, mode: .zeroPageY),
        0x8e: Self.init(mnemonic: .STX, count: 3, cycles: 4, mode: .absolute),

        0x84: Self.init(mnemonic: .STY, count: 2, cycles: 3, mode: .zeroPage),
        0x94: Self.init(mnemonic: .STY, count: 2, cycles: 4, mode: .zeroPageX),
        0x8c: Self.init(mnemonic: .STY, count: 3, cycles: 4, mode: .absolute),

        /* Flags clear */
        0xD8: Self.init(mnemonic: .CLD, count: 1, cycles: 2, mode: .none),
        0x58: Self.init(mnemonic: .CLI, count: 1, cycles: 2, mode: .none),
        0xb8: Self.init(mnemonic: .CLV, count: 1, cycles: 2, mode: .none),
        0x18: Self.init(mnemonic: .CLC, count: 1, cycles: 2, mode: .none),
        0x38: Self.init(mnemonic: .SEC, count: 1, cycles: 2, mode: .none),
        0x78: Self.init(mnemonic: .SEI, count: 1, cycles: 2, mode: .none),
        0xf8: Self.init(mnemonic: .SED, count: 1, cycles: 2, mode: .none),

        0xaa: Self.init(mnemonic: .TAX, count: 1, cycles: 2, mode: .none),
        0xa8: Self.init(mnemonic: .TAY, count: 1, cycles: 2, mode: .none),
        0xba: Self.init(mnemonic: .TSX, count: 1, cycles: 2, mode: .none),
        0x8a: Self.init(mnemonic: .TXA, count: 1, cycles: 2, mode: .none),
        0x9a: Self.init(mnemonic: .TXS, count: 1, cycles: 2, mode: .none),
        0x98: Self.init(mnemonic: .TYA, count: 1, cycles: 2, mode: .none),

        /* Stack */
        0x48: Self.init(mnemonic: .PHA, count: 1, cycles: 3, mode: .none),
        0x68: Self.init(mnemonic: .PLA, count: 1, cycles: 4, mode: .none),
        0x08: Self.init(mnemonic: .PHP, count: 1, cycles: 3, mode: .none),
        0x28: Self.init(mnemonic: .PLP, count: 1, cycles: 4, mode: .none),
    ]
}
