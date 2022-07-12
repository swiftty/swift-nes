import Foundation

struct CPU {
    var registerA: UInt8
    var status: UInt8
    var programCounter: UInt16

    init() {
        registerA = 0
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
            case 0xA9:
                let param = program[pc]
                programCounter += 1
                registerA = param

                if registerA == 0 {
                    status = status | 0b0000_0010
                } else {
                    status = status & 0b1111_1101
                }

                if registerA & 0b1000_0000 != 0 {
                    status = status | 0b1000_0000
                } else {
                    status = status & 0b0111_1111
                }

            case 0x00:
                return

            default:
                fatalError()
            }
        }
    }
}
