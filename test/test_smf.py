from os.path import dirname, join

import py.test
import smf

EMPTY_1_TRACK_120_PPQN = ('MThd\x00\x00\x00\x06\x00\x00\x00\x01\x00\x78'
                          'MTrk\x00\x00\x00\x04\x00\xff\x2f\x00')
TEST_MID1 = join(dirname(__file__), 'test.mid')
TEST_MID2 = join(dirname(__file__), 'test2.mid')

class TestLoadSave:
    def test_new(self):
        a = smf.SMF()
        assert len(a.tracks) == 0
        assert a.ppqn != 0

        b = smf.SMF(number_of_tracks=23)
        assert len(b.tracks) == 23
        assert all(len(tr.events) == 0 for tr in b.tracks)

    def test_load(self):
        a = smf.SMF(TEST_MID1)
        assert len(a.tracks) == 1

        py.test.raises(IOError, smf.SMF, 'nonexistent.mid')

    def test_load_from_memory(self):
        a = smf.SMF(data=EMPTY_1_TRACK_120_PPQN)
        assert a.ppqn == 120
        assert len(a.tracks) == 1

    def test_save(self):
        a = smf.SMF(TEST_MID1)
        a.save(TEST_MID2)
        with open(TEST_MID1, 'rb') as f1, open(TEST_MID2, 'rb') as f2:
            assert f1.read() == f2.read()

        py.test.raises(IOError, a.save, '')

        b = smf.SMF()
        py.test.raises(IOError, b.save, TEST_MID2)

#    def test_save_to_memory(self):
#        a = smf.SMF('test.mid')
#        buf = a.dump()
#        assert len(buf) == 2277


class TestTracks:
    def setup_method(self, method):
        self.smf = smf.SMF()
        for n in range(4):
            self.smf.tracks.append()
        assert len(self.smf.tracks) == 4

    def test_add_track(self):
        self.smf.add_track()
        assert len(self.smf.tracks) == 5
        assert len(self.smf.tracks[4].events) == 0
        self.smf.add_track(2)
        assert len(self.smf.tracks) == 6
        assert all((tr.track_number == n)
                    for n, tr in enumerate(self.smf.tracks))

    def test_remove_track(self):
        del self.smf.tracks[1]
        assert len(self.smf.tracks) == 3
        assert all((tr.track_number == n)
                    for n, tr in enumerate(self.smf.tracks))

    def test_track_slice(self):
        tracks = self.smf.tracks[1:3]
        assert len(tracks) == 2
        assert tracks[0].track_number == 1
        assert tracks[1].track_number == 2

        tracks = self.smf.tracks[3:1:-1]
        assert len(tracks) == 2
        assert tracks[0].track_number == 3
        assert tracks[1].track_number == 2

        del self.smf.tracks[0:3]
        assert len(self.smf.tracks) == 1
