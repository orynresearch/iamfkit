import os
import unittest
import numpy as np

import iamfkit
from iamfkit import IamfDecoder, SoundSystem, OutputFormat, decode_file, decode_to_wav


TEST_IAMF = "/Users/minodab492/libiamf-macos-test/tests/test_000002.iamf"


class TestIamfkit(unittest.TestCase):

    def test_package_exports(self):
        self.assertTrue(hasattr(iamfkit, "IamfDecoder"))
        self.assertTrue(hasattr(iamfkit, "decode_file"))
        self.assertTrue(hasattr(iamfkit, "decode_to_wav"))
        self.assertTrue(hasattr(iamfkit, "SoundSystem"))
        self.assertTrue(hasattr(iamfkit, "OutputFormat"))

    def test_decoder_instantiation(self):
        with IamfDecoder(output_format=OutputFormat.FLOAT32) as dec:
            self.assertEqual(dec.get_num_channels(), 2)

    def test_decoder_binaural_channels(self):
        with IamfDecoder(sound_system=SoundSystem.SOUND_SYSTEM_BINAURAL) as dec:
            self.assertEqual(dec.get_num_channels(), 2)

    def test_decoder_format_switching(self):
        with IamfDecoder(output_format=OutputFormat.INT16) as dec:
            self.assertEqual(dec.output_format, OutputFormat.INT16)
            dec.set_output_format(OutputFormat.FLOAT32)
            self.assertEqual(dec.output_format, OutputFormat.FLOAT32)
            dec.set_output_format(OutputFormat.INT32)
            self.assertEqual(dec.output_format, OutputFormat.INT32)

    @unittest.skipUnless(os.path.exists(TEST_IAMF), "Sample IAMF file not found")
    def test_decode_file_float32(self):
        pcm, sr, channels = decode_file(TEST_IAMF, output_format=OutputFormat.FLOAT32)
        self.assertGreater(pcm.shape[0], 0)
        self.assertEqual(channels, 2)
        self.assertEqual(pcm.dtype, np.float32)

    @unittest.skipUnless(os.path.exists(TEST_IAMF), "Sample IAMF file not found")
    def test_decode_file_int16(self):
        pcm, sr, channels = decode_file(TEST_IAMF, output_format=OutputFormat.INT16)
        self.assertGreater(pcm.shape[0], 0)
        self.assertEqual(channels, 2)
        self.assertEqual(pcm.dtype, np.int16)

    @unittest.skipUnless(os.path.exists(TEST_IAMF), "Sample IAMF file not found")
    def test_decode_to_wav(self):
        out_wav = "/tmp/iamfkit_unittest.wav"
        if os.path.exists(out_wav):
            os.remove(out_wav)
        result_path = decode_to_wav(TEST_IAMF, out_wav)
        self.assertTrue(os.path.exists(result_path))
        self.assertGreater(os.path.getsize(result_path), 1000)
        if os.path.exists(out_wav):
            os.remove(out_wav)


if __name__ == "__main__":
    unittest.main()
