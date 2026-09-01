import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'iamfkit-react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go (use Expo Prebuild / Development Builds)\n';

const NativeIamfKit = NativeModules.IamfKit
  ? NativeModules.IamfKit
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export default NativeIamfKit;
