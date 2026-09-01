import NativeIamfKit from './NativeIamfKit';
import {
  DecodeOptions,
  DecodeResult,
  LayoutAlias,
  OutputFormat,
  SoundSystem,
} from './types';

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
  /**
   * Helper function to convert layout alias or enum to integer layout ID.
   */
  public static parseLayout(layout?: LayoutAlias | SoundSystem | number): number {
    if (layout === undefined) return 99; // Default binaural
    if (typeof layout === 'number') return layout;
    const key = layout.toLowerCase().trim();
    if (key in LAYOUT_MAP) return LAYOUT_MAP[key];
    return 99;
  }

  /**
   * High-level decode of an .iamf file directly into PCM audio data.
   *
   * @param fileUri Absolute path or file:// URI to .iamf file.
   * @param options Decoding options (layout, format, loudness).
   */
  public static async decodeFile(
    fileUri: str,
    options: DecodeOptions = {}
  ): Promise<DecodeResult> {
    const layoutId = IamfDecoder.parseLayout(options.layout);
    const format = options.outputFormat || 'float32';
    const lkfs = options.targetLoudnessLkfs ?? 0.0;
    const peakLimiter = options.enablePeakLimiter ?? true;

    const result = await NativeIamfKit.decodeFile(
      fileUri,
      layoutId,
      format,
      lkfs,
      peakLimiter
    );

    return result;
  }
}
