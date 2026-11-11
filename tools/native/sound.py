"""Build-time sound tables for the native engine (used by convert.py).

The engine (native/sound.asm) runs the game's own music and sound effect
data, from its bank 1 (a copy of which is put in SOUND_BANK, at the
addresses the data's jumps name). Its notes are indices into the game's
MusicalNotesTbl, NES square timer values (f = CPU / 16 / (t + 1); the
triangle sounds an octave lower, f = CPU / 32 / (t + 1)). Here each note
becomes POKEY dividers:

* SQ1 on channels 1+2 joined, clocked at 1.79MHz: f = 1789790 / 2 / (N + 7),
  16 bits, close to exact.
* SQ2 (and the sound effects' tones) on channel 3 and the triangle on
  channel 4, each 8 bits at 64kHz: f = 63921 / 2 / (N + 1). A note too low
  for 8 bits goes up an octave.
* The noise channel's 16 periods (NES timer steps) become channel 3's
  divider for POKEY's 17-bit noise at 64kHz.
"""
import sys

NOTES = 73                      # $80-$C8.
NES_CPU = 1789773
POKEY_FAST = 1789790
POKEY_64K = 63921
NOISE_PERIODS = [4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068]


# Each sound effect's noise texture on POKEY (AUDC's distortion bits, the
# port's own: the NES has only its white noise): $80 white noise, as the
# NES's; $00 crackling (17-bit noise through the 5-bit), the dragon's fire;
# $C0 buzzing (the 4-bit), the hits' crunch and the force field's.
NOISE_DIST = [0xC0, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xC0, 0x80, 0x80, 0xC0,
              0xC0, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00]


def note_timers(rom):
    """The NES timer of each note (MusicalNotesTbl, from note $80)."""
    return [w & 0x7FF for w in rom.words("MusicalNotesTbl", NOTES)]


def divider_8bit(f):
    while True:
        n = round(POKEY_64K / 2 / f) - 1
        if n <= 255:
            return max(n, 0)
        f *= 2


def tables(rom):
    """(SQ1 16-bit dividers, SQ2 8-bit, triangle 8-bit, noise 8-bit)."""
    sq1, sq2, tri = [], [], []
    for t in note_timers(rom):
        f = NES_CPU / 16 / (t + 1)
        sq1.append(min(0xFFFF, max(0, round(POKEY_FAST / 2 / f) - 7)))
        sq2.append(divider_8bit(f))
        tri.append(divider_8bit(f / 2))
    noise = [min(255, max(0, round(POKEY_64K * p / NES_CPU) - 1)) for p in NOISE_PERIODS]
    return sq1, sq2, tri, noise


def resume_music(rom):
    """The music each game map resumes (ResumeMusicTbl), by map number."""
    return rom.table("ResumeMusicTbl", 30)


# ---------------------------------------------------------------------------
# The music and sound effects, converted to the engine's own format.
#
# The game keeps each channel's part as a byte stream read by its sound
# engine (Bank01's UpdateSound on): notes, lengths, and control bytes, some
# parts shared as subroutines (MCTL_JUMP saves where to come back to,
# MCTL_RETURN goes there), loops made of jumps back. Here each part is read
# through as the game's engine reads it, once, and written again as one
# straight stream: subroutines written out in place, loops a GOTO back to
# where the same state was met, the space between notes (MCTL_ADD_SPACE) written as
# a wait after each, the sweep units' bytes and no-ops left out. The
# engine (native/sound.asm) then only plays: a note sets the pitch and goes
# on, a wait ends the frame's reading.
#
# The format (a byte stream; 16-bit addresses are in the sound bank):
#   $00          the end (the channel stops)
#   $01-$7F      wait that many counts
#   $80-$C8      a note ($80 + its index in the note tables)
#   $E0-$EF      the noise channel's period (low nibble)
#   $F0 n        tempo n
#   $F1 n        control byte 0 (envelope, volume, duty, length counter)
#   $F2 n        the noise channel's control byte 0
#   $F3 n        wait n counts (n of $80 or more)
#   $F4 lo hi    go on at address hi:lo
#   $F5 n        the note offset (shared by the channels: the dungeons'
#                tunes step their key down with it as they play)
#   (Any other byte from $C9 on is not written.)

MUSIC = 27                      # MSC_NOSOUND to MSC_LEVEL_UP.
SFX = 22                        # SFX_FFDAMAGE to SFX_FIRE.
SOUND_BASE = 0x8000             # Where the converted data starts in its bank.
OP_TEMPO, OP_CNTRL0, OP_NOISE_VOL, OP_WAIT, OP_GOTO, OP_OFFSET = 0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5


