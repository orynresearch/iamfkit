/*
 * iamfkit.c — Unified C wrapper implementation for libiamf
 * Copyright (c) 2024-2026 Heath Garvin. All rights reserved.
 */

#include "iamfkit.h"
#include "IAMF_decoder.h"
#include <stdlib.h>
#include <string.h>

IAMFKIT_API IamfKitDecoderHandle iamfkit_decoder_open(void) {
    return (IamfKitDecoderHandle)IAMF_decoder_open();
}

IAMFKIT_API int iamfkit_decoder_close(IamfKitDecoderHandle handle) {
    if (!handle) return -1;
    return IAMF_decoder_close((IAMF_DecoderHandle)handle);
}

IAMFKIT_API int iamfkit_decoder_set_sound_system(IamfKitDecoderHandle handle, IamfKitSoundSystem sound_system) {
    if (!handle) return -1;
    if (sound_system == IAMFKIT_SOUND_SYSTEM_BINAURAL) {
        return IAMF_decoder_output_layout_set_binaural((IAMF_DecoderHandle)handle);
    }
    return IAMF_decoder_output_layout_set_sound_system((IAMF_DecoderHandle)handle, (IAMF_SoundSystem)sound_system);
}

IAMFKIT_API int iamfkit_decoder_set_bit_depth(IamfKitDecoderHandle handle, IamfKitBitDepth bit_depth) {
    if (!handle) return -1;
    return IAMF_decoder_set_bit_depth((IAMF_DecoderHandle)handle, (uint32_t)bit_depth);
}

IAMFKIT_API int iamfkit_decoder_set_normalization_loudness(IamfKitDecoderHandle handle, float loudness) {
    if (!handle) return -1;
    return IAMF_decoder_set_normalization_loudness((IAMF_DecoderHandle)handle, loudness);
}

IAMFKIT_API int iamfkit_decoder_enable_peak_limiter(IamfKitDecoderHandle handle, int enable) {
    if (!handle) return -1;
    return IAMF_decoder_peak_limiter_enable((IAMF_DecoderHandle)handle, enable ? 1 : 0);
}

IAMFKIT_API int iamfkit_decoder_set_head_rotation(IamfKitDecoderHandle handle, float w, float x, float y, float z) {
    if (!handle) return -1;
    return IAMF_decoder_set_head_rotation((IAMF_DecoderHandle)handle, w, x, y, z);
}

IAMFKIT_API int iamfkit_decoder_configure(
    IamfKitDecoderHandle handle,
    const uint8_t *data,
    uint32_t size,
    uint32_t *consumed,
    int *is_configured
) {
    if (!handle || !data) return -1;
    uint32_t rsize = 0;
    int res = IAMF_decoder_configure((IAMF_DecoderHandle)handle, data, size, &rsize);
    if (consumed) *consumed = rsize;
    if (is_configured) *is_configured = (res == 0) ? 1 : 0;
    return res;
}

IAMFKIT_API int iamfkit_decoder_decode(
    IamfKitDecoderHandle handle,
    const uint8_t *data,
    uint32_t size,
    uint32_t *consumed,
    void *pcm_output
) {
    if (!handle || !data || !pcm_output) return -1;
    uint32_t rsize = 0;
    int samples = IAMF_decoder_decode((IAMF_DecoderHandle)handle, data, (int32_t)size, &rsize, pcm_output);
    if (consumed) *consumed = rsize;
    return samples;
}

IAMFKIT_API int iamfkit_decoder_get_info(IamfKitDecoderHandle handle, IamfKitStreamInfo *out_info) {
    if (!handle || !out_info) return -1;
    memset(out_info, 0, sizeof(IamfKitStreamInfo));

    IAMF_StreamInfo *info = IAMF_decoder_get_stream_info((IAMF_DecoderHandle)handle);
    if (!info) return -1;

    out_info->max_frame_size = info->max_frame_size;
    out_info->sample_rate = info->iamf_stream_info.sampling_rate;
    out_info->audio_element_count = info->iamf_stream_info.audio_element_count;
    out_info->mix_presentation_count = info->iamf_stream_info.mix_presentation_count;
    out_info->num_channels = 2; // Default binaural/stereo output channels

    IAMF_decoder_free_stream_info(info);
    return 0;
}
