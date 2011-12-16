import smf
import sys

filename = sys.argv[1]

print("opening file '%s'..." % filename)
f = smf.SMF(filename)

print("file is in format %d" % f.format)
print("pulses per quarter note is %d" % f.ppqn)
print("number of tracks is %d" % f.number_of_tracks)

for t in f.tracks:
    print("track %d has %d events" % (t.track_number, len(t.events)))
