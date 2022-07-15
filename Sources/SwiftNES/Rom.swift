import Foundation

let NES_TAG: [UInt8] = [0x4e, 0x45, 0x53, 0x1a]  // NES
let PRG_ROM_PAGE_SIZE = 16384
let CHR_ROM_PAGE_SIZE = 8192

public struct Rom {
    public enum Error: Swift.Error {
        case invalidFormat
        case unsupportedVersion(UInt8)
    }
    var prg: [UInt8]
    var chr: [UInt8]
    var mapper: UInt8
    var mirroring: Mirroring

    public init(_ raw: [UInt8]) throws {
        guard zip(NES_TAG, raw).allSatisfy({ $0 == $1 }) else {
            throw Error.invalidFormat
        }

        mapper = (raw[7] & 0b1111_0000) | (raw[6] >> 4)

        let ver = (raw[7] >> 2) & 0b11
        guard ver == 0 else {
            throw Error.unsupportedVersion(ver)
        }

        mirroring = {
            let screen = raw[6] & 0b1000 != 0
            let vertical = raw[6] & 0b0001 != 0
            switch (screen, vertical) {
            case (true, _): return .four_screen
            case (false, true): return .vertical
            case (false, false): return .horizontal
            }
        }()

        let prg_size = Int(raw[4]) * PRG_ROM_PAGE_SIZE
        let chr_size = Int(raw[5]) * CHR_ROM_PAGE_SIZE

        let skip_trainer = raw[6] & 0b0100 != 0

        let prg_start = 16 + (skip_trainer ? 512 : 0)
        let chr_start = prg_start + prg_size

        prg = Array(raw[prg_start..<(prg_start + prg_size)])
        chr = Array(raw[chr_start..<(chr_start + chr_size)])
    }
}

extension Rom {
    enum Mirroring {
        case vertical, horizontal, four_screen
    }
}
