import Foundation

//  _______________ $10000  _______________
// | PRG-ROM       |       |               |
// | Upper Bank    |       |               |
// |_ _ _ _ _ _ _ _| $C000 | PRG-ROM       |
// | PRG-ROM       |       |               |
// | Lower Bank    |       |               |
// |_______________| $8000 |_______________|
// | SRAM          |       | SRAM          |
// |_______________| $6000 |_______________|
// | Expansion ROM |       | Expansion ROM |
// |_______________| $4020 |_______________|
// | I/O Registers |       |               |
// |_ _ _ _ _ _ _ _| $4000 |               |
// | Mirrors       |       | I/O Registers |
// | $2000-$2007   |       |               |
// |_ _ _ _ _ _ _ _| $2008 |               |
// | I/O Registers |       |               |
// |_______________| $2000 |_______________|
// | Mirrors       |       |               |
// | $0000-$07FF   |       |               |
// |_ _ _ _ _ _ _ _| $0800 |               |
// | RAM           |       | RAM           |
// |_ _ _ _ _ _ _ _| $0200 |               |
// | Stack         |       |               |
// |_ _ _ _ _ _ _ _| $0100 |               |
// | Zero Page     |       |               |
// |_______________| $0000 |_______________|
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
public struct Bus {
    private var vram: [UInt8]
    private var rom: Rom

    public init(rom newRom: Rom) {
        vram = .init(repeating: 0, count: 2048)
        rom = newRom
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

        case 0x8000...0xffff:
            var addr = addr - 0x8000
            if rom.prg.count == 0x4000 && addr >= 0x4000 {
                addr = addr % 0x4000
            }
            return rom.prg[Int(addr)]

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
