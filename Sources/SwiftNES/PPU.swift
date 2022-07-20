import Foundation

struct PPU {
    var rom: [UInt8]
    var palette: [UInt8]
    var vram: [UInt8]
    var oam: [UInt8]
    var addr: AddrRegister
    var ctrl: ControlRegister
    var internal_data: UInt8

    var mirroring: Rom.Mirroring

    init(rom newRom: [UInt8], mirroring newMirroring: Rom.Mirroring) {
        rom = newRom
        palette = .init(repeating: 0, count: 32)
        vram = .init(repeating: 0, count: 2048)
        oam = .init(repeating: 0, count: 64 * 4)
        addr = .init()
        ctrl = .init()
        internal_data = 0
        mirroring = newMirroring
    }

    mutating func write(to_ppu_addr value: UInt8) {
        addr.update(value)
    }

    mutating func write(to_ctrl value: UInt8) {
        ctrl.update(value)
    }

    mutating func increment_vram_addr() {
        addr.increment(ctrl.vram_addr_increment())
    }

    mutating func read() -> UInt8 {
        let addr = addr.get()
        increment_vram_addr()

        switch addr {
        case 0...0x1fff:
            let result = internal_data
            internal_data = rom[Int(addr)]
            return result

        case 0x2000...0x2fff:
            let result = internal_data
            internal_data = vram[Int(mirror_vram_addr(addr))]
            return result

        case 0x3000...0x3eff:
            fatalError("invalid memory access")

        case 0x3f00...0x3fff:
            return palette[Int(addr) - 0x3f00]

        default:
            fatalError("invalid memory access")
        }
    }

    func mirror_vram_addr(_ addr: UInt16) -> UInt16 {
        let mirrored_vram = addr & 0b0010_1111_1111_1111
        let index = mirrored_vram - 0x2000
        let name = index / 0x400
        switch (mirroring, name) {
        case (.vertical, 2), (.vertical, 3): return index - 0x800
        case (.horizontal, 1), (.horizontal, 2): return index - 0x400
        case (.horizontal, 3): return index - 0x800
        default: return index
        }
    }
}

extension PPU {
    struct AddrRegister {
        var value: (hi: UInt8, lo: UInt8)
        var hi_ptr: Bool

        init() {
            value = (0, 0)
            hi_ptr = true
        }

        func get() -> UInt16 {
            UInt16(value.hi) << 8 | UInt16(value.lo)
        }

        mutating func set(_ data: UInt16) {
            value.hi = UInt8(data >> 8)
            value.lo = UInt8(data & 0xff)
        }

        mutating func update(_ data: UInt8) {
            if hi_ptr {
                value.hi = data
            } else {
                value.lo = data
            }

            if case let value = get(), value > 0x3fff {
                set(value & 0b0011_1111_1111_1111)
            }

            hi_ptr.toggle()
        }

        mutating func increment(_ inc: UInt8) {
            let lo = value.lo
            value.lo &+= inc
            if lo > value.lo {
                value.hi &+= 1
            }

            if case let value = get(), value > 0x3fff {
                set(value & 0b0011_1111_1111_1111)
            }
        }

        mutating func reset_latch() {
            hi_ptr = true
        }
    }
}

extension PPU {
    /// 7     bit      0
    /// -------  -------
    /// V P H B  S I N N
    /// ┃ ┃ ┃ ┃  ┃ ┃ ┗━┻ Base nametable address
    /// ┃ ┃ ┃ ┃  ┃ ┃      (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
    /// ┃ ┃ ┃ ┃  ┃ ┗━━━━ VRAM address increment per CPU read/write of PPUDATA
    /// ┃ ┃ ┃ ┃  ┃        (0: add 1, going across; 1: add 32, going down)
    /// ┃ ┃ ┃ ┃  ┗━━━━━━ Sprite pattern table address for 8x8 sprites
    /// ┃ ┃ ┃ ┃           (0: $0000; 1: $1000; ignored in 8x16 mode)
    /// ┃ ┃ ┃ ┗━━━━━━━━━ Background pattern table address (0: $0000; 1: $1000)
    /// ┃ ┃ ┗━━━━━━━━━━━ Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
    /// ┃ ┗━━━━━━━━━━━━━ PPU master/slave select
    /// ┃                 (0: read backdrop from EXT pins; 1: output color on EXT pins)
    /// ┗━━━━━━━━━━━━━━━ Generate an NMI at the start of the
    ///                   vertical blanking interval (0: off; 1: on)
    struct ControlRegister: OptionSet {
        var rawValue: UInt8

        static let NAMETABLE1             = Self.init(rawValue: 0b0000_0001)
        static let NAMETABLE2             = Self.init(rawValue: 0b0000_0010)
        static let VRAM_ADD_INCREMENT     = Self.init(rawValue: 0b0000_0100)
        static let SPRITE_PATTERN_ADDR    = Self.init(rawValue: 0b0000_1000)
        static let BACKROUND_PATTERN_ADDR = Self.init(rawValue: 0b0001_0000)
        static let SPRITE_SIZE            = Self.init(rawValue: 0b0010_0000)
        static let MASTER_SLAVE_SELECT    = Self.init(rawValue: 0b0100_0000)
        static let GENERATE_NMI           = Self.init(rawValue: 0b1000_0000)

        func vram_addr_increment() -> UInt8 {
            !contains(.VRAM_ADD_INCREMENT) ? 1 : 32
        }

        mutating func update(_ data: UInt8) {
            rawValue = data
        }
    }
}
