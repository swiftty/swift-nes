import XCTest
@testable import SwiftNES

class CPUTests: XCTestCase {
    func test_0xa9_lda_immidiate_load_data() {
        var cpu = CPU()
        cpu.start(program: [0xa9, 0x05, 0x00])
        XCTAssertEqual(cpu.registerA, 0x05)
        XCTAssertEqual(cpu.status.rawValue & 0b0000_0010, 0b00)
        XCTAssertEqual(cpu.status.rawValue & 0b1000_0000, 0b00)
    }

    func test_0xa9_lda_zero_flag() {
        var cpu = CPU()
        cpu.start(program: [0xa9, 0x00, 0x00])
        XCTAssertEqual(cpu.status.rawValue & 0b0000_0010, 0b10)
    }

    func test_0xaa_tax_move_a_to_x() {
        var cpu = CPU()
        cpu.start(program: [0xa9, 0x0A,0xaa, 0x00])
        XCTAssertEqual(cpu.registerX, 10)
    }

    func test_5_ops_working_together() {
        var cpu = CPU()
        cpu.start(program: [0xa9, 0xc0, 0xaa, 0xe8, 0x00])
        XCTAssertEqual(cpu.registerX, 0xc1)
    }

    func test_inx_overflow() {
        var cpu = CPU()
        cpu.start(program: [0xa9, 0xff, 0xaa,0xe8, 0xe8, 0x00])
        XCTAssertEqual(cpu.registerX, 1)
    }

    func test_lda_from_memory() {
        var cpu = CPU()
        cpu.mem_write(0x55, at: 0x10)
        cpu.start(program: [0xa5, 0x10, 0x00])
        XCTAssertEqual(cpu.registerA, 0x55)
    }
}
