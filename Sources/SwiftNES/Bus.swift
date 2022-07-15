import Foundation

private let RAM = 0x0000 as UInt16
private let RAM_MIRRORS_END = 0x1fff as UInt16
private let PPU_REGISTERS = 0x2000 as UInt16
private let PPU_REGISTERS_MIRRORS_END = 0x3fff as UInt16

// MARK: -
protocol Mem {
    func mem_read(_ addr: UInt16) -> UInt8
    mutating func mem_write(_ value: UInt8, at addr: UInt16)
}

extension Mem {
    func mem_read_16(_ addr: UInt16) -> UInt16 {
        let lo = UInt16(mem_read(addr))
        let hi = UInt16(mem_read(addr + 1))
        return (hi << 8) | lo
    }

    mutating func mem_write_16(_ value: UInt16, at addr: UInt16) {
        let hi = UInt8(value >> 8)
        let lo = UInt8(value & 0xff)
        mem_write(lo, at: addr)
        mem_write(hi, at: addr + 1)
    }
}

// MARK: -
struct Bus {
    private var vram: [UInt8]

    init() {
        vram = .init(repeating: 0, count: 2048)
    }
}

extension Bus: Mem {
    func mem_read(_ addr: UInt16) -> UInt8 {
        switch addr {
        case RAM...RAM_MIRRORS_END:
            let addr = addr & 0b0000_0111_1111_1111
            return vram[Int(addr)]

        case PPU_REGISTERS...PPU_REGISTERS_MIRRORS_END:
            let addr = addr & 0b0010_0000_0000_0111
            fatalError("PPU is not supported yet at \(hex: addr)")

        default:
            fatalError("invalid mem access at \(hex: addr)")
        }
    }

    mutating func mem_write(_ value: UInt8, at addr: UInt16) {
        switch addr {
        case RAM...RAM_MIRRORS_END:
            let addr = addr & 0b0000_0111_1111_1111
            vram[Int(addr)] = value

        case PPU_REGISTERS...PPU_REGISTERS_MIRRORS_END:
            let addr = addr & 0b0010_0000_0000_0111
            fatalError("PPU is not supported yet at \(hex: addr)")

        default:
            fatalError("invalid mem access at \(hex: addr)")
        }
    }
}
