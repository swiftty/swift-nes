import Foundation

// ┏━━━━━━━━━━━━━━━┓ $10000 ┏━━━━━━━━━━━━━━━┓
// ┃ PRG-ROM       ┃        ┃               ┃
// ┃ Upper Bank    ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $C000  ┃ PRG-ROM       ┃
// ┃ PRG-ROM       ┃        ┃               ┃
// ┃ Lower Bank    ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $8000  ┣━━━━━━━━━━━━━━━┫
// ┃ SRAM          ┃        ┃ SRAM          ┃
// ┣━━━━━━━━━━━━━━━┫ $6000  ┣━━━━━━━━━━━━━━━┫
// ┃ Expansion ROM ┃        ┃ Expansion ROM ┃
// ┣━━━━━━━━━━━━━━━┫ $4020  ┣━━━━━━━━━━━━━━━┫
// ┃ I/O Registers ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $4000  ┃               ┃
// ┃ Mirrors       ┃        ┃ I/O Registers ┃
// ┃ $2000-$2007   ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $2008  ┃               ┃
// ┃ I/O Registers ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $2000  ┣━━━━━━━━━━━━━━━┫
// ┃ Mirrors       ┃        ┃               ┃
// ┃ $0000-$07FF   ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $0800  ┃               ┃
// ┃ RAM           ┃        ┃ RAM           ┃
// ┣━━━━━━━━━━━━━━━┫ $0200  ┃               ┃
// ┃ Stack         ┃        ┃               ┃
// ┣━━━━━━━━━━━━━━━┫ $0100  ┃               ┃
// ┃ Zero Page     ┃        ┃               ┃
// ┗━━━━━━━━━━━━━━━┛ $0000  ┗━━━━━━━━━━━━━━━┛
private let RAM = 0x0000 as UInt16
private let RAM_MIRRORS_END = 0x1fff as UInt16
private let PPU_REGISTERS = 0x2000 as UInt16
private let PPU_REGISTERS_MIRRORS_END = 0x3fff as UInt16

// MARK: -
protocol Mem {
    mutating func mem_read(_ addr: UInt16) -> UInt8
    mutating func mem_write(_ value: UInt8, at addr: UInt16)
}

extension Mem {
    mutating func mem_read_16(_ addr: UInt16) -> UInt16 {
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
    private var ppu: PPU

    private var cycles: Int

    public init(rom newRom: Rom) {
        vram = .init(repeating: 0, count: 2048)
        rom = newRom
        ppu = .init(rom: rom.chr, mirroring: rom.mirroring)
        cycles = 0
    }

    mutating func tick(_ step: UInt8) {
        cycles += Int(step)
        ppu.tick(step)
    }

    func poll_nmi_status() -> UInt8? {
        ppu.nmi_interrupt
    }
}

extension Bus: Mem {
    mutating func mem_read(_ addr: UInt16) -> UInt8 {
        switch addr {
        case RAM...RAM_MIRRORS_END:
            let addr = addr & 0b0000_0111_1111_1111
            return vram[Int(addr)]

        case 0x2000, 0x2001, 0x2003, 0x2005, 0x2006, 0x4014:
            fatalError("attempt to read from write-only PPU address \(hex: addr)")

        case 0x2002:
            return ppu.read_status()

        case 0x2004:
            return ppu.read_oam_data()

        case 0x2007:
            return ppu.read()

        case 0x2008...PPU_REGISTERS_MIRRORS_END:
            let addr = addr & 0b0010_0000_0000_0111
            return mem_read(addr)

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

        case 0x2000:
            ppu.write(to_ctrl: value)

        case 0x2001:
            ppu.write(to_mask: value)

        case 0x2002:
            fatalError()

        case 0x2003:
            ppu.write(to_oam_addr: value)

        case 0x2004:
            ppu.write(to_oam_data: value)

        case 0x2006:
            ppu.write(to_ppu_addr: value)

        case 0x2007:
            ppu.write(value)

        case 0x2008...PPU_REGISTERS_MIRRORS_END:
            let addr = addr & 0b0010_0000_0000_0111
            mem_write(value, at: addr)

        default:
            fatalError("invalid mem access at \(hex: addr)")
        }
    }
}
