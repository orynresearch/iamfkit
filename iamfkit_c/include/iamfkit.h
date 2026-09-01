/*
 * iamfkit.h — Standalone C Public Header for IAMF Kit
 * Copyright (c) 2024-2026 Heath Garvin. All rights reserved.
 *
 * Direct C/C++ API for decoding IAMF (Immersive Audio Model and Formats) streams.
 */

#ifndef IAMFKIT_H
#define IAMFKIT_H

#include <stdint.h>
#include <stddef.h>

#ifdef _WIN32
  #ifdef IAMFKIT_BUILD_DLL
    #define IAMFKIT_API __declspec(dllexport)
  #else
    #define IAMFKIT_API __declspec(dllimport)
  #endif
#else
  #define IAMFKIT_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void* IamfKitDecoderHandle;

typedef enum {
    IAMFKIT_SOUND_SYSTEM_STEREO = 0,
    IAMFKIT_SOUND_SYSTEM_5_0 = 1,
    IAMFKIT_SOUND_SYSTEM_7_0 = 2,
    IAMFKIT_SOUND_SYSTEM_5_1_2 = 3,
    IAMFKIT_SOUND_SYSTEM_5_1_4 = 4,
    IAMFKIT_SOUND_SYSTEM_7_1_4 = 5,
    IAMFKIT_SOUND_SYSTEM_3_1_2 = 6,
    IAMFKIT_SOUND_SYSTEM_7_1_2 = 7,
    IAMFKIT_SOUND_SYSTEM_3_1_0 = 8,
    IAMFKIT_SOUND_SYSTEM_MONO = 9,
    IAMFKIT_SOUND_SYSTEM_BINAURAL = 99
} IamfKitSoundSystem;

typedef enum {
    IAMFKIT_BIT_DEPTH_16 = 16,
    IAMFKIT_BIT_DEPTH_24 = 24,
    IAMFKIT_BIT_DEPTH_32 = 32
} IamfKitBitDepth;

typedef struct {
    uint32_t sample_rate;
    uint32_t num_channels;
    uint32_t max_frame_size;
    uint32_t audio_element_count;
    uint32_t mix_presentation_count;
} IamfKitStreamInfo;

/**
 * Open a new IAMF decoder instance.
 * @return IamfKitDecoderHandle or NULL on memory allocation error.
 */
IAMFKIT_API IamfKitDecoderHandle iamfkit_decoder_open(void);

/**
 * Close and free an IAMF decoder instance.
 * @return 0 on success, < 0 on invalid handle.
 */
IAMFKIT_API int iamfkit_decoder_close(IamfKitDecoderHandle handle);

/**
 * Configure output speaker layout or binaural 3D rendering.
 */
IAMFKIT_API int iamfkit_decoder_set_sound_system(IamfKitDecoderHandle handle, IamfKitSoundSystem sound_system);

/**
 * Set output PCM bit depth (16, 24, or 32 bit).
 */
IAMFKIT_API int iamfkit_decoder_set_bit_depth(IamfKitDecoderHandle handle, IamfKitBitDepth bit_depth);

/**
 * Configure EBU R128 loudness target in dB (LKFS).
 * 0.0f disables normalization. Negative values set target (e.g. -23.0f).
 */
IAMFKIT_API int iamfkit_decoder_set_normalization_loudness(IamfKitDecoderHandle handle, float loudness);

/**
 * Enable or disable peak limiter.
 */
IAMFKIT_API int iamfkit_decoder_enable_peak_limiter(IamfKitDecoderHandle handle, int enable);

/**
 * Set head rotation quaternion for binaural 3D rendering in world space.
 */
IAMFKIT_API int iamfkit_decoder_set_head_rotation(IamfKitDecoderHandle handle, float w, float x, float y, float z);

/**
 * Feed configuration header data to the decoder.
 * Sets *is_configured to 1 if decoder configuration is complete.
 * Sets *consumed to bytes read from data buffer.
 */
IAMFKIT_API int iamfkit_decoder_configure(
    IamfKitDecoderHandle handle,
    const uint8_t *data,
    uint32_t size,
    uint32_t *consumed,
    int *is_configured
);

/**
 * Decode a chunk of IAMF frame data into PCM output buffer.
 * Returns number of samples decoded per channel, or < 0 on error.
 */
IAMFKIT_API int iamfkit_decoder_decode(
    IamfKitDecoderHandle handle,
    const uint8_t *data,
    uint32_t size,
    uint32_t *consumed,
    void *pcm_output
);

/**
 * Retrieve high-level stream info.
 */
IAMFKIT_API int iamfkit_decoder_get_info(IamfKitDecoderHandle handle, IamfKitStreamInfo *out_info);

#ifdef __cplusplus
}
#endif

#endif /* IAMFKIT_H */
