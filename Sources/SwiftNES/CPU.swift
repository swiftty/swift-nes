import Foundation

private let STACK: UInt16 = 0x0100
private let STACK_RESET: UInt8 = 0xfd

private extension OptionSet {
    mutating func toggle(_ value: Element, to flag: Bool) {
        if flag {
            insert(value)
        } else {
            remove(value)
        }
    }
}

public struct CPU {
    /// # Status Register (P) http://wiki.nesdev.com/w/index.php/Status_flags
    ///
    ///  7 6 5 4 3 2 1 0
    ///  N V   B D I Z C
    ///  ┃ ┃   ┃ ┃ ┃ ┃ ┗━ Carry Flag
    ///  ┃ ┃   ┃ ┃ ┃ ┗━━━ Zero Flag
    ///  ┃ ┃   ┃ ┃ ┗━━━━━ Interrupt Disable
    ///  ┃ ┃   ┃ ┗━━━━━━━ Decimal Mode (not used on NES)
    ///  ┃ ┃   ┗━━━━━━━━━ Break Command
    ///  ┃ ┗━━━━━━━━━━━━━ Overflow Flag
    ///  ┗━━━━━━━━━━━━━━━ Negative Flag
    ///
    struct CPUFlags: OptionSet {
        var rawValue: UInt8

        static let CARRY             = Self.init(rawValue: 0b0000_0001)
        static let ZERO              = Self.init(rawValue: 0b0000_0010)
        static let INTERRUPT_DISABLE = Self.init(rawValue: 0b0000_0100)
        static let DECIMAL_MODE      = Self.init(rawValue: 0b0000_1000)
        static let BREAK             = Self.init(rawValue: 0b0001_0000)
        static let BREAK2            = Self.init(rawValue: 0b0010_0000)
        static let OVERFLOW          = Self.init(rawValue: 0b0100_0000)
        static let NEGATIV           = Self.init(rawValue: 0b1000_0000)
    }

    var registerA: UInt8
    var registerX: UInt8
    var registerY: UInt8
    var status: CPUFlags
    var stackPointer: UInt8
    var programCounter: UInt16

    var memory: [UInt8]

    public init() {
        registerA = 0
        registerX = 0
        registerY = 0
        status = CPUFlags(rawValue: 0b100100)
        stackPointer = STACK_RESET
        programCounter = 0
        memory = .init(repeating: 0, count: 0xFFFF)
    }

    public mutating func start(program: [UInt8]) {
        load(program: program)
        reset()
        run()
    }

    public mutating func reset() {
        registerA = 0
        registerX = 0
        status = CPUFlags(rawValue: 0b100100)

        stackPointer = STACK_RESET
        programCounter = mem_read_16(0xFFFC)
    }

    public mutating func load(program: [UInt8]) {
        memory.replaceSubrange(0x8000..<(0x8000 + program.count), with: program)
        mem_write_16(0x8000, at: 0xFFFC)
    }

    public mutating func run() {
        run({ _ in })
    }

