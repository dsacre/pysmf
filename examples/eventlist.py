import smf
import sys

filename = sys.argv[1]
tracknum = int(sys.argv[2])

print("opening file '%s'..." % filename)
f = smf.SMF(filename)

t = f.tracks[tracknum]

print("---\nlisting binary data for track %d:\n---" % tracknum)
for e in t.events:
    print(e.midi_buffer)

print("---\nlisting decoded events for track %d:\n---" % tracknum)
for e in t.events:
    print(e.decode())
