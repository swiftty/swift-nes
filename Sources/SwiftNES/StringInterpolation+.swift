import Foundation

public func trace(_ cpu: CPU) -> String {
    let code = cpu.mem_read(cpu.programCounter)
    let ops = CPU.OpCode.codes[code]!

    let begin = cpu.programCounter
    var hex_dump = [code]

    let (addr, value): (UInt16, UInt8) = {
        switch ops.mode {
        case .immediate, .none:
            return (0, 0)
        default:
            let addr = cpu.absolute_address(ops.mode, begin + 1)
            return (addr, cpu.mem_read(addr))
        }
    }()

    let tmp: String = {
        switch ops.count {
        case 1:
            switch code {
            case 0x0a, 0x4a, 0x2a, 0x6a: return "A "
            default: return ""
            }

        case 2:
            let address = cpu.mem_read(begin + 1)
            hex_dump.append(address)

            switch ops.mode {
            case .immediate:
                return "#$\(hex: address)"
            case .zeroPage:
                return "$\(hex: addr) = \(hex: value)"
            case .zeroPageX:
                return "$\(hex: address),X @ \(hex: addr) = \(hex: value)"
            case .zeroPageY:
                return "$\(hex: address),Y @ \(hex: addr) = \(hex: value)"
            case .indirectX:
                return "($\(hex: address), X) @ \(hex: address &+ cpu.registerX) \(hex: addr) = \(hex: value)"
            case .indirectY:
                return "($\(hex: address), Y) @ \(hex: address &+ cpu.registerY) \(hex: addr) = \(hex: value)"
            case .none:
                let address = Int(begin + 2) &+ Int(Int8(address))
                return "$\(hex: address)"
            default:
                fatalError()
            }

        case 3:
            let lo = cpu.mem_read(begin + 1)
            let hi = cpu.mem_read(begin + 2)
            hex_dump.append(contentsOf: [lo, hi])

            let address = cpu.mem_read_16(begin + 1)

            switch ops.mode {
            case .none:
                if code == 0x6c {
                    let addr: UInt16
                    if (address & 0x00ff) == 0x00ff {
                        let lo = UInt16(cpu.mem_read(address))
                        let hi = UInt16(cpu.mem_read(address & 0xff00))
                        addr = hi << 8 | lo
                    } else {
                        addr = cpu.mem_read_16(address)
                    }
                    return "($\(hex: address)) = \(hex: addr)"
                } else {
                    return "$\(hex: address)"
                }
            case .absolute:
                return "$\(hex: addr) = \(hex: value)"
            case .absoluteX:
                return "$\(hex: address),X @ \(hex: addr) = \(hex: value)"
            case .absoluteY:
                return "$\(hex: address),Y @ \(hex: addr) = \(hex: value)"
            default:
                fatalError()
            }

        default:
            return ""
        }
    }()

    let hex_str = hex_dump
        .map { "\(hex: $0)" }
        .joined(separator: " ")
    let asm_str = "\(hex: begin)  \(hex_str) \(ops.mnemonic) \(tmp)"

    return [
        "\(asm_str)",
        "A:\(hex: cpu.registerA)",
        "X:\(hex: cpu.registerX)",
        "Y:\(hex: cpu.registerY)",
        "P:\(hex: cpu.status.rawValue)",
        "SP:\(hex: cpu.stackPointer)"
    ].joined(separator: " ")
}

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
