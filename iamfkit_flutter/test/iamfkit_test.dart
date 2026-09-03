import 'package:flutter_test/flutter_test.dart';
import 'package:iamfkit/eclipsa_iamf_decoder.dart';

void main() {
  test('IAMF sound system constants are defined', () {
    expect(IAMF_SoundSystem.SOUND_SYSTEM_A.value, equals(0));
    expect(IAMF_SoundSystem.SOUND_SYSTEM_B.value, equals(1));
  });
}
