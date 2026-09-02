#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "IAMF_decoder.h"

#ifdef __cplusplus
extern "C" {
#endif
void set_log_level(int level);
#ifdef __cplusplus
}
#endif

struct wav_header {
    char riff[4];           // "RIFF"
    int32_t flength;        // file length - 8
    char wave[4];           // "WAVE"
    char fmt[4];            // "fmt "
    int32_t chunk_size;     // size of fmt chunk (16 for PCM)
    int16_t format_tag;     // 1 for PCM
    int16_t num_chans;      // number of channels
    int32_t srate;          // sample rate
    int32_t bpsec;          // bytes per second
    int16_t block_align;    // bytes per frame
    int16_t bps;            // bits per sample (16)
    char data[4];           // "data"
    int32_t dlength;        // data length
};

void init_wav_header(struct wav_header *header, int channels, int sample_rate) {
    header->riff[0] = 'R'; header->riff[1] = 'I'; header->riff[2] = 'F'; header->riff[3] = 'F';
    header->flength = 36;
    header->wave[0] = 'W'; header->wave[1] = 'A'; header->wave[2] = 'V'; header->wave[3] = 'E';
    header->fmt[0] = 'f';  header->fmt[1] = 'm';  header->fmt[2] = 't';  header->fmt[3] = ' ';
    header->chunk_size = 16;
    header->format_tag = 1; // PCM
    header->num_chans = channels;
    header->srate = sample_rate;
    header->bps = 16;
    header->block_align = channels * 2;
    header->bpsec = sample_rate * header->block_align;
    header->data[0] = 'd'; header->data[1] = 'a'; header->data[2] = 't'; header->data[3] = 'a';
    header->dlength = 0;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        printf("Usage: %s <input.iamf> <output.wav> [layout_type] [log_level]\n", argv[0]);
        printf("  layout_type:\n");
        printf("    0: Sound System A (0+2+0 / Stereo, default)\n");
        printf("    1: Sound System B (0+5+0)\n");
        printf("    2: Sound System C (2+5+0)\n");
        printf("    3: Sound System D (4+5+0)\n");
        printf("    4: Sound System E (4+5+1)\n");
        printf("    5: Sound System F (3+7+0)\n");
        printf("    6: Sound System G (4+9+0)\n");
        printf("    7: Sound System H (9+10+3)\n");
        printf("    8: Sound System I (0+7+0)\n");
        printf("    9: Sound System J (4+7+0)\n");
        printf("    10: Sound System EXT 7.1.2 (2+7+0)\n");
        printf("    11: Sound System EXT 3.1.2 (2+3+0)\n");
        printf("    12: Sound System MONO (0+1+0)\n");
        printf("    13: Sound System EXT 9.1.6 (6+9+0)\n");
        printf("    14: Sound System EXT 7.1.5.4 (5+7+4)\n");
        printf("    20: Binaural\n");
        printf("  log_level:\n");
        printf("    0..5 (default: 2 / WARNING. Set to 5 for trace level logs)\n");
        return 1;
    }

    const char *filename = argv[1];
    const char *wav_filename = argv[2];
    int layout_type = (argc >= 4) ? atoi(argv[3]) : 0;
    int log_level = (argc >= 5) ? atoi(argv[4]) : 2;

    set_log_level(log_level);

    FILE *f = fopen(filename, "rb");
    if (!f) {
        printf("Failed to open input file: %s\n", filename);
        return 1;
    }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    uint8_t *buffer = (uint8_t *)malloc(size);
    if (!buffer) {
        printf("Failed to allocate memory for file buffer\n");
        fclose(f);
        return 1;
    }

    if (fread(buffer, 1, size, f) != size) {
        printf("Failed to read input file\n");
        free(buffer);
        fclose(f);
        return 1;
    }
    fclose(f);

    printf("Read %ld bytes from %s\n", size, filename);

    IAMF_DecoderHandle handle = IAMF_decoder_open();
    if (!handle) {
        printf("Failed to open decoder\n");
        free(buffer);
        return 1;
    }

    int ret;
    int num_channels = 2; // Default to stereo

    if (layout_type == 20) {
        ret = IAMF_decoder_output_layout_set_binaural(handle);
        printf("Set binaural layout: %d\n", ret);
        num_channels = IAMF_layout_binaural_channels_count();
    } else {
        IAMF_SoundSystem ss = SOUND_SYSTEM_A;
        switch (layout_type) {
            case 0: ss = SOUND_SYSTEM_A; break;
            case 1: ss = SOUND_SYSTEM_B; break;
            case 2: ss = SOUND_SYSTEM_C; break;
            case 3: ss = SOUND_SYSTEM_D; break;
            case 4: ss = SOUND_SYSTEM_E; break;
            case 5: ss = SOUND_SYSTEM_F; break;
            case 6: ss = SOUND_SYSTEM_G; break;
            case 7: ss = SOUND_SYSTEM_H; break;
            case 8: ss = SOUND_SYSTEM_I; break;
            case 9: ss = SOUND_SYSTEM_J; break;
            case 10: ss = SOUND_SYSTEM_EXT_712; break;
            case 11: ss = SOUND_SYSTEM_EXT_312; break;
            case 12: ss = SOUND_SYSTEM_MONO; break;
            case 13: ss = SOUND_SYSTEM_EXT_916; break;
            case 14: ss = SOUND_SYSTEM_EXT_7154; break;
            default:
                printf("Unknown layout type %d, defaulting to Sound System A\n", layout_type);
                ss = SOUND_SYSTEM_A;
                break;
        }
        ret = IAMF_decoder_output_layout_set_sound_system(handle, ss);
        printf("Set sound system: %d (ret=%d)\n", ss, ret);
        num_channels = IAMF_layout_sound_system_channels_count(ss);
    }

    printf("Output channels count: %d\n", num_channels);

    ret = IAMF_decoder_set_bit_depth(handle, 16);
    printf("Set bit depth 16: %d\n", ret);

    // Run configure loop
    uint32_t offset = 0;
    while (offset < size) {
        uint32_t rsize = 0;
        ret = IAMF_decoder_configure(handle, buffer + offset, size - offset, &rsize);
        if (rsize == 0) {
            printf("Configure made no progress!\n");
            break;
        }
        offset += rsize;
        if (ret == IAMF_OK) {
            printf("Decoder configured successfully at offset %u!\n", offset);
            break;
        }
    }

    // Query sampling rate
    int sample_rate = 16000; // default fallback
    IAMF_StreamInfo *info = IAMF_decoder_get_stream_info(handle);
    if (info) {
        sample_rate = info->iamf_stream_info.sampling_rate;
        printf("Detected stream sampling rate: %d Hz\n", sample_rate);
    } else {
        printf("Failed to get stream info. Defaulting to 16000 Hz\n");
    }

    // Open output WAV file
    FILE *wav_file = fopen(wav_filename, "wb");
    if (!wav_file) {
        printf("Failed to open output WAV file: %s\n", wav_filename);
        IAMF_decoder_close(handle);
        free(buffer);
        return 1;
    }

    struct wav_header header;
    init_wav_header(&header, num_channels, sample_rate);
    fwrite(&header, 1, sizeof(header), wav_file);

    // Allocate PCM buffer (large enough for one frame)
    // Up to 32 channels, 16-bit depth, max samples per channel
    int pcm_capacity = num_channels * 2 * 4096;
    uint8_t *pcm = (uint8_t *)malloc(pcm_capacity);
    if (!pcm) {
        printf("Failed to allocate PCM buffer\n");
        fclose(wav_file);
        IAMF_decoder_close(handle);
        free(buffer);
        return 1;
    }

    // Decode loop
    int decoded_frames = 0;
    int32_t total_data_bytes = 0;
    int non_zero_samples_count = 0;

    printf("Decoding start...\n");
    while (offset < size) {
        uint32_t rsize = 0;
        ret = IAMF_decoder_decode(handle, buffer + offset, size - offset, &rsize, pcm);
        if (rsize == 0 && ret <= 0) {
            break;
        }
        
        if (ret > 0) {
            decoded_frames++;
            // ret is the number of samples per channel
            int frame_bytes = ret * num_channels * sizeof(int16_t);
            fwrite(pcm, 1, frame_bytes, wav_file);
            total_data_bytes += frame_bytes;

            int16_t *pcm16 = (int16_t *)pcm;
            int total_samples = ret * num_channels;
            for (int i = 0; i < total_samples; i++) {
                if (pcm16[i] != 0) {
                    non_zero_samples_count++;
                }
            }

            if (decoded_frames % 10 == 0 || offset + rsize >= size) {
                printf("Decoded %d frames (offset: %u / %ld bytes)\n", decoded_frames, offset, size);
            }
        }
        offset += rsize;
    }

    // Finalize WAV header
    header.dlength = total_data_bytes;
    header.flength = total_data_bytes + 36;
    fseek(wav_file, 0, SEEK_SET);
    fwrite(&header, 1, sizeof(header), wav_file);
    fclose(wav_file);

    printf("Decoding complete.\n");
    printf("  Total decoded frames: %d\n", decoded_frames);
    printf("  Total decoded bytes: %d\n", total_data_bytes);
    printf("  Total non-zero PCM samples: %d\n", non_zero_samples_count);
    printf("  WAV file saved to: %s\n", wav_filename);

    free(pcm);
    IAMF_decoder_close(handle);
    free(buffer);

    if (decoded_frames == 0) {
        printf("FAIL: no frames were decoded at all.\n");
        return 2;
    }
    if (non_zero_samples_count == 0) {
        printf("FAIL: decode completed but every PCM sample was zero (silent audio regression).\n");
        return 2;
    }
    return 0;
}