def channel_part(rom, start, noise):
    """A channel's part from START, read as the game reads it, written in the
    engine's format: (bytes, [(index in bytes, target position)] of GOTOs).
    NOISE: the noise channel's (the sound effects'), whose notes do not end
    a frame's reading."""
    out, gotos, seen = bytearray(), [], {}
    addr, ret, quiet = start, None, 0

    def byte():
        nonlocal addr
        b = rom.read(1, addr, 1)[0]
        addr += 1
        return b

    while True:
        state = (addr, ret, quiet)
        if state in seen:
            gotos.append((len(out), seen[state]))
            out += bytes([OP_GOTO, 0, 0])
            return bytes(out), gotos
        seen[state] = len(out)
        b = byte()
        if b == 0xFE:                   # MCTL_JUMP: a word, the return kept.
            lo, hi = byte(), byte()
            ret, addr = addr, lo | hi << 8
        elif b == 0xFF:                 # MCTL_TEMPO.
            out += bytes([OP_TEMPO, byte()])
        elif b == 0xFC:                 # MCTL_NO_OP.
            pass
        elif b == 0xFD:                 # MCTL_RETURN.
            addr = ret
        elif b == 0xFA:                 # MCTL_CNTRL1: the sweep (not done).
            byte()
        elif b == 0xFB:                 # MCTL_CNTRL0.
            out += bytes([OP_CNTRL0, byte()])
        elif b == 0xF8:                 # MCTL_NOISE_VOL.
            out += bytes([OP_NOISE_VOL, byte()])
        elif b == 0xF9:                 # MCTL_NOTE_OFST.
            out += bytes([OP_OFFSET, byte()])
        elif b == 0xF6:                 # MCTL_END_SPACE.
            quiet = 0
        elif b == 0xF7:                 # MCTL_ADD_SPACE.
            quiet = byte()
        elif b >= 0xE0:                 # MCTL_NOISE_CFG.
            out.append(0xE0 | b & 0x0F)
        elif b >= 0x80:                 # A note (the engine adds the offset).
            out.append(b)
            if not noise and quiet:
                out += bytes([quiet] if quiet < 0x80 else [OP_WAIT, quiet])
        else:                           # A length: 0 the end.
            out.append(b)
            if b == 0:
                return bytes(out), gotos


def converted(rom):
    """The sound bank's data, each music's 3 parts' addresses (SQ1, SQ2,
    TRI), and each sound effect's."""
    table = rom.words("MscStrtIndxTbl", MUSIC * 3)
    no_sound = table[0:3]               # Music 0's: a missing part plays it.
    data, placed = bytearray(), {}

    def place(start, noise):
        key = (start, noise)
        if key not in placed:
            part, gotos = channel_part(rom, start, noise)
            at = len(data)
            part = bytearray(part)
            for i, target in gotos:
                a = SOUND_BASE + at + target
                part[i + 1:i + 3] = bytes([a & 0xFF, a >> 8])
            data.extend(part)
            placed[key] = SOUND_BASE + at
        return placed[key]

    music = []
    for m in range(MUSIC):
        starts = [table[m * 3 + c] or no_sound[c] for c in range(3)]
        music.append([place(s, False) for s in starts])
    sfx = [place(s, True) for s in rom.words("SFXStrtIndxTbl", SFX)]
    return bytes(data), music, sfx


# ---------------------------------------------------------------------------
# The check, run by every build: each music and sound effect played for a
# while both ways, by a model of the game's engine on the ROM's data and by
# a model of the native engine on the converted data, frame by frame; what
# each writes to the channels (control bytes, notes with the offset added,
# the noise's period and control, the tempo) must be the same.

CHECK_FRAMES = 3600             # A minute of each music.
SFX_FRAMES = 300


