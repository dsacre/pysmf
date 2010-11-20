cdef extern from 'smf.h':
    ctypedef struct smf_t:
        int format
        int ppqn
        int number_of_tracks

    ctypedef struct smf_track_t:
        int track_number
        int number_of_events

    ctypedef struct smf_event_t:
        int track_number
        int event_number
        int time_pulses
        double time_seconds
        unsigned char *midi_buffer
        int midi_buffer_length

    smf_t *smf_new()
    smf_t *smf_load(char *file_name)
    smf_t *smf_load_from_memory(void *buffer, int buffer_length)
    int smf_save(smf_t *smf, char *file_name)
#    int smf_save_to_memory(smf_t *smf, void **buffer, int *buffer_length)
    void smf_delete(smf_t *smf)
    int smf_set_format(smf_t *smf, int format)
    int smf_set_ppqn(smf_t *smf, int ppqn)
    void smf_rewind(smf_t *smf)
    smf_event_t *smf_get_next_event(smf_t *smf)
    smf_track_t *smf_get_track_by_number(smf_t *smf, int track_number)
    void smf_add_track(smf_t *smf, smf_track_t *track)

    smf_track_t *smf_track_new()
    void smf_track_remove_from_smf(smf_track_t *track)
    void smf_track_delete(smf_track_t *track)
    smf_event_t *smf_track_get_next_event(smf_track_t *track)
    smf_event_t *smf_track_get_event_by_number(smf_track_t *track, int event_number)
    void smf_track_add_event(smf_track_t *track, smf_event_t *event)
    void smf_track_add_event_pulses(smf_track_t *track, smf_event_t *event, int pulses)
    void smf_track_add_event_seconds(smf_track_t *track, smf_event_t *event, double seconds)

    smf_event_t *smf_event_new_from_pointer(void *midi_data, int len)
    void smf_event_delete(smf_event_t *event)
    int smf_event_is_valid(smf_event_t *event)
    char *smf_event_decode(smf_event_t *event)