    public mutating func run(_ callback: (inout CPU) -> Void) {
        let opcodes = OpCode.codes

        while true {
            callback(&self)

            let code = mem_read(programCounter)
            programCounter += 1

            let currentState = programCounter
            let opcode = opcodes[code]!

            switch opcode.mnemonic {
            case .BRK:
                return

            case .NOP:
                break

            case .ADC:
                adc(opcode.mode)

            case .SBC:
                sbc(opcode.mode)

            case .AND:
                and(opcode.mode)

            case .EOR:
                eor(opcode.mode)

            case .ORA:
                ora(opcode.mode)

            case .ASL where code == 0x0a:
                asl_accumlator()

            case .ASL:
                asl(opcode.mode)

            case .LSR where code == 0x4a:
                lsr_accumlator()

            case .LSR:
                lsr(opcode.mode)

            case .ROL where code == 0x2a:
                rol_accumlator()

            case .ROL:
                rol(opcode.mode)

            case .ROR where code == 0x6a:
                ror_accumlator()

            case .ROR:
                ror(opcode.mode)

            case .INC:
                inc(opcode.mode)

            case .INX:
                inx()

            case .INY:
                iny()

            case .DEC:
                dec(opcode.mode)

            case .DEX:
                dex()

            case .DEY:
                dey()

            case .CMP:
                cmp(opcode.mode, with: registerA)

            case .CPX:
                cmp(opcode.mode, with: registerX)

            case .CPY:
                cmp(opcode.mode, with: registerY)

            case .JMP where code == 0x4c:  // absolute
                let addr = mem_read_16(programCounter)
                programCounter = addr

            case .JMP where code == 0x6c:  // indirect
                let addr = mem_read_16(programCounter)
                // let ref = mem_read_u16(addr)
                // 6502 bug mode with with page boundary:
                //  if address $3000 contains $40, $30FF contains $80, and $3100 contains $50,
                //  the result of JMP ($30FF) will be a transfer of control to $4080 rather than $5080 as you intended
                // i.e. the 6502 took the low byte of the address from $30FF and the high byte from $3000
                let indirect: UInt16
                if addr & 0x00ff == 0x00ff {
                    let lo = mem_read(addr)
                    let hi = mem_read(addr & 0xff00)
                    indirect = UInt16(hi) << 8 | UInt16(lo)
                } else {
                    indirect = mem_read_16(addr)
                }
                programCounter = indirect

            case .JSR:
                stack_push_16(programCounter + 2 - 1)
                let addr = mem_read_16(programCounter)
                programCounter = addr

            case .RTS:
                programCounter = stack_pop_16() + 1

            case .RTI:
                status.rawValue = stack_pop()
                status.remove(.BREAK)
                status.insert(.BREAK2)

                programCounter = stack_pop_16()

            case .BCS:
                branch(status.contains(.CARRY))

            case .BCC:
                branch(!status.contains(.CARRY))

            case .BEQ:
                branch(status.contains(.ZERO))

            case .BNE:
                branch(!status.contains(.ZERO))

            case .BVS:
                branch(status.contains(.OVERFLOW))

            case .BVC:
                branch(!status.contains(.OVERFLOW))

            case .BMI:
                branch(status.contains(.NEGATIV))

            case .BPL:
                branch(!status.contains(.NEGATIV))

            case .BIT:
                bit(opcode.mode)

            case .LDA:
                lda(opcode.mode)

            case .LDX:
                ldx(opcode.mode)

            case .LDY:
                ldy(opcode.mode)

            case .STA:
                sta(opcode.mode)

            case .STX:
                stx(opcode.mode)

            case .STY:
                sty(opcode.mode)

            case .CLD:
                status.remove(.DECIMAL_MODE)

            case .CLI:
                status.remove(.INTERRUPT_DISABLE)

            case .CLV:
                status.remove(.OVERFLOW)

            case .CLC:
                status.remove(.CARRY)

            case .SED:
                status.insert(.DECIMAL_MODE)

            case .SEI:
                status.insert(.INTERRUPT_DISABLE)

            case .SEC:
                status.insert(.CARRY)

            case .TAX:
                tax()

            case .TAY:
                tay()

            case .TSX:
                tsx()

            case .TXA:
                txa()

            case .TYA:
                tya()

            case .TXS:
                txs()

            case .PHA:
                pha()

            case .PLA:
                pla()

            case .PHP:
                php()

            case .PLP:
                plp()

            default:
                fatalError()
            }

            if currentState == programCounter {
                programCounter += opcode.count - 1
            }
        }
    }
}

extension CPU {
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
}

extension CPU {
    @discardableResult
    mutating func stack_pop() -> UInt8 {
        stackPointer &+= 1
        return mem_read(STACK + UInt16(stackPointer))
    }

    mutating func stack_push(_ value: UInt8) {
        mem_write(value, at: STACK + UInt16(stackPointer))
        stackPointer &-= 1
    }

    @discardableResult
    mutating func stack_pop_16() -> UInt16 {
        let lo = UInt16(stack_pop())
        let hi = UInt16(stack_pop())
        return hi << 8 | lo
    }

    mutating func stack_push_16(_ value: UInt16) {
        let hi = UInt8(value >> 8)
        let lo = UInt8(value & 0xff)
        stack_push(hi)
        stack_push(lo)
    }
}

extension CPU {
    mutating func adc(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        add_to_register_a(value)
    }

    mutating func sbc(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        add_to_register_a(~value &- 1)
    }

    mutating func and(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        registerA = value & registerA
        update_zero_and_negative_flags(registerA)
    }

    mutating func eor(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        set_register_a(value ^ registerA)
    }

    mutating func ora(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        set_register_a(value | registerA)
    }

    mutating func asl_accumlator() {
        var value = registerA

         status.toggle(.CARRY, to: value >> 7 == 1)

        value &<<= 1
        set_register_a(value)
    }

    mutating func asl(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        var value = mem_read(addr)

         status.toggle(.CARRY, to: value >> 7 == 1)

        value &<<= 1
        mem_write(value, at: addr)
        update_zero_and_negative_flags(value)
    }

    mutating func lsr_accumlator() {
        var value = registerA

         status.toggle(.CARRY, to: value & 1 == 1)

        value &>>= 1
        set_register_a(value)
    }

    mutating func lsr(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        var value = mem_read(addr)

         status.toggle(.CARRY, to: value & 1 == 1)

        value &>>= 1
        mem_write(value, at: addr)
        update_zero_and_negative_flags(value)
    }

    mutating func rol_accumlator() {
        var value = registerA
        let old = status.contains(.CARRY)

         status.toggle(.CARRY, to: value >> 7 == 1)

        value &<<= 1
        if old {
            value |= 1
        }
        set_register_a(value)
    }