class GameModel:
    """The game's engine (UpdateSound, GetNextNote, ProcessAudioByte), its
    hardware writes logged."""

    def __init__(self, rom):
        self.rom = rom
        self.ptr, self.ret = [0] * 4, [0] * 4
        self.length, self.quiet = [0] * 4, [0] * 4
        self.tempo, self.counter, self.offset = 0xFF, 0, 0
        self.sfx, self.log = False, []

    def start_music(self, music):
        table = self.rom.words("MscStrtIndxTbl", MUSIC * 3)
        for c in range(3):
            self.ptr[c] = table[music * 3 + c] or table[c]
            self.length[c] = 1
            self.quiet[c] = 0
        self.offset = 0

    def start_sfx(self, sfx):
        self.ptr[3] = self.rom.words("SFXStrtIndxTbl", SFX)[sfx]
        self.length[3] = 1
        self.sfx = True

    def byte(self, c):
        b = self.rom.read(1, self.ptr[c], 1)[0]
        self.ptr[c] += 1
        return b

    def next_note(self, c, hw):
        if self.length[c] == 0:
            return 0
        self.length[c] -= 1
        if self.length[c]:
            return self.length[c]
        while True:
            b = self.byte(c)
            if b == 0xFE:
                lo, hi = self.byte(c), self.byte(c)
                self.ret[c], self.ptr[c] = self.ptr[c], lo | hi << 8
            elif b == 0xFF:
                self.tempo = self.byte(c)
                self.log.append(("tempo", self.tempo))
            elif b == 0xFC:
                pass
            elif b == 0xFD:
                self.ptr[c] = self.ret[c]
            elif b == 0xFA:
                self.byte(c)
            elif b == 0xFB:
                self.log.append(("cntrl0", hw, self.byte(c)))
            elif b == 0xF8:
                self.log.append(("cntrl0", "noise", self.byte(c)))
            elif b == 0xF9:
                self.offset = self.byte(c)
            elif b == 0xF6:
                self.quiet[c] = 0
            elif b == 0xF7:
                self.quiet[c] = self.byte(c)
            elif b >= 0xE0:
                self.log.append(("noise", b & 0x0F))
            elif b >= 0x80:
                self.log.append(("note", hw, min((b + self.offset) & 0x7F, NOTES - 1)))
                if c != 3 and self.quiet[c]:
                    self.length[c] = self.quiet[c]
                    return self.length[c]
            else:
                self.length[c] = b
                return b

    def frame(self):
        if self.sfx:
            keep, self.offset = self.offset, 0
            going = self.next_note(3, "sq2")
            self.offset = keep
            if not going:
                self.sfx = False
                self.log.append(("sfx end",))
        total = self.counter + self.tempo   # A step each time the count
        self.counter = total & 0xFF         # passes 256, then less 150.
        if total >= 256:
            self.counter = (self.counter - 150) & 0xFF
            self.next_note(2, "tri")
            self.next_note(1, "dmc" if self.sfx else "sq2")
            self.next_note(0, "sq1")
        self.log.append(("frame",))


class NativeModel(GameModel):
    """The native engine on the converted data (same timing, same logging)."""

    def __init__(self, rom, data, music, sfx):
        super().__init__(rom)
        self.data, self.music_at, self.sfx_at = data, music, sfx

    def start_music(self, music):
        for c in range(3):
            self.ptr[c] = self.music_at[music][c]
            self.length[c] = 1
        self.offset = 0

    def start_sfx(self, sfx):
        self.ptr[3] = self.sfx_at[sfx]
        self.length[3] = 1
        self.sfx = True

    def byte(self, c):
        b = self.data[self.ptr[c] - SOUND_BASE]
        self.ptr[c] += 1
        return b

    def next_note(self, c, hw):
        if self.length[c] == 0:
            return 0
        self.length[c] -= 1
        if self.length[c]:
            return self.length[c]
        while True:
            b = self.byte(c)
            if b == OP_TEMPO:
                self.tempo = self.byte(c)
                self.log.append(("tempo", self.tempo))
            elif b == OP_CNTRL0:
                self.log.append(("cntrl0", hw, self.byte(c)))
            elif b == OP_NOISE_VOL:
                self.log.append(("cntrl0", "noise", self.byte(c)))
            elif b == OP_WAIT:
                self.length[c] = self.byte(c)
                return self.length[c]
            elif b == OP_GOTO:
                lo, hi = self.byte(c), self.byte(c)
                self.ptr[c] = lo | hi << 8
            elif b == OP_OFFSET:
                self.offset = self.byte(c)
            elif b >= 0xE0:
                self.log.append(("noise", b & 0x0F))
            elif b >= 0x80:
                self.log.append(("note", hw, min((b + self.offset) & 0x7F, NOTES - 1)))
            else:
                self.length[c] = b
                return b


def check(rom, data, music, sfx):
    """Exit if any music or sound effect plays differently converted."""
    for m in range(MUSIC):
        a, b = GameModel(rom), NativeModel(rom, data, music, sfx)
        for model in (a, b):
            model.start_music(m)
            for _ in range(CHECK_FRAMES):
                model.frame()
        if a.log != b.log:
            sys.exit(f"sound: music {m} plays differently converted")
    for e in range(SFX):
        a, b = GameModel(rom), NativeModel(rom, data, music, sfx)
        for model in (a, b):
            model.start_music(0)
            model.start_sfx(e)
            for _ in range(SFX_FRAMES):
                model.frame()
        if a.log != b.log:
            sys.exit(f"sound: sound effect {e} plays differently converted")
