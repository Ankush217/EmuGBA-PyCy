# cython: language_level=3
from libc.stdint cimport uint32_t, uint16_t
cimport numpy as np
import numpy as np

cdef class PPU:
    cdef uint32_t[::1] framebuffer
    cdef object memory

    def __init__(self, memory_system):
        self.memory = memory_system
        self.framebuffer = np.zeros(240 * 160, dtype=np.uint32)

    cpdef void render_scanline(self, int line):
        cdef uint16_t color
        cdef uint32_t rgb_color
        cdef int x

        # Mode 3: 240x160, 15-bit BGR
        if line < 160:
            for x in range(240):
                color = self.memory.read_u16(0x06000000 + (line * 240 + x) * 2)
                rgb_color = ((color & 0x1F) << 3) | (((color >> 5) & 0x1F) << 11) | (((color >> 10) & 0x1F) << 19)
                self.framebuffer[line * 240 + x] = rgb_color

    cpdef get_framebuffer(self):
        return np.asarray(self.framebuffer).reshape((160, 240))