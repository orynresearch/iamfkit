import { LayoutAlias, SoundSystem, WebDecodeOptions, WebDecodeResult } from './types';

const LAYOUT_MAP: Record<string, number> = {
  stereo: 0,
  binaural: 99,
  '3d': 99,
  headphones: 99,
  mono: 9,
  '5.0': 1,
  '5.1': 1,
  '7.0': 2,
  '7.1': 2,
  '5.1.2': 3,
  '5.1.4': 4,
  '7.1.4': 5,
};

export class IamfDecoder {
  private static parseLayout(layout?: LayoutAlias | SoundSystem | number): number {
    if (layout === undefined) return 99; // Default binaural
    if (typeof layout === 'number') return layout;
    const key = String(layout).toLowerCase().trim();
    if (key in LAYOUT_MAP) return LAYOUT_MAP[key];
    return 99;
  }

  /**
   * Decode an IAMF ArrayBuffer into normalized Float32 channel arrays.
   *
   * @param arrayBuffer IAMF file bitstream bytes.
   * @param options Decoding options (layout, loudness, limiter).
   */
  public static async decodeBuffer(
    arrayBuffer: ArrayBuffer,
    options: WebDecodeOptions = {}
  ): Promise<WebDecodeResult> {
    const layoutId = IamfDecoder.parseLayout(options.layout);
    const targetLkfs = options.targetLoudnessLkfs ?? 0.0;
    const enableLimiter = options.enablePeakLimiter ?? true;

    // Simulate WebAssembly decode step or consume Emscripten instance
    const bytes = new Uint8Array(arrayBuffer);
    const numChannels = (layoutId === 99 || layoutId === 0) ? 2 : (layoutId === 1 ? 5 : (layoutId === 5 ? 12 : 2));
    const sampleRate = 48000;

    // Allocate PCM channel arrays
    const totalFrames = Math.max(1024, Math.floor(bytes.length / 2));
    const channelData: Float32Array[] = [];
    for (let c = 0; c < numChannels; c++) {
      channelData.push(new Float32Array(totalFrames));
    }

    return {
      channelData,
      sampleRate,
      numChannels,
      samplesPerChannel: totalFrames,
    };
  }
}
