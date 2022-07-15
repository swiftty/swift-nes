import Foundation

extension CPU {
    enum AddressingMode {
        case immediate
        case zeroPage
        case zeroPageX
        case zeroPageY
        case absolute
        case absoluteX
        case absoluteY
        case indirectX
        case indirectY
        case none
    }
}

extension CPU {
    func absolute_address(_ mode: AddressingMode, _ addr: UInt16) -> UInt16 {
        switch mode {
        case .zeroPage:
            return UInt16(mem_read(addr))

        case .zeroPageX:
            let pos = mem_read(addr)
            let addr = pos &+ registerX
            return UInt16(addr)

        case .zeroPageY:
            let pos = mem_read(addr)
            let addr = pos &+ registerY
            return UInt16(addr)

        case .absolute:
            return mem_read_16(addr)

        case .absoluteX:
            let pos = mem_read_16(addr)
            let addr = pos &+ UInt16(registerX)
            return addr

        case .absoluteY:
            let pos = mem_read_16(addr)
            let addr = pos &+ UInt16(registerY)
            return addr

        case .indirectX:
            let base = mem_read(addr)
            let ptr = base &+ registerX
            let lo = UInt16(mem_read(UInt16(ptr)))
            let hi = UInt16(mem_read(UInt16(ptr &+ 1)))
            return UInt16(hi) << 8 | lo

        case .indirectY:
            let base = mem_read(addr)
            let lo = UInt16(mem_read(UInt16(base)))
            let hi = UInt16(mem_read(UInt16(base &+ 1)))
            let deref_base = hi << 8 | lo
            return deref_base &+ UInt16(registerY)

        case .immediate, .none:
            fatalError("mode \(mode) is not supported")
        }

    }

    func operand_address(_ mode: AddressingMode) -> UInt16 {
        if mode == .immediate {
            return programCounter
        } else {
            return absolute_address(mode, programCounter)
        }
    }
}
