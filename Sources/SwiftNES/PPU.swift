import Foundation

struct PPU {
    var rom: [UInt8]
    var palette: [UInt8]
    var vram: [UInt8]
    var oam: [UInt8]
    var addr: AddrRegister
    var ctrl: ControlRegister
    var mask: MaskRegister
    var status: StatusRegister
    var scroll: ScrollRegister
    var internal_data: UInt8
    var scanline: UInt16
    var cycles: Int

    var oam_addr: UInt8
    var oam_data: [UInt8]

    var nmi_interrupt: UInt8?

    var mirroring: Rom.Mirroring

    init(rom newRom: [UInt8], mirroring newMirroring: Rom.Mirroring) {
        rom = newRom
        palette = .init(repeating: 0, count: 32)
        vram = .init(repeating: 0, count: 2048)
        oam = .init(repeating: 0, count: 64 * 4)
        addr = .init()
        ctrl = .init()
        mask = .init()
        status = .init()
        scroll = .init()
        internal_data = 0
        scanline = 0
        cycles = 0

        oam_addr = 0
        oam_data = .init(repeating: 0, count: 64 * 4)

        mirroring = newMirroring
    }

    mutating func write(_ value: UInt8) {
        let addr = addr.get()
        switch addr {
        case 0...0x1fff:
            fatalError("invalid memory access")

        case 0x2000...0x2fff:
            vram[Int(mirror_vram_addr(addr))] = value

        case 0x3000...0x3eff:
            fatalError("invalid memory access")

        case 0x3f10, 0x3f14, 0x3f18, 0x3f1c:
            let addr = addr - 0x10
            palette[Int(addr - 0x3f00)] = value

        case 0x3f00...0x3fff:
            palette[Int(addr - 0x3f00)] = value

        default:
            fatalError("invalid memory access")
        }
    }

    mutating func write(to_ppu_addr value: UInt8) {
        addr.update(value)
    }

    mutating func write(to_ctrl value: UInt8) {
        let curr = ctrl.contains(.GENERATE_NMI)
        ctrl.update(value)
        if !curr && ctrl.contains(.GENERATE_NMI) && status.contains(.VBLANK_STARTED) {
            nmi_interrupt = 1
        }
    }

    mutating func write(to_mask value: UInt8) {
        mask.rawValue = value
    }

    mutating func write(to_oam_addr value: UInt8) {
        oam_addr = value
    }

    mutating func write(to_oam_data value: UInt8) {
        oam_data[Int(oam_addr)] = value
        oam_addr &+= 1
    }

