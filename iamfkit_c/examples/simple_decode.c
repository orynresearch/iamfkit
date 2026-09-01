/*
 * simple_decode.c — Example C program demonstrating direct C binding to libiamfkit
 *
 * Compile:
 *   gcc simple_decode.c -I../include -L../build -liamfkit -o simple_decode
 * Run:
 *   ./simple_decode input.iamf output.wav
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "iamfkit.h"

#pragma pack(push, 1)
struct WavHeader {
    char chunk_id[4];        // "RIFF"
    uint32_t chunk_size;
    char format[4];          // "WAVE"
    char subchunk1_id[4];   // "fmt "
    uint32_t subchunk1_size; // 16
    uint16_t audio_format;   // 1 = PCM
    uint16_t num_channels;
    uint32_t sample_rate;
    uint32_t byte_rate;
    uint16_t block_align;
    uint16_t bits_per_sample;// 16
    char subchunk2_id[4];   // "data"
    uint32_t subchunk2_size;
};
#pragma pack(pop)

int main(int argc, char **argv) {
    if (argc < 3) {
        printf("Usage: %s <input.iamf> <output.wav>\n", argv[0]);
        return 1;
    }

    const char *input_filename = argv[1];
    const char *output_filename = argv[2];

    FILE *f_in = fopen(input_filename, "rb");
    if (!f_in) {
        perror("Failed to open input IAMF file");
        return 1;
    }

    fseek(f_in, 0, SEEK_END);
    long file_size = ftell(f_in);
    fseek(f_in, 0, SEEK_SET);

    uint8_t *file_buf = (uint8_t *)malloc(file_size);
    if (fread(file_buf, 1, file_size, f_in) != (size_t)file_size) {
        fprintf(stderr, "Failed to read full input file\n");
        fclose(f_in);
        free(file_buf);
        return 1;
    }
    fclose(f_in);

    // Open iamfkit decoder
    IamfKitDecoderHandle decoder = iamfkit_decoder_open();
    if (!decoder) {
        fprintf(stderr, "Failed to open IAMF decoder\n");
        free(file_buf);
        return 1;
    }

    // Configure 3D Binaural rendering, 16-bit PCM
    iamfkit_decoder_set_sound_system(decoder, IAMFKIT_SOUND_SYSTEM_BINAURAL);
    iamfkit_decoder_set_bit_depth(decoder, IAMFKIT_BIT_DEPTH_16);

    uint32_t offset = 0;
    int is_configured = 0;

    // Header configuration loop
    while (offset < (uint32_t)file_size && !is_configured) {
        uint32_t consumed = 0;
        int res = iamfkit_decoder_configure(
            decoder,
            file_buf + offset,
            file_size - offset,
            &consumed,
            &is_configured
        );
        if (consumed == 0) break;
        offset += consumed;
        if (res == 0) break;
    }

    if (!is_configured) {
        fprintf(stderr, "Failed to configure IAMF decoder\n");
        iamfkit_decoder_close(decoder);
        free(file_buf);
        return 1;
    }

    IamfKitStreamInfo info;
    iamfkit_decoder_get_info(decoder, &info);
    printf("Decoder configured! Sample rate: %u Hz, Channels: %u\n",
           info.sample_rate, info.num_channels);

    // Prepare output WAV file
    FILE *f_out = fopen(output_filename, "wb");
    if (!f_out) {
        perror("Failed to open output WAV file");
        iamfkit_decoder_close(decoder);
        free(file_buf);
        return 1;
    }

    struct WavHeader header;
    memcpy(header.chunk_id, "RIFF", 4);
    header.chunk_size = 36; // placeholder
    memcpy(header.format, "WAVE", 4);
    memcpy(header.subchunk1_id, "fmt ", 4);
    header.subchunk1_size = 16;
    header.audio_format = 1; // PCM
    header.num_channels = (uint16_t)info.num_channels;
    header.sample_rate = info.sample_rate;
    header.bits_per_sample = 16;
    header.byte_rate = info.sample_rate * info.num_channels * (16 / 8);
    header.block_align = info.num_channels * (16 / 8);
    memcpy(header.subchunk2_id, "data", 4);
    header.subchunk2_size = 0; // placeholder

    fwrite(&header, 1, sizeof(header), f_out);

    uint8_t *pcm_out = (uint8_t *)malloc(4096 * info.num_channels * sizeof(int16_t));
    uint32_t total_data_bytes = 0;

    // Decode loop
    while (offset < (uint32_t)file_size) {
        uint32_t consumed = 0;
        int frames = iamfkit_decoder_decode(
            decoder,
            file_buf + offset,
            file_size - offset,
            &consumed,
            pcm_out
        );
        if (consumed == 0 && frames <= 0) break;
        offset += consumed;

        if (frames > 0) {
            uint32_t bytes = frames * info.num_channels * sizeof(int16_t);
            fwrite(pcm_out, 1, bytes, f_out);
            total_data_bytes += bytes;
        }
    }

    // Finalize WAV header
    header.chunk_size = 36 + total_data_bytes;
    header.subchunk2_size = total_data_bytes;
    fseek(f_out, 0, SEEK_SET);
    fwrite(&header, 1, sizeof(header), f_out);

    fclose(f_out);
    free(pcm_out);
    free(file_buf);
    iamfkit_decoder_close(decoder);

    printf("Successfully decoded %u bytes of PCM audio to %s\n", total_data_bytes, output_filename);
    return 0;
}
