import XCTest
@testable import SwiftNES

class CPUTests: XCTestCase {
    func test_0xa9_lda_immidiate_load_data() {
        var cpu = CPU()
        cpu.interpret(program: [0xa9, 0x05, 0x00])
        XCTAssertEqual(cpu.registerA, 0x05)
        XCTAssertEqual(cpu.status & 0b0000_0010, 0b00)
        XCTAssertEqual(cpu.status & 0b1000_0000, 0b00)
    }

    func test_0xa9_lda_zero_flag() {
        var cpu = CPU()
        cpu.interpret(program: [0xa9, 0x00, 0x00])
        XCTAssertEqual(cpu.status & 0b0000_0010, 0b10)
    }

    func test_0xaa_tax_move_a_to_x() {
        var cpu = CPU()
        cpu.registerA = 10
        cpu.interpret(program: [0xaa, 0x00])
        XCTAssertEqual(cpu.registerX, 10)
    }
}
