"""Check AIZ1's giant-ring passage and height transitions in the assembled ROM.

Requires Python 3 and unicorn 2.1.4. Build with buildS3Complete.lua first.
Usage: python tests/check_aiz1_camera_bounds.py [ROM [LST]]
"""
import argparse
import json
import re
from pathlib import Path

from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE
from unicorn.m68k_const import (
    UC_CPU_M68K_M68000, UC_M68K_REG_A0, UC_M68K_REG_A1,
    UC_M68K_REG_A7, UC_M68K_REG_PC, UC_M68K_REG_SR,
)

ROOT = Path(__file__).resolve().parents[1]


class CPU:
    def __init__(self, rom, symbols):
        self.s = symbols
        self.uc = Uc(UC_ARCH_M68K, UC_MODE_BIG_ENDIAN)
        self.uc.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        self.uc.mem_map(0, 0x800000)
        self.uc.mem_write(0, rom)
        self.uc.mem_map(0xFFFF0000, 0x10000)
        self.uc.reg_write(UC_M68K_REG_SR, 0x2700)
        self.uc.reg_write(UC_M68K_REG_A0, symbols['Player_1'])
        self.deaths = 0
        address = symbols['Kill_Character']

        def killed(uc, pc, size, user):
            self.deaths += 1
            stack = uc.reg_read(UC_M68K_REG_A7)
            uc.reg_write(UC_M68K_REG_PC, self.read(stack, 4))
            uc.reg_write(UC_M68K_REG_A7, stack + 4)

        self.uc.hook_add(UC_HOOK_CODE, killed, begin=address, end=address)

    def addr(self, name):
        return self.s[name] if isinstance(name, str) else name

    def write(self, name, value, size=2):
        self.uc.mem_write(self.addr(name), value.to_bytes(size, 'big'))

    def read(self, name, size=2):
        return int.from_bytes(self.uc.mem_read(self.addr(name), size), 'big')

    def call(self, name):
        stop = 0x7F0000
        self.uc.reg_write(UC_M68K_REG_A7, 0xFFFFF000)
        self.write(0xFFFFF000, stop, 4)
        self.uc.emu_start(self.s[name], stop, count=10000)
        assert self.uc.reg_read(UC_M68K_REG_PC) == stop, name


def passage(rom, symbols, mode, player_x):
    cpu = CPU(rom, symbols)
    p = symbols['Player_1']
    for name, value in {
        'Player_mode': mode, 'Camera_min_X_pos': 0x1308,
        'Camera_max_X_pos': 0x6000, 'Camera_X_pos': player_x - 160,
        'Camera_Y_pos': 0x430, 'Camera_max_Y_pos': 0x430,
        'Camera_target_max_Y_pos': 0x430, 'Camera_pan_X': 160,
        'Distance_from_top': 0x60, 'Distance_from_top_P2': 0x60,
        'Screen_Y_wrap_value': 0x7FF,
    }.items():
        cpu.write(name, value)
    cpu.write('Dynamic_resize_routine', 4, 1)
    cpu.write(p + symbols['x_pos'], player_x)
    cpu.write(p + symbols['y_pos'], 0x4DC)
    cpu.write(p + symbols['spin_dash_flag'], 1, 1)
    # Charge in both directions, then let the pan return to the centre.
    for facing, charging in ((1, 1), (0, 1), (0, 0)):
        cpu.write(p + symbols['status'], facing, 1)
        cpu.write(p + symbols['spin_dash_flag'], charging, 1)
        for frame in range(64):
            cpu.call('Player_PanCamera')
            cpu.call('Player_LevelBound')
            cpu.call('DeformBgLayer')
            assert cpu.deaths == 0, ('stationary player killed beside giant ring', mode, frame)
            assert cpu.read('Camera_Y_pos') == 0x430, ('camera snapped up', mode, frame)
            assert cpu.read('Camera_max_Y_pos') == 0x430, ('death plane raised', mode, frame)
    assert cpu.read('Camera_pan_X') == 160
    # Genuine falls below the level still kill the player.
    cpu.write(p + symbols['y_pos'], 0x511)
    cpu.call('Player_LevelBound')
    assert cpu.deaths == 1, 'death plane was disabled instead of corrected'


def height(rom, symbols, camera_x, pan, *, forced=False, locked=False):
    cpu = CPU(rom, symbols)
    cpu.write('Camera_X_pos', camera_x)
    cpu.write('Camera_pan_X', pan)
    cpu.write('Scroll_lock', int(locked), 1)
    if forced:
        cpu.uc.reg_write(UC_M68K_REG_A0, symbols['Scroll_forced_X_pos'] - symbols['x_pos'])
    cpu.uc.reg_write(UC_M68K_REG_A1, symbols['word_1C60A'])
    cpu.call('Resize_MaxYFromX')
    return cpu.read('Camera_max_Y_pos'), cpu.read('Camera_target_max_Y_pos')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('rom', nargs='?', type=Path, default=ROOT / 'sonic3k.bin')
    parser.add_argument('lst', nargs='?', type=Path)
    args = parser.parse_args()
    rom = args.rom.read_bytes()
    listing = (args.lst or args.rom.with_suffix('.lst')).read_text(errors='replace')
    symbols = {m[1]: int(m[2], 16) & 0xFFFFFFFF for m in
               re.finditer(r'\b([\w.]+) :\s+([0-9A-F]+) [-A-Z]', listing)}
    for mode in range(5):
        for player_x in (0x1B9A, 0x1BA0, 0x1BB0):
            passage(rom, symbols, mode, player_x)
    cases = 0
    for boundary in (0x1650, 0x1B00, 0x2000, 0x2B00, 0x2D80):
        for offset in (-1, 0, 1):
            centred_x = boundary + offset
            original = height(rom, symbols, centred_x, 160)
            for pan in (96, 160, 224):
                assert height(rom, symbols, centred_x + 160 - pan, pan) == original
                # Cutscenes and locked cameras use their actual screen position.
                assert height(rom, symbols, centred_x, pan, forced=True) == original
                assert height(rom, symbols, centred_x, pan, locked=True) == original
                cases += 1
    assert height(rom, symbols, 0, 96) == height(rom, symbols, 0, 160)
    print(json.dumps({'character_modes': 5, 'passage_positions': 3, 'pan_frames_per_position': 192,
                      'height_transition_cases': cases, 'real_falls_still_kill': True,
                      'forced_and_locked_cameras_preserved': True, 'passed': True}, indent=2))


if __name__ == '__main__':
    main()
