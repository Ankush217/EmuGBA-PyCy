class GBAMemory:
    def __init__(self):
        # Define all GBA memory regions
        self.bios = bytearray(16 * 1024)       # 16KB BIOS
        self.ewram = bytearray(256 * 1024)     # 256KB EWRAM
        self.iwram = bytearray(32 * 1024)      # 32KB IWRAM
        self.palette = bytearray(1024)         # Palette RAM
        self.vram = bytearray(96 * 1024)       # VRAM
        self.oam = bytearray(1024)             # OAM
        self.rom = bytearray(32 * 1024 * 1024) # 32MB ROM
        self.sram = bytearray(64 * 1024)       # 64KB SRAM
        self.io = bytearray(0x400)             # I/O Registers

        # Memory map (start, end, region)
        self.memory_map = [
            (0x00000000, 0x00003FFF, self.bios),
            (0x02000000, 0x0203FFFF, self.ewram),
            (0x03000000, 0x03007FFF, self.iwram),
            (0x04000000, 0x040003FF, self.io),
            (0x05000000, 0x050003FF, self.palette),
            (0x06000000, 0x06017FFF, self.vram),
            (0x07000000, 0x070003FF, self.oam),
            (0x08000000, 0x09FFFFFF, self.rom),
            (0x0E000000, 0x0E00FFFF, self.sram)
        ]

    def load_rom(self, rom_path):
        """Load ROM file into memory at 0x08000000"""
        with open(rom_path, "rb") as f:
            rom_data = f.read()
            if len(rom_data) > len(self.rom):
                rom_data = rom_data[:len(self.rom)]
            self.rom[:len(rom_data)] = rom_data

    def _get_region(self, addr):
        """Find which memory region contains an address"""
        addr &= 0x0FFFFFFF  # Handle mirroring
        
        for start, end, region in self.memory_map:
            if start <= addr <= end:
                return region, addr - start
                
        return None, 0  # Unmapped memory

    def read_u32(self, addr):
        """Read 32-bit value from memory (little-endian)"""
        region, offset = self._get_region(addr)
        if region is None:
            return 0
            
        if offset + 4 > len(region):
            return 0
            
        return int.from_bytes(region[offset:offset+4], 'little')

    def read_u16(self, addr):
        """Read 16-bit value from memory (little-endian)"""
        region, offset = self._get_region(addr)
        if region is None:
            return 0
            
        if offset + 2 > len(region):
            return 0
            
        return int.from_bytes(region[offset:offset+2], 'little')

    def write_u32(self, addr, value):
        """Write 32-bit value to memory (little-endian)"""
        region, offset = self._get_region(addr)
        if region is None:
            return
            
        if offset + 4 <= len(region):
            region[offset:offset+4] = value.to_bytes(4, 'little')

    def write_u16(self, addr, value):
        """Write 16-bit value to memory (little-endian)"""
        region, offset = self._get_region(addr)
        if region is None:
            return
            
        if offset + 2 <= len(region):
            region[offset:offset+2] = value.to_bytes(2, 'little')