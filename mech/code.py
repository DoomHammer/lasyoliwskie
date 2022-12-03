# This code is based on midi_visualizer.py by Tod Kurt
# Original source: https://gist.github.com/todbot/ec5c6ed9101fe25bc741e22599f30361
# 31 Aug 2022 - @todbot / Tod Kurt

# This is the moss part

import time
import board
import random

# libraries installed with circup
import usb_midi
import neopixel
import adafruit_pixel_framebuf

# local libraries in CIRCUITPY
import winterbloom_smolmidi as smolmidi

usb_out = usb_midi.ports[1]
usb_in = usb_midi.ports[0]
usb_midi_in = smolmidi.MidiIn(usb_in)

base_note = 36

# We're in a forest, so let's have a nice forest color pallette
# 0xbab86c - Olive Green
# 0x376b2f - Radical Green
# 0x556b2f - Dark Olive Green
# 0x6b632f - Himalaya
# 0x799943 - Lattice Green
play_colors = [0xBAB86C, 0x376B2F, 0x556B2F, 0x6B632F, 0x799943]

dim = 25

# We're using a 16x16 square LED matrix. However to get better effects speed, we're only iterating over half of the matrix.
leds_w = 16
leds_h = 8

leds_num = leds_w * leds_h

leds = neopixel.NeoPixel(board.GP28, leds_num, brightness=1.0, auto_write=False)
leds_framebuf = adafruit_pixel_framebuf.PixelFramebuffer(
    leds, leds_w, leds_h, reverse_x=True, alternating=True
)

leds_framebuf.fill(0x556B2F) # Let's light up the tree with Dark Olive Green
leds_framebuf.display()

playing_notes = []  # which notes are playing


def midi_receive():
    global playing_notes, base_note
    while msg := usb_midi_in.receive():  # get to use walrus operator!
        if msg.type == smolmidi.NOTE_ON:
            note = msg.data[0]
            if base_note == 0:
                base_note = note
            playing_notes.append(note)
        elif msg.type == smolmidi.NOTE_OFF:
            note = msg.data[0]
            try:
                playing_notes.remove(note)
            except ValueError:  # note already removed
                pass


def display_notes():
    # copy old notes to new line
    leds_framebuf.scroll(0, 1)

    # display new notes
    for n in playing_notes:
        multiply = 3
        nn = n % 12
        noct = ((n - base_note) // 12) % len(play_colors)
        # The beat only uses three instruments (so three notes), so all we'd
        # see are three sad columns. Instead, we want to light up three
        # columns per note, each one in a different color.
        for i in range(multiply):
            play_color = play_colors[noct + i]
            leds_framebuf.pixel(nn * multiply + i, 0, play_color)

    # dim all LEDs
    local_dim = random.randint(dim - 5, dim + 5)
    for y in range(leds_h):
        for x in range(leds_w):
            c = leds_framebuf.pixel(x, y)  # this returns an int not a tuple
            ca = (c >> 16) & 255, (c >> 8) & 255, c & 255  # make tuple
            c = (
                max(ca[0] - local_dim, 0),
                max(ca[1] - local_dim, 0),
                max(ca[2] - local_dim, 0),
            )  # dim
            leds_framebuf.pixel(x, y, c)  # put new color back

    leds_framebuf.display()


while True:
    midi_receive()
    display_notes()
