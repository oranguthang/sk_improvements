"""Play the title screen's demo cycle in Gens and check every demo.

Usage:
    python tests/check_demo_cycle.py [ROM [LST]] [--baseline ROM [LST]]
                                     [--gens GENS.EXE] [--demos N] [--frames N]
                                     [--save FILE]

Needs Gens with the automation extension (Lua hooks), built from
https://github.com/oranguthang/gens_automation; give its Gens.exe with --gens
or the GENS_EXE environment variable. ROM and LST default to sonic3k.bin and
sonic3k.lst in the repository.

For every demo it prints the zone and act, the game frames played, the frames
player 1 spent dead, the furthest X reached and the rings at the end. A
healthy cycle has no deaths. With --baseline, the same demos are played on
that ROM too (build it from an older commit, for example in a git worktree)
and the two are compared frame by frame, keyed by the level frame counter:
player 1's and player 2's position, speed, animation and routine, the rings
and the camera. Changes that should not affect gameplay, such as
optimisations, must give identical traces; lag frames do not matter, since
each line is taken when the level loop starts.

--save keeps the trace (and FILE.baseline) for a closer look; each T line is
demo, zone and act, level frame, then player 1's x, y, x_vel, y_vel, anim and
routine, the rings, the camera X and player 2's x and y, all in hex.

The exit code is 1 if a demo died or the traces differ.
"""
from pathlib import Path
import argparse, os, re, subprocess, sys, tempfile, time

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = Path(__file__).resolve().parent / 'demo_trace.lua'
SYMBOLS = ('LevelLoop', 'Game_mode', 'Current_zone_and_act', 'Level_frame_counter',
           'Player_1', 'Player_2', 'Ring_count', 'Camera_X_pos')
ROUTINE_DEATH = 6

def symbols(lst):
    text = Path(lst).read_bytes().decode('latin-1')
    found = {m[1]: int(m[2], 16) & 0xFFFFFFFF
             for m in re.finditer(r'\b(\w+) :\s+([0-9A-F]+) [-A-Z]', text)}
    missing = [s for s in SYMBOLS if s not in found]
    if missing:
        sys.exit(f'{lst}: symbols not found: {missing}')
    return {s: found[s] for s in SYMBOLS}

def play(gens, rom, lst, demos, frames, save=None):
    S = symbols(lst)
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / 'trace.txt'
        env = dict(os.environ, SK_OUT=str(out), SK_DEMOS=str(demos), SK_FRAMES=str(frames),
                   SK_SYMS=','.join(f'{k}={v:X}' for k, v in S.items()))
        proc = subprocess.Popen([str(gens), '-rom', str(rom), '-lua', str(SCRIPT), '-max-frames', str(frames + 10),
                                 '-turbo', '-nosound'], env=env, cwd=Path(gens).parent,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Gens keeps running, no longer in turbo, after the script ends: stop it then
        start = time.time()
        while proc.poll() is None and time.time() - start < 3600:
            if out.exists() and out.read_text().endswith('END\n'):
                proc.terminate()
                break
            time.sleep(1)
        proc.wait()
        if not out.exists():
            sys.exit(f'{rom}: Gens wrote no trace; is it the automation build with Lua?')
        lines = out.read_text().splitlines()
        if save:
            Path(save).write_text(out.read_text())
    info, trace = {}, {}
    for line in lines:
        p = line.split()
        if p[0] == 'D' and p[2] == 'start':
            info[int(p[1])] = dict(zone=p[5], frames=0, dead=0, max_x=0, rings=0)
        elif p[0] == 'T':
            n, key = int(p[1]), (int(p[1]), p[2], p[3])
            trace[key] = ' '.join(p[4:])
            s = info[n]
            s['frames'] += 1
            s['dead'] += int(p[9], 16) >= ROUTINE_DEATH
            s['max_x'] = max(s['max_x'], int(p[4], 16))
            s['rings'] = int(p[10], 16)
    if 'END' not in lines[-1:]:
        print(f'warning: {rom}: the trace did not finish')
    return info, trace

def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('rom', nargs='?', default=ROOT / 'sonic3k.bin')
    ap.add_argument('lst', nargs='?', default=None)
    ap.add_argument('--baseline', nargs='+', metavar=('ROM', 'LST'))
    ap.add_argument('--gens', default=os.environ.get('GENS_EXE'))
    ap.add_argument('--demos', type=int, default=5, help='the cycle has five demos')
    ap.add_argument('--frames', type=int, default=20000)
    ap.add_argument('--save', metavar='FILE', help='keep the trace of ROM (and FILE.baseline for --baseline)')
    a = ap.parse_args()
    if not a.gens or not Path(a.gens).exists():
        sys.exit('Give Gens.exe (gens_automation) with --gens or GENS_EXE')
    rom = Path(a.rom).resolve()
    lst = Path(a.lst).resolve() if a.lst else rom.with_suffix('.lst')
    info, trace = play(a.gens, rom, lst, a.demos, a.frames, a.save)
    bad = False
    for n, s in sorted(info.items()):
        print(f"demo {n}: zone {s['zone']}, {s['frames']} frames, dead {s['dead']}, "
              f"max x {s['max_x']:X}, rings {s['rings']}")
        bad |= s['dead'] > 0
    if not info:
        print('no demo was played'); bad = True
    if a.baseline:
        brom = Path(a.baseline[0]).resolve()
        blst = Path(a.baseline[1]).resolve() if len(a.baseline) > 1 else brom.with_suffix('.lst')
        _, base = play(a.gens, brom, blst, a.demos, a.frames, a.save and a.save + '.baseline')
        keys = sorted(set(trace) | set(base))
        diff = [k for k in keys if trace.get(k) != base.get(k)]
        print(f'baseline: {len(base)} frames, {len(trace)} frames here, {len(diff)} differ')
        for k in diff[:5]:
            print(f'  demo {k[0]} zone {k[1]} frame {k[2]}: baseline {base.get(k)} / here {trace.get(k)}')
        bad |= bool(diff)
    print('FAIL' if bad else 'OK')
    sys.exit(1 if bad else 0)

if __name__ == '__main__':
    main()
