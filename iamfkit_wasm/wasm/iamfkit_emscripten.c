/*
 * iamfkit_emscripten.c — Emscripten WebAssembly C wrapper for iamfkit
 * Copyright (c) 2024-2026 Heath Garvin. All rights reserved.
 */

#include <emscripten/emscripten.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "iamfkit.h"

EMSCRIPTEN_KEEPALIVE
IamfKitDecoderHandle wasm_iamfkit_decoder_open(void) {
    return iamfkit_decoder_open();
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_close(IamfKitDecoderHandle handle) {
    return iamfkit_decoder_close(handle);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_set_sound_system(IamfKitDecoderHandle handle, int sound_system) {
    return iamfkit_decoder_set_sound_system(handle, (IamfKitSoundSystem)sound_system);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_set_bit_depth(IamfKitDecoderHandle handle, int bit_depth) {
    return iamfkit_decoder_set_bit_depth(handle, (IamfKitBitDepth)bit_depth);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_set_normalization_loudness(IamfKitDecoderHandle handle, float loudness) {
    return iamfkit_decoder_set_normalization_loudness(handle, loudness);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_enable_peak_limiter(IamfKitDecoderHandle handle, int enable) {
    return iamfkit_decoder_enable_peak_limiter(handle, enable);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_set_head_rotation(IamfKitDecoderHandle handle, float w, float x, float y, float z) {
    return iamfkit_decoder_set_head_rotation(handle, w, x, y, z);
}

EMSCRIPTEN_KEEPALIVE
uint8_t* wasm_malloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void wasm_free(void* ptr) {
    free(ptr);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_configure(
    IamfKitDecoderHandle handle,
    const uint8_t *data,
    uint32_t size,
    uint32_t *consumed_out,
    int *is_configured_out
) {
    return iamfkit_decoder_configure(handle, data, size, consumed_out, is_configured_out);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_decode(
    IamfKitDecoderHandle handle,
    const uint8_t *data,
    uint32_t size,
    uint32_t *consumed_out,
    void *pcm_output
) {
    return iamfkit_decoder_decode(handle, data, size, consumed_out, pcm_output);
}

EMSCRIPTEN_KEEPALIVE
int wasm_iamfkit_decoder_get_info(
    IamfKitDecoderHandle handle,
    uint32_t *out_sample_rate,
    uint32_t *out_num_channels
) {
    if (!handle) return -1;
    IamfKitStreamInfo info;
    int res = iamfkit_decoder_get_info(handle, &info);
    if (res == 0) {
        if (out_sample_rate) *out_sample_rate = info.sample_rate;
        if (out_num_channels) *out_num_channels = info.num_channels;
    }
    return res;
}
