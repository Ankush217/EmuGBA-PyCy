# cython: language_level=3
from libc.stdint cimport uint32_t, int32_t, uint8_t, uint16_t
import numpy as np
cimport numpy as np
import warnings

cdef class ARM7TDMI:
    cdef int32_t[::1] reg
    cdef uint32_t cpsr
    cdef bint thumb
    cdef object memory_system  # Python reference to memory.py
    cdef bint debug

    def __cinit__(self, memory_system, bint debug=False):
        self.memory_system = memory_system
        self.debug = debug
        self.reg = np.zeros(16, dtype=np.int32)
        self.cpsr = 0x1F  # Supervisor mode, interrupts disabled
        self.thumb = False
        self.reset()

    cpdef void reset(self):
        """Reset the CPU to initial state"""
        for i in range(16):
            self.reg[i] = 0
        self.reg[15] = 0x08000000  # PC starts at ROM base
        self.cpsr = 0x1F
        self.thumb = False

    cpdef void step(self):
        """Execute one instruction"""
        cdef uint32_t pc = self.reg[15]
        
        # Handle PC alignment
        if self.thumb:
            pc &= ~0x1  # THUMB: 2-byte aligned
        else:
            pc &= ~0x3  # ARM: 4-byte aligned
            
        try:
            if self.thumb:
                instr = self.read_memory16(pc)
                if self.debug:
                    print(f"THUMB @ {hex(pc)}: {hex(instr)}")
                self.reg[15] = pc + 2
                self.execute_thumb(instr)
            else:
                instr = self.read_memory32(pc)
                if self.debug:
                    print(f"ARM @ {hex(pc)}: {hex(instr)}")
                self.reg[15] = pc + 4
                self.execute_arm(instr)
        except Exception as e:
            warnings.warn(f"CPU exception at {hex(pc)}: {str(e)}")
            self.reg[15] += 4 if not self.thumb else 2

    cdef void execute_arm(self, uint32_t instr):
        """Execute ARM-mode instruction"""
        cdef uint32_t cond = (instr >> 28) & 0xF
        if not self.check_condition(cond):
            return

        cdef uint32_t op = (instr >> 21) & 0xF
        cdef uint32_t rn, rd, rm, rs, shift, imm

        # Special cases first
        if (instr & 0x0FFFFFFF) == 0x012FFF1E:  # BX
            rm = instr & 0xF
            target = self.reg[rm]
            self.reg[15] = target & (~0x1)
            self.thumb = (target & 0x1)
            if self.debug:
                print(f"BX to {hex(target)}, mode={'THUMB' if self.thumb else 'ARM'}")
        elif op == 0b1101:  # Branch
            self.execute_branch(instr)
        elif op == 0b0100:  # Data processing
            self.execute_data_processing(instr)
        else:
            warnings.warn(f"Unimplemented ARM instruction: {hex(instr)}")

    cdef void execute_thumb(self, uint16_t instr):
        """Execute THUMB-mode instruction"""
        cdef uint32_t op = (instr >> 10) & 0x3F
        
        if op == 0b010001:  # BL/BLX
            self.execute_thumb_branch(instr)
        else:
            warnings.warn(f"Unimplemented THUMB instruction: {hex(instr)}")

    cdef uint32_t read_memory32(self, uint32_t addr):
        """Read 32-bit value from memory"""
        return self.memory_system.read_u32(addr)

    cdef uint16_t read_memory16(self, uint32_t addr):
        """Read 16-bit value from memory"""
        return self.memory_system.read_u16(addr)

    cdef void write_memory32(self, uint32_t addr, uint32_t value):
        """Write 32-bit value to memory"""
        self.memory_system.write_u32(addr, value)

    cdef void write_memory16(self, uint32_t addr, uint16_t value):
        """Write 16-bit value to memory"""
        self.memory_system.write_u16(addr, value)

    cdef bint check_condition(self, uint32_t cond):
        """Check ARM condition codes"""
        # TODO: Implement proper condition checking
        return True  # Always execute for now

    cdef void execute_branch(self, uint32_t instr):
        """Execute branch instruction"""
        cdef int32_t offset = instr & 0xFFFFFF
        # Sign extend 24-bit offset
        if offset & 0x800000:
            offset |= ~0xFFFFFF
        offset <<= 2
        
        if (instr >> 24) & 1:  # BL (Branch with Link)
            self.reg[14] = self.reg[15] + 4  # Save return address
            if self.debug:
                print(f"BL to {hex(self.reg[15] + offset)}, LR={hex(self.reg[14])}")
        else:
            if self.debug:
                print(f"B to {hex(self.reg[15] + offset)}")
        
        self.reg[15] += offset

    cdef void execute_data_processing(self, uint32_t instr):
        """Execute data processing instruction"""
        warnings.warn(f"Data processing instruction not implemented: {hex(instr)}")

    cdef void execute_thumb_branch(self, uint16_t instr):
        """Execute THUMB branch instruction"""
        warnings.warn(f"THUMB branch not implemented: {hex(instr)}")

    # Python-accessible methods
    cpdef int32_t get_register(self, int index):
        """Get register value (Python accessible)"""
        if 0 <= index < 16:
            return self.reg[index]
        raise IndexError("Register index out of range")

    cpdef void set_register(self, int index, int32_t value):
        """Set register value (Python accessible)"""
        if 0 <= index < 16:
            self.reg[index] = value
        else:
            raise IndexError("Register index out of range")

    cpdef int32_t get_pc(self):
        """Get program counter (Python accessible)"""
        return self.reg[15]

    cpdef void set_pc(self, int32_t value):
        """Set program counter (Python accessible)"""
        self.reg[15] = value
        # Clear pipeline or handle mode changes if needed

    cpdef dict get_registers(self):
        """Get all registers as dictionary (Python accessible)"""
        return {f"r{i}": self.reg[i] for i in range(16)}

    cpdef str get_status(self):
        """Get CPU status string (Python accessible)"""
        return (f"PC: {hex(self.reg[15])}, "
                f"Mode: {'THUMB' if self.thumb else 'ARM'}, "
                f"CPSR: {bin(self.cpsr)}")