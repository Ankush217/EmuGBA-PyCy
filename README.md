
# PyGBA-Cython

A high-performance Game Boy Advance emulator written in Python and Cython, featuring an ARM7TDMI CPU core and Mode 3 PPU renderer. Designed for accuracy, speed, and easy extensibility.

---

## Features

- **ARM7TDMI CPU core** implemented in Cython for fast emulation  
- **PPU (Picture Processing Unit)** supporting Mode 3 rendering with framebuffer output  
- **Accurate memory mapping** of GBA regions (BIOS, EWRAM, IWRAM, VRAM, SRAM, ROM, etc.)  
- Uses **NumPy arrays** for efficient framebuffer manipulation  
- **Pygame integration** for window creation and rendering  
- Debug mode with CPU register and status printing  
- Modular design with separate CPU, PPU, and memory components  

---

## Requirements

- Python 3.8+  
- [Pygame](https://www.pygame.org/)  
- [NumPy](https://numpy.org/)  
- [Cython](https://cython.org/)  

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Ankush217/EmuGBA-PyCy.git
   cd GBA
````

2. Build the Cython modules:

   python setup.py build_ext --inplace
   ```

3. Install Python dependencies:

   ```bash
   pip install -r requirements.txt
   ```

---

## Usage

1. Place your `.gba` ROM file somewhere accessible.

2. Edit `main.py` to set your ROM path:
   emu.load_rom("/path/to/your/rom.gba")

3. Run the emulator:

   ```bash
   python main.py
   ```

## Project Structure

* `main.py` — Main emulator loop integrating CPU, PPU, and memory
* `cpu.pyx` — Cython implementation of ARM7TDMI CPU core
* `ppu.pyx` — Cython PPU rendering code for Mode 3 framebuffer
* `memory.py` — GBA memory map and read/write handlers
* `setup.py` — Build script for compiling Cython extensions

---

## Status & Roadmap

**Current status:**

* The emulator is in early development and not fully functional.
* It can barely read ROM headers at this stage.
* Basic ARM and Thumb instruction support with branching is partially implemented.
* Mode 3 rendering works with framebuffer output.
* Memory mapping and ROM loading are implemented but incomplete.

**Upcoming work:**

* Complete full ARM7TDMI instruction set implementation
* Add support for other PPU modes and hardware features (DMA, interrupts)
* Implement input handling and audio support
* Optimize performance and increase test coverage

---

## License

MIT License — use, modify, and contribute freely.

---

## Contributing

Contributions are welcome! Open issues for bugs or feature requests, and submit pull requests for improvements.

---

## Acknowledgments

Inspired by GBA hardware documentation and emulator projects. Special thanks to the Python, Cython, Pygame, and NumPy communities.

---

Enjoy your retro gaming adventure with PyGBA-Cython!
