#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "iamfkit.h"

@interface IamfKit : NSObject <RCTBridgeModule>
@end

@implementation IamfKit

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

RCT_EXPORT_METHOD(decodeFile:(NSString *)fileUri
                  layout:(NSInteger)layout
                  format:(NSString *)format
                  lkfs:(double)lkfs
                  peakLimiter:(BOOL)peakLimiter
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = fileUri;
        if ([path hasPrefix:@"file://"]) {
            path = [path substringFromIndex:7];
        }

        NSData *fileData = [NSData dataWithContentsOfFile:path];
        if (!fileData) {
            reject(@"FILE_NOT_FOUND", [NSString stringWithFormat:@"Could not read IAMF file at %@", path], nil);
            return;
        }

        IamfKitDecoderHandle decoder = iamfkit_decoder_open();
        if (!decoder) {
            reject(@"DECODER_ERROR", @"Failed to allocate native IAMF decoder handle", nil);
            return;
        }

        iamfkit_decoder_set_sound_system(decoder, (IamfKitSoundSystem)layout);
        iamfkit_decoder_set_bit_depth(decoder, IAMFKIT_BIT_DEPTH_16);
        if (lkfs != 0.0) {
            iamfkit_decoder_set_normalization_loudness(decoder, (float)lkfs);
        }
        iamfkit_decoder_enable_peak_limiter(decoder, peakLimiter ? 1 : 0);

        const uint8_t *bytes = (const uint8_t *)[fileData bytes];
        uint32_t totalLen = (uint32_t)[fileData length];
        uint32_t offset = 0;
        int isConfigured = 0;

        // Configure loop
        while (offset < totalLen && !isConfigured) {
            uint32_t consumed = 0;
            int res = iamfkit_decoder_configure(decoder, bytes + offset, totalLen - offset, &consumed, &isConfigured);
            if (consumed == 0) break;
            offset += consumed;
            if (res == 0) break;
        }

        if (!isConfigured) {
            iamfkit_decoder_close(decoder);
            reject(@"CONFIG_FAILED", @"Failed to configure IAMF decoder with file header", nil);
            return;
        }

        IamfKitStreamInfo info;
        iamfkit_decoder_get_info(decoder, &info);

        NSMutableData *pcmData = [NSMutableData data];
        uint32_t pcmCap = 4096 * info.num_channels * sizeof(int16_t);
        uint8_t *pcmBuf = (uint8_t *)malloc(pcmCap);
        uint32_t totalFrames = 0;

        // Decode loop
        while (offset < totalLen) {
            uint32_t consumed = 0;
            int frames = iamfkit_decoder_decode(decoder, bytes + offset, totalLen - offset, &consumed, pcmBuf);
            if (consumed == 0 && frames <= 0) break;
            offset += consumed;

            if (frames > 0) {
                totalFrames += frames;
                uint32_t byteLen = frames * info.num_channels * sizeof(int16_t);
                [pcmData appendBytes:pcmBuf length:byteLen];
            }
        }

        free(pcmBuf);
        iamfkit_decoder_close(decoder);

        NSString *base64Str = [pcmData base64EncodedStringWithOptions:0];

        NSDictionary *result = @{
            @"pcmBase64": base64Str,
            @"sampleRate": @(info.sample_rate),
            @"channels": @(info.num_channels),
            @"samplesPerChannel": @(totalFrames)
        };

        resolve(result);
    });
}

@end
