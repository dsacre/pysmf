# -*- coding: utf-8 -*-
#
# Copyright (c) 2009-2011  Dominic Sacré  <dominic.sacre@gmx.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# ALTHOUGH THIS SOFTWARE IS MADE OF WIN AND SCIENCE, IT IS PROVIDED BY THE
# AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
# THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

"""
A module for reading and writing standard MIDI files, based on libsmf.
"""

from smf cimport *
from libc.stdlib cimport malloc, free
from cpython cimport PY_VERSION_HEX


cdef list _index_helper(n, int length, char *what):
    """simplify handling of single indices and slices by returning a list of all selected indices"""
    if isinstance(n, slice):
        return range(*n.indices(length))
    else:
        indices = slice(n, n + 1).indices(length)
        if indices[0] != indices[1]:
            return [indices[0]]
        else:
            raise IndexError("invalid %s index" % what)

cdef bytes _data_to_bytestring(data):
    """convert a python list/str to a bytestring"""
    if isinstance(data, bytes):
        return data
    elif isinstance(data, unicode):
        return data.encode('latin1')
    else:
        if PY_VERSION_HEX >= 0x03000000:
            return ''.join(map(chr, data)).encode('latin1')
        else:
            return ''.join(map(chr, data))

def data_to_bytestring(data):
    return _data_to_bytestring(data)

cdef list _binary_to_list(unsigned char *buf, int length):
    """convert a C array to a python list"""
    return [buf[i] for i in range(length)]

cdef str _decode(s):
    """convert to standard string type, depending on python version"""
    if PY_VERSION_HEX >= 0x03000000 and isinstance(s, bytes):
        return s.decode()
    else:
        return s

cdef bytes _encode(s):
    """convert unicode to bytes"""
    if isinstance(s, unicode):
        return s.encode()
    else:
        return s


cdef class _SMFReference:
    """base class for all classes referencing an SMF structure"""
    cdef smf_t *_smf
    def __init__(self, _SMFReference parent not None):
        self._smf = parent._smf

cdef class _SMFTrackReference(_SMFReference):
    """base class for all classes referencing a particular track"""
    cdef smf_track_t *_track
    def __init__(self, _SMFReference parent not None, int track_number):
        _SMFReference.__init__(self, parent)
        self._track = smf_get_track_by_number(parent._smf, track_number + 1)

cdef class _SMFEventReference(_SMFReference):
    """base class for all classes referencing a particular event"""
    cdef smf_event_t *_event
    def __init__(self, _SMFReference parent not None, int track_number, int event_number):
        _SMFReference.__init__(self, parent)
        self._event = smf_track_get_event_by_number(smf_get_track_by_number(parent._smf, track_number + 1), event_number + 1)


# forward declarations
cdef class EventIterator(_SMFReference)
cdef class TrackList(_SMFReference)
cdef class Track(_SMFTrackReference)
cdef class TrackEventList(_SMFTrackReference)
cdef class Event(_SMFEventReference)


cdef class SMF(_SMFReference):
    """
    SMF(filename) -> SMF object
    SMF(data=...) -> SMF object
    SMF(number_of_tracks=None, ppqn=None) -> SMF object
    Create a new SMF object, optionally loading MIDI data from a file or from memory.
    """
    def __init__(self, filename=None, *, data=None, number_of_tracks=None, ppqn=None):
        assert not (data and filename)

        if filename:
            # load from MIDI file
            s = _encode(filename)
            self._smf = smf_load(s)
            if not self._smf:
                raise IOError("couldn't load MIDI file: %s" % filename)
        elif data:
            # load from memory
            s = _data_to_bytestring(data)
            self._smf = smf_load_from_memory(<char *>s, len(s))
            if not self._smf:
                raise IOError("couldn't load MIDI data")
        else:
            # create empty smf
            self._smf = smf_new()

        if number_of_tracks:
            for x in range(number_of_tracks - len(self.tracks)):
                self.tracks.append()
        if ppqn:
            self.ppqn = ppqn

    def __dealloc__(self):
        if self._smf:
            smf_delete(self._smf)

    def save(self, filename):
        """
        save(self, filename) -> None
        Save the SMF object to a file.
        """
        s = _encode(filename)
        if smf_save(self._smf, s):
            raise IOError("couldn't save MIDI file: %s" % filename)

#    def dump(self):
#        cdef unsigned char *buf
#        cdef int length
#        if smf_save_to_memory(self._smf, <void **>&buf, &length):
#            raise IOError("couldn't dump MIDI data")
#        r = _binary_to_list(buf, length)
#        free(buf)
#        return r

    def add_track(self, index=None):
        """
        add_track(self, index=None) -> None
        Add an empty track at the end or at the given index.
        """
        if index != None:
            self.tracks.insert(index)
        else:
            self.tracks.append()

    def remove_track(self, track):
        """
        remove_track(self, track) -> None
        Remove the given track.
        """
        n = track.track_number if isinstance(track, Track) else track
        del self.tracks[n]

    def add_event(self, event, track_number, pulses=None, seconds=None):
        """
        add_event(self, event, track_number, pulses=None, seconds=None) -> None
        Add an event to the given track.
        """
        self.tracks[track_number].add_event(event, pulses, seconds)

    property format:
        """SMF format 0 (one track) or 1 (several tracks)"""
        def __get__(self):
            return self._smf.format
        def __set__(self, int format):
            assert not smf_set_format(self._smf, format)

    property ppqn:
        """Pulses per quarter note (read/write)."""
        def __get__(self):
            return self._smf.ppqn
        def __set__(self, int ppqn):
            assert not smf_set_ppqn(self._smf, ppqn)

    property number_of_tracks:
        """Number of tracks (read-only)."""
        def __get__(self):
            return len(self.tracks)

    property events:
        """An iterable object yielding all events on all tracks."""
        def __get__(self):
            return EventIterator(self)

    property tracks:
        """A list-like object providing access to individual tracks."""
        def __get__(self):
            return TrackList(self)


