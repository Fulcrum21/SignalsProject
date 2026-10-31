"""Meaningful independent checks of metric edge handling and input contracts."""
import math
import json
from pathlib import Path
import unittest
from unittest.mock import MagicMock, Mock, patch

import numpy as np

from scipy.signal import firwin

from audit_existing import (audit, coverage_rows, expected_case_ids, mono_vector,
                            positive_rate, quality_metrics, reconstruct_22050, write_json)


class MetricTests(unittest.TestCase):
    def metric(self, x, y, **kwargs):
        return quality_metrics(x, y, reference_fs=44100,
                               processed_fs=kwargs.pop("processed_fs", 44100), **kwargs)

    def test_unchanged(self):
        result = self.metric([0.2, -0.4, 0.1], [0.2, -0.4, 0.1])
        self.assertEqual(result["nmse"], 0)
        self.assertEqual(result["snr_db"], math.inf)

    def test_half_amplitude(self):
        result = self.metric([0.2, -0.4, 0.1], [0.1, -0.2, 0.05])
        self.assertEqual(result["nmse"], 0.25)
        self.assertAlmostEqual(result["snr_db"], 6.020599913279624)

    def test_zero_processed(self):
        result = self.metric([0.2, -0.4], [0, 0])
        self.assertEqual(result["nmse"], 1)
        self.assertEqual(result["snr_db"], 0)

    def test_both_zero(self):
        result = self.metric([0, 0], [0, 0])
        self.assertTrue(math.isnan(result["nmse"]))
        self.assertTrue(math.isnan(result["snr_db"]))

    def test_zero_reference_nonzero_error(self):
        result = self.metric([0, 0], [0.2, 0])
        self.assertEqual(result["nmse"], math.inf)
        self.assertEqual(result["snr_db"], -math.inf)

    def test_nmse_snr_relation(self):
        result = self.metric([0.8, -0.5, 0.25], [0.7, -0.6, 0.2])
        self.assertAlmostEqual(result["snr_db"], -10 * math.log10(result["nmse"]))

    def test_mismatched_length_rejected(self):
        with self.assertRaisesRegex(ValueError, "lengths"):
            self.metric([1, 2], [1])

    def test_mismatched_rate_rejected(self):
        with self.assertRaisesRegex(ValueError, "rates"):
            self.metric([1, 2], [1, 2], processed_fs=22050)

    def test_invalid_rate_metadata_rejected(self):
        for value in (0, -1, math.nan, math.inf, "44100", [44100], True):
            with self.subTest(value=value), self.assertRaises(ValueError):
                positive_rate(value)

    def test_stereo_rejected(self):
        with self.assertRaisesRegex(ValueError, "mono"):
            mono_vector([[1, 2], [3, 4]])

    def test_nonfinite_rejected(self):
        for bad in (math.nan, math.inf, -math.inf):
            with self.subTest(value=bad), self.assertRaises(ValueError):
                self.metric([0, 1], [0, bad])

    def test_empty_and_complex_rejected(self):
        for bad in ([], [1j, 0j]):
            with self.subTest(value=bad), self.assertRaises(ValueError):
                mono_vector(bad)

    def test_large_values_do_not_overflow(self):
        result = self.metric([1e200, -1e200], [0.5e200, -0.5e200])
        self.assertEqual(result["nmse"], 0.25)


class ReconstructionTests(unittest.TestCase):
    def test_interpolation_dc_gain_is_one_not_two(self):
        h = firwin(41, 0.5, window=("kaiser", 5))
        reconstructed = reconstruct_22050(np.ones(256), h)
        interior = reconstructed[40:-40]
        self.assertAlmostEqual(float(np.mean(interior)), 1, places=12)
        self.assertLess(float(np.max(np.abs(interior - 1))), 0.001)
        self.assertEqual(len(reconstructed), 512)

    def test_double_scaled_FIR_rejected(self):
        h = 2 * firwin(41, 0.5, window=("kaiser", 5))
        with self.assertRaisesRegex(ValueError, "unity"):
            reconstruct_22050(np.ones(256), h)


class JsonTests(unittest.TestCase):
    def test_json_never_emits_nonstandard_nan(self):
        path = Mock()
        with self.assertRaises(ValueError):
            write_json(path, {"bad": math.nan})
        path.write_text.assert_not_called()
        write_json(path, {"all_checks_passed": False, "status": "failed"})
        result = json.loads(path.write_text.call_args.args[0])
        self.assertFalse(result["all_checks_passed"])


class FailClosedTests(unittest.TestCase):
    def test_invalid_source_stops_before_metrics_or_csv(self):
        info = {"sampling_rate_hz": 48000, "wav_container_bits": 16}
        output = MagicMock()
        with patch("audit_existing.read_pcm16", return_value=(np.zeros(2), info)), \
                patch("audit_existing.loadmat", return_value={"prototype": {}}), \
                patch("audit_existing.write_json") as write_status, \
                patch("audit_existing.quality_metrics") as metrics, \
                patch("audit_existing.write_csv") as csv_output:
            with self.assertRaisesRegex(ValueError, "source_header"):
                audit(Path("."), output)
            metrics.assert_not_called()
            csv_output.assert_not_called()
            self.assertEqual(write_status.call_args.args[1]["status"], "failed")
            self.assertFalse(write_status.call_args.args[1]["csv_evidence_valid"])


class CoverageTests(unittest.TestCase):
    def test_matrix_unique(self):
        cases = expected_case_ids()
        self.assertEqual(len(cases), 72)
        self.assertEqual(len(set(cases)), 72)
        self.assertEqual(sum(case.endswith("_matlab") for case in cases), 36)

    def test_missing_and_duplicate_are_explicit(self):
        case = expected_case_ids()[0]
        rows = coverage_rows([case, case])
        self.assertEqual(next(row for row in rows if row["case_id"] == case)["status"], "duplicate")
        self.assertEqual(sum(row["status"] == "missing" for row in rows), 71)

    def test_unknown_id_rejected(self):
        with self.assertRaisesRegex(ValueError, "unexpected"):
            coverage_rows(["invented"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
