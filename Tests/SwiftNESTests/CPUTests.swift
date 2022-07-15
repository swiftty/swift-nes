import XCTest
@testable import SwiftNES

struct TestRom {
    var header: [UInt8]
    var trainer: [UInt8]?
    var prg_rom: [UInt8]
    var chr_rom: [UInt8]

    func asRom() -> Rom {
        var raw: [UInt8] = []
        raw.append(contentsOf: header)
        raw.append(contentsOf: trainer ?? [])
        raw.append(contentsOf: prg_rom)
        raw.append(contentsOf: chr_rom)
        return try! Rom(raw)
    }
}
extension Rom {
    static func test() -> Rom {
        TestRom(
            header: [0x4E, 0x45, 0x53, 0x1A, 0x02, 0x01, 0x31, 00, 00, 00, 00, 00, 00, 00, 00, 00],
            prg_rom: .init(repeating: 1, count: 2 * PRG_ROM_PAGE_SIZE),
            chr_rom: .init(repeating: 2, count: 1 * CHR_ROM_PAGE_SIZE)
        ).asRom()
    }
}

class CPUTests: XCTestCase {
    func test_0xa9_lda_immidiate_load_data() {
        let bus = Bus(rom: .test())
        var cpu = CPU(bus: bus)
        cpu.start(program: [0xa9, 0x05, 0x00])
        XCTAssertEqual(cpu.registerA, 0x05)
        XCTAssertEqual(cpu.status.rawValue & 0b0000_0010, 0b00)
        XCTAssertEqual(cpu.status.rawValue & 0b1000_0000, 0b00)
    }

    func test_0xa9_lda_zero_flag() {
        let bus = Bus(rom: .test())
        var cpu = CPU(bus: bus)
        cpu.start(program: [0xa9, 0x00, 0x00])
        XCTAssertEqual(cpu.status.rawValue & 0b0000_0010, 0b10)
    }

    func test_0xaa_tax_move_a_to_x() {
        let bus = Bus(rom: .test())
        var cpu = CPU(bus: bus)
        cpu.start(program: [0xa9, 0x0A,0xaa, 0x00])
        XCTAssertEqual(cpu.registerX, 10)
    }

    func test_5_ops_working_together() {
        let bus = Bus(rom: .test())
        var cpu = CPU(bus: bus)
        cpu.start(program: [0xa9, 0xc0, 0xaa, 0xe8, 0x00])
        XCTAssertEqual(cpu.registerX, 0xc1)
    }

    func test_inx_overflow() {
        let bus = Bus(rom: .test())
        var cpu = CPU(bus: bus)
        cpu.start(program: [0xa9, 0xff, 0xaa,0xe8, 0xe8, 0x00])
        XCTAssertEqual(cpu.registerX, 1)
    }

    func test_lda_from_memory() {
        let bus = Bus(rom: .test())
        var cpu = CPU(bus: bus)
        cpu.mem_write(0x55, at: 0x10)
        cpu.start(program: [0xa5, 0x10, 0x00])
        XCTAssertEqual(cpu.registerA, 0x55)
    }
}
