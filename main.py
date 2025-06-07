import pygame
import numpy as np
from memory import GBAMemory
from cpu import ARM7TDMI

class PPU:
    def __init__(self, memory):
        self.memory = memory
        self.framebuffer = np.zeros((160, 240), dtype=np.uint32)

    def render_scanline(self, line):
        """Render one scanline (simplified Mode 3 rendering)"""
        if line >= 160:
            return
            
        base_addr = 0x06000000 + line * 240 * 2
        for x in range(240):
            color = self.memory.read_u16(base_addr + x * 2)
            # Convert from BGR555 to RGB888
            r = (color & 0x1F) << 3
            g = ((color >> 5) & 0x1F) << 3
            b = ((color >> 10) & 0x1F) << 3
            self.framebuffer[line, x] = (r << 16) | (g << 8) | b

    def get_framebuffer(self):
        return self.framebuffer

class GBAEmulator:
    def __init__(self, debug=False):
        pygame.init()
        self.memory = GBAMemory()
        self.cpu = ARM7TDMI(self.memory, debug=debug)
        self.ppu = PPU(self.memory)
        self.screen = pygame.display.set_mode((240 * 2, 160 * 2))
        self.clock = pygame.time.Clock()
        self.running = False
        self.debug = debug

    def load_rom(self, rom_path):
        self.memory.load_rom(rom_path)
        self.cpu.reset()
        
        if self.debug:
            print("\n=== Initial CPU State ===")
            print(self.cpu.get_status())
            print("Registers:")
            regs = self.cpu.get_registers()
            for i in range(0, 16, 4):
                print(f"R{i}:{hex(regs[f'r{i}'])}  R{i+1}:{hex(regs[f'r{i+1}'])}  R{i+2}:{hex(regs[f'r{i+2}'])}  R{i+3}:{hex(regs[f'r{i+3}'])}")
            print("=======================")

    def run(self):
        self.running = True
        try:
            while self.running:
                self.handle_events()
                self.run_frame()
                self.render()
                self.clock.tick(60)
        except Exception as e:
            print(f"Emulator crashed: {str(e)}")
            if self.debug:
                print("\n=== Final CPU State ===")
                print(self.cpu.get_status())
                print(self.cpu.get_registers())
            raise

    def run_frame(self):
        """Run for approximately one frame's worth of instructions"""
        for _ in range(280896 // 4):  # ~16.78MHz / 60Hz
            self.cpu.step()
            
            if self.debug and _ % 100 == 0:
                print(self.cpu.get_status())

        # Render all scanlines
        for line in range(160):
            self.ppu.render_scanline(line)

    def render(self):
        """Render the current frame to screen"""
        try:
            fb = self.ppu.get_framebuffer()
            
            # Create surface with correct dimensions
            surf = pygame.Surface((240, 160))
            
            # Copy numpy array to surface
            pygame.pixelcopy.array_to_surface(surf, fb)
            
            # Scale to display size
            scaled_surf = pygame.transform.scale(surf, (240 * 2, 160 * 2))
            self.screen.blit(scaled_surf, (0, 0))
            pygame.display.flip()
        except Exception as e:
            raise RuntimeError(f"Rendering error: {str(e)}")

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False

if __name__ == "__main__":
    emu = GBAEmulator(debug=True)
    try:
        emu.load_rom("/Users/apple/Emu/GBA/Pokemon  Emerald.gba")  # Replace with your ROM path
        emu.run()
    except Exception as e:
        print(f"Error: {str(e)}")
    finally:
        pygame.quit()