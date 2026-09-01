export enum SoundSystem {
  STEREO = 0,
  SURROUND_5_0 = 1,
  SURROUND_7_0 = 2,
  SURROUND_5_1_2 = 3,
  SURROUND_5_1_4 = 4,
  SURROUND_7_1_4 = 5,
  SURROUND_3_1_2 = 6,
  SURROUND_7_1_2 = 7,
  SURROUND_3_1_0 = 8,
  MONO = 9,
  BINAURAL = 99,
}

export type LayoutAlias =
  | 'binaural'
  | 'stereo'
  | '3d'
  | 'headphones'
  | '5.1'
  | '5.0'
  | '7.1'
  | '7.0'
  | '5.1.2'
  | '5.1.4'
  | '7.1.4'
  | 'mono';

export interface WebDecodeOptions {
  layout?: LayoutAlias | SoundSystem;
  targetLoudnessLkfs?: number;
  enablePeakLimiter?: boolean;
}

export interface WebDecodeResult {
  channelData: Float32Array[]; // Float32Array per channel normalized [-1.0, 1.0]
  sampleRate: number;
  numChannels: number;
  samplesPerChannel: number;
}
