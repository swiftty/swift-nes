import Foundation

struct CPU {
    var registerA: UInt8
    var registerX: UInt8
    var status: UInt8
    var programCounter: UInt16

    var memory: [UInt8]

    init() {
        registerA = 0
        registerX = 0
        status = 0
        programCounter = 0
        memory = .init(repeating: 0, count: 0xFFFF)
    }

    func mem_read(_ addr: UInt16) -> UInt8 {
        memory[Int(addr)]
    }

    func mem_read_16(_ addr: UInt16) -> UInt16 {
        let lo = UInt16(mem_read(addr))
        let hi = UInt16(mem_read(addr + 1))
        return (hi << 8) | lo
    }

    mutating func mem_write(_ value: UInt8, at addr: UInt16) {
        memory[Int(addr)] = value
    }

    mutating func mem_write_16(_ value: UInt16, at addr: UInt16) {
        let hi = UInt8(value >> 8)
        let lo = UInt8(value & 0xFF)
        mem_write(lo, at: addr)
        mem_write(hi, at: addr + 1)
    }

    mutating func start(program: [UInt8]) {
        load(program: program)
        reset()
        run()
    }

    mutating func reset() {
        registerA = 0
        registerX = 0
        status = 0

        programCounter = mem_read_16(0xFFFC)
    }

    mutating func load(program: [UInt8]) {
        memory.replaceSubrange(0x8000..<(0x8000 + program.count), with: program)
        mem_write_16(0x8000, at: 0xFFFC)
    }

    mutating func run() {
        while true {
            let opscode = mem_read(programCounter)
            programCounter += 1

            switch opscode {
            case 0x00:
                return

            case 0xA9:
                let param = mem_read(programCounter)
                programCounter += 1
                lda(param)

            case 0xAA:
                tax()

            case 0xE8:
                inx()

            default:
                fatalError()
            }
        }
    }

    mutating func lda(_ value: UInt8) {
        registerA = value
        updateZeroAndNegativeFlags(registerA)
    }

    mutating func tax() {
        registerX = registerA
        updateZeroAndNegativeFlags(registerX)
    }

    mutating func inx() {
        registerX &+= 1
        updateZeroAndNegativeFlags(registerX)
    }

    private mutating func updateZeroAndNegativeFlags(_ result: UInt8) {
        if result == 0 {
            status = status | 0b0000_0010
        } else {
            status = status & 0b1111_1101
        }

        if result & 0b1000_0000 != 0 {
            status = status | 0b1000_0000
        } else {
            status = status & 0b0111_1111
        }
    }
}
