import Foundation

struct CPU {
    var registerA: UInt8
    var registerX: UInt8
    var status: UInt8
    var programCounter: UInt16

    init() {
        registerA = 0
        registerX = 0
        status = 0
        programCounter = 0
    }

    mutating func interpret(program: [UInt8]) {
        var pc: Int {
            Int(programCounter)
        }
        programCounter = 0

        while true {
            let opscode = program[pc]
            programCounter += 1

            switch opscode {
            case 0x00:
                return

            case 0xA9:
                let param = program[pc]
                programCounter += 1
                lda(param)

            case 0xAA:
                tax()

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