    mutating func write(to_scroll value: UInt8) {
        scroll.write(value)
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

        case 0x3f10, 0x3f14, 0x3f18, 0x3f1c:
            let addr = addr - 0x10
            return palette[Int(addr - 0x3f00)]

        case 0x3f00...0x3fff:
            return palette[Int(addr - 0x3f00)]

        default:
            fatalError("invalid memory access")
        }
    }

    mutating func read_status() -> UInt8 {
        let data = status.rawValue
        status.remove(.VBLANK_STARTED)
        addr.reset_latch()
        scroll.reset_latch()
        return data
    }

    func read_oam_data() -> UInt8 {
        oam_data[Int(oam_addr)]
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

    @discardableResult
    mutating func tick(_ step: UInt8) -> Bool {
        cycles += Int(step)
        if cycles >= 341 {
            cycles -= 341
            scanline += 1

            if scanline == 241 {
                status.insert(.VBLANK_STARTED)
                status.insert(.SPRITE_ZERO_HIT)
                if ctrl.contains(.GENERATE_NMI) {
                    nmi_interrupt = 1
                }
            } else if scanline >= 262 {
                scanline = 0
                nmi_interrupt = nil
                status.remove(.SPRITE_ZERO_HIT)
                status.remove(.VBLANK_STARTED)
                return true
            }
        }
        return false
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

extension PPU {
    /// 7     bit      0
    /// -------  -------
    /// V S O .  . . . .
    /// ┃ ┃ ┃ ┗━━┻━┻━┻━┻ Least significant bits previously written into a PPU register
    /// ┃ ┃ ┃             (due to register not being updated for this address)
    /// ┃ ┃ ┗━━━━━━━━━━━ Sprite overflow. The intent was for this flag to be set
    /// ┃ ┃               whenever more than eight sprites appear on a scanline, but a
    /// ┃ ┃               hardware bug causes the actual behavior to be more complicated
    /// ┃ ┃               and generate false positives as well as false negatives; see
    /// ┃ ┃               PPU sprite evaluation. This flag is set during sprite
    /// ┃ ┃               evaluation and cleared at dot 1 (the second dot) of the
    /// ┃ ┃               pre-render line.
    /// ┃ ┗━━━━━━━━━━━━━ Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
    /// ┃                 a nonzero background pixel; cleared at dot 1 of the pre-render
    /// ┃                 line.  Used for raster timing.
    /// ┗━━━━━━━━━━━━━━━ Vertical blank has started (0: not in vblank; 1: in vblank).
    ///                   Set at dot 1 of line 241 (the line *after* the post-render
    ///                   line); cleared after reading $2002 and at dot 1 of the
    ///                   pre-render line.
    struct StatusRegister: OptionSet {
        var rawValue: UInt8

        static let NA0             = Self.init(rawValue: 0b0000_0001)
        static let NA1             = Self.init(rawValue: 0b0000_0010)
        static let NA2             = Self.init(rawValue: 0b0000_0100)
        static let NA3             = Self.init(rawValue: 0b0000_1000)
        static let NA4             = Self.init(rawValue: 0b0001_0000)
        static let SPRITE_OVERFLOW = Self.init(rawValue: 0b0010_0000)
        static let SPRITE_ZERO_HIT = Self.init(rawValue: 0b0100_0000)
        static let VBLANK_STARTED  = Self.init(rawValue: 0b1000_0000)
    }
}

extension PPU {
    /// 7     bit      0
    /// -------  -------
    /// B G R s  b M m G
    /// ┃ ┃ ┃ ┃  ┃ ┃ ┃ ┗ Greyscale (0: normal color, 1: produce a greyscale display)
    /// ┃ ┃ ┃ ┃  ┃ ┃ ┗━━ 1: Show background in leftmost 8 pixels of screen, 0: Hide
    /// ┃ ┃ ┃ ┃  ┃ ┗━━━━ 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
    /// ┃ ┃ ┃ ┃  ┗━━━━━━ 1: Show background
    /// ┃ ┃ ┃ ┗━━━━━━━━━ 1: Show sprites
    /// ┃ ┃ ┗━━━━━━━━━━━ Emphasize red
    /// ┃ ┗━━━━━━━━━━━━━ Emphasize green
    /// ┗━━━━━━━━━━━━━━━ Emphasize blue
    struct MaskRegister: OptionSet {
        var rawValue: UInt8

        static let GREYSCALE                = Self.init(rawValue: 0b0000_0001)
        static let LEFTMOST_8PXL_BACKGROUND = Self.init(rawValue: 0b0000_0010)
        static let LEFTMOST_8PXL_SPRITE     = Self.init(rawValue: 0b0000_0100)
        static let SHOW_BACKGROUND          = Self.init(rawValue: 0b0000_1000)
        static let SHOW_SPRITES             = Self.init(rawValue: 0b0001_0000)
        static let EMPHASISE_RED            = Self.init(rawValue: 0b0010_0000)
        static let EMPHASISE_GREEN          = Self.init(rawValue: 0b0100_0000)
        static let EMPHASISE_BLUE           = Self.init(rawValue: 0b1000_0000)
    }
}

extension PPU {
    struct ScrollRegister {
        var scroll: (x: UInt8, y: UInt8)
        var latch: Bool

        init() {
            scroll = (0, 0)
            latch = false
        }

        mutating func write(_ value: UInt8) {
            if !latch {
                scroll.x = value
            } else {
                scroll.y = value
            }
            latch.toggle()
        }

        mutating func reset_latch() {
            latch = false
        }
    }
}