cdef class EventIterator(_SMFReference):

    def __iter__(self):
        smf_rewind(self._smf)
        return self

    def __next__(self):
        cdef smf_event_t *ev = smf_get_next_event(self._smf)
        if ev:
            return _event_reference(self, ev.track_number - 1, ev.event_number - 1)
        else:
            raise StopIteration


cdef class TrackList(_SMFReference):

    def __len__(self):
        return self._smf.number_of_tracks

    def __getitem__(self, n):
        indices = _index_helper(n, len(self), "track")
        if isinstance(n, slice):
            return [Track(self, i) for i in indices]
        else:
            return Track(self, indices[0])

    def __delitem__(self, n):
        # delete in reverse order so the indices of subsequent tracks don't change
        for i in sorted(_index_helper(n, len(self), "track"), reverse=True):
            smf_track_delete(smf_get_track_by_number(self._smf, i + 1))

    def insert(self, index):
        """
        insert(self, index) -> None
        Insert an empty track at the given index.
        """
        cdef int n

        # make sure index is in range
        if index < 0:
            index += len(self)
        index = min(max(index, 0), len(self))

        # store pointers to all tracks after index, and detach those tracks
        cdef int num_tracks_after = len(self) - index
        cdef smf_track_t **tracks_after = <smf_track_t**>malloc(num_tracks_after * sizeof(smf_track_t*))
        for 0 <= n < num_tracks_after:
            tracks_after[n] = smf_get_track_by_number(self._smf, index + 1)
            smf_track_remove_from_smf(tracks_after[n])

        # add the new track
        smf_add_track(self._smf, smf_track_new())

        # re-attach following tracks
        for 0 <= n < num_tracks_after:
            smf_add_track(self._smf, tracks_after[n])

        free(tracks_after)

    def append(self):
        """
        append(self) -> None
        Append an empty track.
        """
        self.insert(len(self))


cdef class Track(_SMFTrackReference):

    def __init__(self, _SMFReference parent, int track_number):
        _SMFTrackReference.__init__(self, parent, track_number)

    def add_event(self, Event event, pulses=None, seconds=None):
        """
        add_event(self, event, pulses=None, seconds=None) -> None
        Add an event to this track.
        """
        assert (pulses != None or seconds != None) and not (pulses != None and seconds != None)
        cdef smf_event_t *ev = smf_event_new_from_pointer(event._event.midi_buffer, event._event.midi_buffer_length)
        if pulses != None:
            smf_track_add_event_pulses(self._track, ev, pulses)
        elif seconds != None:
            smf_track_add_event_seconds(self._track, ev, seconds)
        else:
            raise ValueError("pulses or seconds must be specified")

    property events:
        """A list-like object providing access to all events on this track."""
        def __get__(self):
            return TrackEventList(self, self.track_number)

    property track_number:
        """The index of this track within the containing SMF object."""
        def __get__(self):
            return self._track.track_number - 1


cdef class TrackEventList(_SMFTrackReference):

    def __len__(self):
        return self._track.number_of_events

    def __getitem__(self, n):
        indices = _index_helper(n, len(self), "event")
        if isinstance(n, slice):
            return [_event_reference(self, self._track.track_number - 1, i) for i in indices]
        else:
            return _event_reference(self, self._track.track_number - 1, indices[0])

    def __delitem__(self, n):
        # delete in reverse order so the indices of subsequent events don't change
        for i in sorted(_index_helper(n, len(self), "event"), reverse=True):
            smf_event_delete(smf_track_get_event_by_number(self._track, i + 1))

    def __iter__(self):
        smf_rewind(self._smf)
        return self

    def __next__(self):
        cdef smf_event_t *ev = smf_track_get_next_event(self._track)
        if ev:
            return _event_reference(self, ev.track_number - 1, ev.event_number - 1)
        else:
            raise StopIteration


cdef class Event(_SMFEventReference):
    """
    Event(data) -> MIDI Event object
    Create a new MIDI event.
    """
    def __init__(self, data):
        self._smf = NULL
        self._event = NULL

        if not data:
            # caller needs to take care of initialisation
            return
        #
        # do not call base class __init__()
        #
        s = _data_to_bytestring(data)
        self._event = smf_event_new_from_pointer(<char *>s, len(s))
        # refuse to create invalid MIDI events
        if not smf_event_is_valid(self._event):
            raise ValueError("MIDI event is invalid")

    def __dealloc__(self):
        if not self._smf and self._event:
            smf_event_delete(self._event)

    def decode(self):
        cdef char *c = smf_event_decode(self._event)
        if c:
            s = bytes(c)
            free(c)
            return _decode(s)
        else:
            return ''

    property track_number:
        def __get__(self):
            if self._event.track_number < 1:
                raise AttributeError
            return self._event.track_number - 1

    property event_number:
        def __get__(self):
            if self._event.event_number < 1:
                raise AttributeError
            return self._event.event_number - 1

    property time_pulses:
        def __get__(self):
            if self._event.time_pulses < 0:
                raise AttributeError
            return self._event.time_pulses

    property time_seconds:
        def __get__(self):
            if self._event.time_seconds < 0.0:
                raise AttributeError
            return self._event.time_seconds

    property midi_buffer:
        def __get__(self):
            return _binary_to_list(self._event.midi_buffer, self._event.midi_buffer_length)


cdef Event _event_reference(_SMFReference parent, int track_number, int event_number):
    """create an Event object from an existing event"""
    cdef Event ev = Event(None)
    _SMFEventReference.__init__(ev, parent, track_number, event_number)
    return ev
