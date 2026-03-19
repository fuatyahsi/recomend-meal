from __future__ import annotations

import unittest

import extract_items


class _Payload:
    def __init__(self, txts=None, scores=None) -> None:
        self.txts = txts
        self.scores = scores


class ExtractItemsTest(unittest.TestCase):
    def test_run_reader_handles_none_payload_fields(self) -> None:
        def engine(_image):
            return (_Payload(txts=None, scores=None), None)

        text, confidence = extract_items.run_reader(engine, image=None)

        self.assertEqual("", text)
        self.assertEqual(0.0, confidence)

    def test_run_reader_merges_texts_and_scores(self) -> None:
        def engine(_image):
            return (_Payload(txts=["BİM", "Kaşar", None], scores=[0.9, 0.7, None]), None)

        text, confidence = extract_items.run_reader(engine, image=None)

        self.assertEqual("BİM Kaşar", text)
        self.assertAlmostEqual(0.8, confidence, places=2)


if __name__ == "__main__":
    unittest.main()