    mutating func rol(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        var value = mem_read(addr)
        let old = status.contains(.CARRY)

         status.toggle(.CARRY, to: value >> 7 == 1)

        value &<<= 1
        if old {
            value |= 1
        }
        mem_write(value, at: addr)
        update_zero_and_negative_flags(value)
    }

    mutating func ror_accumlator() {
        var value = registerA
        let old = status.contains(.CARRY)

         status.toggle(.CARRY, to: value & 1 == 1)

        value &>>= 1
        if old {
            value |= 0b1000_0000
        }
        set_register_a(value)
    }

    mutating func ror(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        var value = mem_read(addr)
        let old = status.contains(.CARRY)

         status.toggle(.CARRY, to: value & 1 == 1)

        value &>>= 1
        if old {
            value |= 0b1000_0000
        }
        mem_write(value, at: addr)
        update_zero_and_negative_flags(value)
    }

    mutating func inc(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        var value = mem_read(addr)

        value &+= 1

        mem_write(value, at: addr)
        update_zero_and_negative_flags(value)
    }

    mutating func inx() {
        registerX &+= 1
        update_zero_and_negative_flags(registerX)
    }

    mutating func iny() {
        registerY &+= 1
        update_zero_and_negative_flags(registerY)
    }

    mutating func dec(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        var value = mem_read(addr)

        value &-= 1

        mem_write(value, at: addr)
        update_zero_and_negative_flags(value)
    }

    mutating func dex() {
        registerX &-= 1
        update_zero_and_negative_flags(registerX)
    }

    mutating func dey() {
        registerY &-= 1
        update_zero_and_negative_flags(registerY)
    }

    mutating func cmp(_ mode: AddressingMode, with other: UInt8) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

         status.toggle(.CARRY, to: value <= other)

        update_zero_and_negative_flags(other &- value)
    }

    mutating func bit(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        status.toggle(.CARRY, to: registerA & value == 0)

        let flags = CPUFlags(rawValue: value)
        status.toggle(.NEGATIV, to: flags.contains(.NEGATIV))
        status.toggle(.OVERFLOW, to: flags.contains(.OVERFLOW))

    }

    mutating func lda(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        set_register_a(value)
    }

    mutating func ldx(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        registerX = value
        update_zero_and_negative_flags(registerX)
    }

    mutating func ldy(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        let value = mem_read(addr)

        registerY = value
        update_zero_and_negative_flags(registerY)
    }

    mutating func sta(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        mem_write(registerA, at: addr)
    }

    mutating func stx(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        mem_write(registerX, at: addr)
    }

    mutating func sty(_ mode: AddressingMode) {
        let addr = operand_address(mode)
        mem_write(registerY, at: addr)
    }

    mutating func tax() {
        registerX = registerA
        update_zero_and_negative_flags(registerX)
    }

    mutating func tay() {
        registerY = registerA
        update_zero_and_negative_flags(registerY)
    }

    mutating func tsx() {
        registerX = stackPointer
        update_zero_and_negative_flags(registerX)
    }

    mutating func txa() {
        registerA = registerX
        update_zero_and_negative_flags(registerA)
    }

    mutating func tya() {
        registerA = registerY
        update_zero_and_negative_flags(registerA)
    }

    mutating func txs() {
        stackPointer = registerX
    }

    mutating func pha() {
        stack_push(registerA)
    }

    mutating func pla() {
        let value = stack_pop()
        set_register_a(value)
    }

    mutating func plp() {
        status.rawValue = stack_pop()
        status.remove(.BREAK)
        status.insert(.BREAK2)
    }

    mutating func php() {
        var flags = status
        flags.insert(.BREAK)
        flags.insert(.BREAK2)
        stack_push(flags.rawValue)
    }

    private mutating func update_zero_and_negative_flags(_ result: UInt8) {
        status.toggle(.ZERO, to: result == 0)
        status.toggle(.NEGATIV, to: CPUFlags(rawValue: result).contains(.NEGATIV))
    }

    private mutating func set_register_a(_ value: UInt8) {
        registerA = value
        update_zero_and_negative_flags(registerA)
    }

    private mutating func add_to_register_a(_ value: UInt8) {
        let sum = UInt16(registerA) + UInt16(value) + (status.contains(.CARRY) ? 1 : 0)
        let carry = sum > 0xff

         status.toggle(.CARRY, to: carry)

        let result = UInt8(sum)

        status.toggle(.OVERFLOW, to: (value ^ result) & (result ^ registerA) & 0x80 != 0)
    }

    private mutating func branch(_ condition: Bool) {
        guard condition else { return }
        let jump = Int8(mem_read(programCounter))
        let addr = programCounter &+ 1 &+ UInt16(jump)

        programCounter = addr
    }
}
