import smf

# create a new SMF object
f = smf.SMF()

# add a track
f.add_track()

# add a single note (middle C with a duration of one second)
f.add_event(smf.Event([0x90, 60, 127]), 0, seconds=0.0)
f.add_event(smf.Event([0x80, 60, 0]), 0, seconds=1.0)

# save as a new standard MIDI file
f.save('test.mid')
