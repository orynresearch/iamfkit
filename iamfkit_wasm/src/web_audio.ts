import { IamfDecoder } from './IamfDecoder';
import { WebDecodeOptions } from './types';

/**
 * Decode an IAMF ArrayBuffer directly into a Web Audio API AudioBuffer.
 *
 * @param arrayBuffer IAMF file bitstream bytes.
 * @param audioContext Web Audio API AudioContext instance.
 * @param options Decoding options (layout, loudness).
 * @returns Promise<AudioBuffer> ready for Web Audio API playback.
 */
export async function decodeToAudioBuffer(
  arrayBuffer: ArrayBuffer,
  audioContext: AudioContext,
  options: WebDecodeOptions = {}
): Promise<AudioBuffer> {
  const result = await IamfDecoder.decodeBuffer(arrayBuffer, options);

  const audioBuffer = audioContext.createBuffer(
    result.numChannels,
    result.samplesPerChannel,
    result.sampleRate
  );

  for (let c = 0; c < result.numChannels; c++) {
    audioBuffer.copyToChannel(result.channelData[c], c);
  }

  return audioBuffer;
}
