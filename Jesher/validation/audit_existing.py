"""Independent Python audit of tracked reference and AA-02 sampling controls.

This does not execute MATLAB/Simulink, invent combined cases, or certify listening.
Run from any directory: python Jesher/validation/audit_existing.py [--output DIR]
The CSV metrics describe the existing double arrays, before WAV conversion.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import platform
import subprocess
import sys
import unittest
import wave
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import scipy
from scipy.io import loadmat, wavfile
from scipy.signal import resample_poly, upfirdn

SOURCE = "Audios/SpeechMusic.wav"
HANDOFF = "Results/Abdulrahman/AA02/sampling_22050.mat"
PROVENANCE = "Python numerical cross-check; MATLAB/Simulink not executed"


def positive_rate(value):
    """Validate a real numeric scalar before any integer conversion."""
    raw = np.asarray(value)
    if raw.ndim != 0 or raw.dtype.kind not in "iuf" or not np.isfinite(raw) or raw <= 0:
        raise ValueError("sampling rate must be a finite positive real scalar")
    return float(raw)


def mono_vector(samples, name="samples"):
    """Require a nonempty finite real mono vector; never flatten stereo."""
    raw = np.asarray(samples)
    if np.iscomplexobj(raw) or raw.size == 0:
        raise ValueError(f"{name} must be nonempty and real")
    if raw.ndim == 2 and raw.shape[1] == 1:
        raw = raw[:, 0]
    if raw.ndim != 1:
        raise ValueError(f"{name} must be a mono vector")
    result = raw.astype(np.float64)
    if not np.all(np.isfinite(result)):
        raise ValueError(f"{name} contains NaN or infinity")
    return result


def quality_metrics(reference, processed, *, reference_fs, processed_fs):
    """Compute metrics only after rates and lengths match on a known grid.

    Callers are responsible for equal physical start time and delay policy.
    Zero-reference results are explicit, with no epsilon substituted for energy.
    """
    reference_fs, processed_fs = positive_rate(reference_fs), positive_rate(processed_fs)
    if reference_fs != processed_fs:
        raise ValueError("comparison rates must match and be positive")
    x, y = mono_vector(reference, "reference"), mono_vector(processed, "processed")
    if x.shape != y.shape:
        raise ValueError("comparison lengths must match; align physical times first")
    # Scale both arrays by the same value only for arithmetic stability. This
    # leaves their ratio unchanged and is not independent signal normalization.
    scale = max(float(np.max(np.abs(x))), float(np.max(np.abs(y))))
    if scale == 0:
        return {"nmse": math.nan, "snr_db": math.nan,
                "metric_status": "undefined_zero_reference_and_error"}
    xs, ys = x / scale, y / scale
    energy = float(np.dot(xs, xs))
    error = xs - ys
    error_energy = float(np.dot(error, error))
    if energy == 0:
        return {"nmse": math.inf, "snr_db": -math.inf,
                "metric_status": "zero_reference_nonzero_error"}
    if error_energy == 0:
        return {"nmse": 0.0, "snr_db": math.inf, "metric_status": "zero_error"}
    ratio = error_energy / energy
    return {"nmse": ratio, "snr_db": -10 * math.log10(ratio), "metric_status": "finite"}


def expected_case_ids():
    result = []
    for software in ("matlab", "simulink"):
        for rate in (44100, 22050, 11025, 8000, 4000):
            for mode in (("native",) if rate == 44100 else ("lpf", "none")):
                for bits in (16, 8, 4, 2):
                    result.append(f"speechmusic_fs{rate}_b{bits:02d}_{mode}_{software}")
    return result


def coverage_rows(available_ids):
    counts = Counter(available_ids)
    expected = expected_case_ids()
    unexpected = sorted(set(counts) - set(expected))
    if unexpected:
        raise ValueError(f"unexpected case IDs: {unexpected}")
    return [{"case_id": case, "available_artifact_count": counts[case],
             "status": "missing" if counts[case] == 0 else
             "duplicate" if counts[case] > 1 else "control_artifact_available",
             "final_evaluation_verified": False,
             "execution_evidence": PROVENANCE if counts[case] else "not supplied"}
            for case in expected]


def reconstruct_22050(samples, coefficients):
    """Use saved symmetric 41-tap downsampling FIR as reconstruction prototype.

    MATLAB's 2/1 interpolation uses effective FIR 2*h, where the tracked 1/2
    h has sum 1, n=10, beta=5. SciPy multiplies array windows by up internally,
    so window=h supplies effective FIR 2*h, not 4*h. Also verify against raw
    upfirdn(2*h, y, up=2) with the known 20-source-sample group delay removed.
    This explicit mapping is independently checked, not a MATLAB execution.
    """
    y, h = mono_vector(samples), mono_vector(coefficients, "FIR")
    if len(h) != 41 or not np.allclose(h, h[::-1], rtol=0, atol=1e-15):
        raise ValueError("AA-03 reconstruction requires saved symmetric 41-tap FIR")
    if not math.isclose(float(np.sum(h)), 1, rel_tol=0, abs_tol=1e-12):
        raise ValueError("saved downsampling FIR must have unity DC gain")
    result = resample_poly(y, 2, 1, window=h, padtype="constant")
    raw = upfirdn(2 * h, y, up=2)
    delay = (len(h) - 1) // 2
    explicit = raw[delay:delay + 2 * len(y)]
    if not np.allclose(result, explicit, rtol=0, atol=1e-14):
        raise ValueError("polyphase reconstruction disagrees with explicit FIR delay mapping")
    return result


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_pcm16(path):
    with wave.open(str(path), "rb") as stream:
        info = {"sampling_rate_hz": stream.getframerate(),
                "sample_count": stream.getnframes(),
                "channels": stream.getnchannels(),
                "wav_container_bits": stream.getsampwidth() * 8,
                "compression": stream.getcomptype()}
    rate, data = wavfile.read(path)
    positive_rate(rate)
    if (info["channels"] != 1 or data.dtype != np.int16 or info["compression"] != "NONE"
            or rate != info["sampling_rate_hz"] or len(data) != info["sample_count"]):
        raise ValueError(f"expected mono PCM16: {path}")
    samples = mono_vector(data.astype(np.float64) / 32768)
    info.update(duration_seconds=len(samples) / rate,
                last_sample_time_seconds=(len(samples) - 1) / rate,
                file_bytes=path.stat().st_size, sha256=sha256(path))
    return samples, info


def write_csv(path, rows):
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def write_json(path, value):
    """Strict JSON; any nonfinite number is an error rather than invalid JSON."""
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n", encoding="utf-8")


def run_tests(output):
    loader = unittest.TestLoader()
    suite = loader.discover(str(Path(__file__).parent), pattern="test_audit_existing.py")
    with (output / "test_evidence.txt").open("w", encoding="utf-8") as stream:
        outcome = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
    return {"tests_run": outcome.testsRun, "failures": len(outcome.failures),
            "errors": len(outcome.errors), "successful": outcome.wasSuccessful()}


def audit(root, output):
    output.mkdir(parents=True, exist_ok=True)
    # Invalidate older CSV evidence before reading new inputs. CSVs are usable
    # only alongside this run's succeeded audit.json, even after interruption.
    write_json(output / "audit.json", {
        "schema_version": 1, "status": "running", "all_checks_passed": False,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "execution_evidence": PROVENANCE,
        "csv_evidence_valid": False,
    })
    checks = []

    def check(name, condition, detail=""):
        checks.append({"name": name, "passed": bool(condition), "detail": detail})
        if not condition:
            write_json(output / "audit.json", {
                "schema_version": 1, "status": "failed", "all_checks_passed": False,
                "generated_utc": datetime.now(timezone.utc).isoformat(),
                "execution_evidence": PROVENANCE, "csv_evidence_valid": False,
                "checks": checks, "error": f"Required artifact check failed: {name}",
            })
            raise ValueError(f"Required artifact check failed: {name}")

    reference, original_info = read_pcm16(root / SOURCE)
    p = loadmat(root / HANDOFF, simplify_cells=True)["prototype"]
    source_fs = int(positive_rate(original_info["sampling_rate_hz"]))
    check("source_header", source_fs == 44100 and len(reference) == 882005
          and original_info["wav_container_bits"] == 16)
    check("MAT_reference_matches_original", np.array_equal(reference, p["original"]["samples"]))
    check("source_identity", p["sourceFile"] == SOURCE
          and p["sourceBitsPerSample"] == 16 and p["platform"] == "MATLAB"
          and positive_rate(p["original"]["Fs"]) == source_fs
          and p["original"]["sampleCount"] == len(reference)
          and math.isclose(p["original"]["durationSeconds"], len(reference)/source_fs,
                           rel_tol=0, abs_tol=1e-12))
    check("no_independent_normalization", not p["normalizationApplied"])
    check("sampling_control_not_requantized", not p["quantizationApplied"]
          and p["processingStage"] == "sampling_only")
    h = mono_vector(p["filter"]["coefficients"], "FIR")
    check("filter_settings", p["filter"]["p"] == 1 and p["filter"]["q"] == 2
          and p["filter"]["designN"] == 10 and p["filter"]["kaiserBeta"] == 5
          and p["filter"]["delayCompensatedByResample"])
    replicated = resample_poly(reference, 1, 2, window=h, padtype="constant")
    replication_error = float(np.max(np.abs(replicated - p["filtered"]["samples"])))
    check("saved_FIR_replicates_MAT_sampling", replication_error <= 1e-14,
          f"maximum absolute difference {replication_error:.17g}")

    native_id = "speechmusic_fs44100_b16_native_matlab"
    metrics = []
    manifest = []

    def metric_row(case, samples, fs, bits, mode, metric_values, representation):
        return {"case_id": case, "platform": "matlab", "source": SOURCE,
                "sampling_rate_hz": fs, "effective_bits": bits, "filter_mode": mode,
                "sample_count": len(samples), "duration_seconds": len(samples) / fs,
                "comparison_rate_hz": source_fs, "comparison_start_seconds": 0,
                "comparison_end_seconds": (len(reference) - 1) / source_fs,
                "comparison_sample_count": len(reference), **metric_values,
                "representation": representation, "metric_engine": PROVENANCE,
                "final_evaluation_verified": False}

    metrics.append(metric_row(native_id, reference, source_fs, 16, "native",
                             quality_metrics(reference, reference, reference_fs=source_fs,
                                             processed_fs=source_fs), "original PCM16 baseline control"))
    manifest.append({"case_id": native_id, "wav_filename": SOURCE,
                     "effective_bits": 16, **original_info,
                     "max_abs_roundtrip_error": 0.0,
                     "playback_status": "not listened; device playback pending"})
    for key, mode in (("unfiltered", "none"), ("filtered", "lpf")):
        branch = p[key]
        y = mono_vector(branch["samples"])
        # Do not silently accept a fractional/incorrect rate by truncating it.
        raw_rate = positive_rate(branch["Fs"])
        expected_id = f"speechmusic_fs22050_b16_{mode}_matlab"
        check(f"{key}_metadata", branch["caseId"] == expected_id and raw_rate == 22050
              and branch["sampleCount"] == len(y) == 441003
              and branch["filterMode"] == mode
              and branch["firstSampleTimeSeconds"] == 0
              and math.isclose(branch["lastSampleTimeSeconds"], (len(y)-1)/raw_rate,
                               rel_tol=0, abs_tol=1e-12)
              and math.isclose(branch["durationSeconds"], len(y)/raw_rate,
                               rel_tol=0, abs_tol=1e-12))
        fs = int(raw_rate)
        if key == "unfiltered":
            check("unfiltered_exact_sample_selection", np.array_equal(y, reference[::2]))
        reconstructed = reconstruct_22050(y, h)
        # Only the final unmatched endpoint is omitted for the odd-length source.
        check(f"{key}_reconstruction_length", len(reconstructed) == len(reference) + 1)
        values = quality_metrics(reference, reconstructed[:len(reference)],
                                 reference_fs=source_fs, processed_fs=source_fs)
        metrics.append(metric_row(expected_id, y, fs, 16, mode, values,
                                  "MAT double sampling-only control; source bits=16"))
        wav_path = (root / HANDOFF).parent / branch["wav"]["fileName"]
        exported, info = read_pcm16(wav_path)
        check(f"{key}_wav_rate_length_width", info["sampling_rate_hz"] == fs
              and info["sample_count"] == len(y) and info["wav_container_bits"] == 16)
        if exported.shape != y.shape:
            raise ValueError(f"{key} WAV shape differs from MAT samples")
        error = float(np.max(np.abs(exported - y)))
        metadata = branch["wav"]
        check(f"{key}_wav_metadata", info["file_bytes"] == metadata["fileBytes"]
              and info["wav_container_bits"] == metadata["bitsPerSample"]
              and math.isclose(error, metadata["maxAbsRoundTripError"], abs_tol=1e-14))
        # A 1-LSB bound accommodates MATLAB's signed PCM conversion convention.
        # This audit does not infer a round-to-nearest, half-LSB guarantee.
        check(f"{key}_wav_conversion_bound", error <= 1/32768 + 1e-14
              and np.min(y) >= -1 and np.max(y) <= 1 - 1/32768,
              f"max error {error:.17g}; bound 1/32768; no clipping expected")
        manifest.append({"case_id": expected_id,
                         "wav_filename": wav_path.relative_to(root).as_posix(),
                         "effective_bits": "16 source/control; no explicit quantizer",
                         **info, "max_abs_roundtrip_error": error,
                         "playback_status": "not listened; device playback pending"})

    coverage = coverage_rows([row["case_id"] for row in metrics])
    check("expected_case_matrix", len(coverage) == 72
          and sum(row["status"] == "control_artifact_available" for row in coverage) == 3
          and sum(row["status"] == "missing" for row in coverage) == 69)
    tests = run_tests(output)
    check("metric_and_validation_tests", tests["successful"])
    try:
        revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root,
                                           text=True).strip()
    except (OSError, subprocess.SubprocessError):
        revision = "unknown"
    summary = {
        "schema_version": 1, "status": "succeeded", "csv_evidence_valid": True,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "execution_evidence": PROVENANCE, "source_commit": revision,
        "python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__,
        "input_files": {SOURCE: sha256(root / SOURCE), HANDOFF: sha256(root / HANDOFF)},
        "checks": checks, "all_checks_passed": all(c["passed"] for c in checks),
        "tests": tests, "case_coverage": {"expected": 72, "available_controls": 3,
                                         "missing": 69, "final_verified_rows": 0},
        "alignment": {
            "scope": "Only the documented 44100->22050 AA-03 route is evaluated",
            "reconstruction": "resample_poly(y,2,1,window=saved_h,padtype='constant')",
            "effective_interpolation_FIR": "2*saved_h; SciPy applies the up=2 scaling internally",
            "independent_check": "upfirdn(2*saved_h,y,up=2), remove 20 original-rate samples",
            "interval": "all original sample times; discard only one unmatched final reconstruction sample",
            "extra_lag_search": False, "edge_trimming": False,
            "independent_signal_normalization": False,
            "MATLAB_default_reconstruction_parity": "inferred from shared n=10,beta=5,FIR; awaiting MATLAB execution",
            "sources": ["https://www.mathworks.com/help/signal/ref/resample.html",
                        "https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.resample_poly.html"]},
        "limitations": ["No MATLAB or Simulink execution in this local audit",
                        "No combined quantized outputs or persisted Simulink case arrays supplied",
                        "No listening observations or actual speaker playback performed",
                        "Recording microphone provenance still belongs to Yazan",
                        "Baseline has a MATLAB matrix control ID only for coverage; this is not evidence of MATLAB execution"],
    }
    write_csv(output / "available_controls_metrics.csv", metrics)
    write_csv(output / "case_coverage.csv", coverage)
    write_csv(output / "wav_manifest.csv", manifest)
    # JSON contains no nonstandard NaN/Infinity tokens; special metrics are in CSV.
    write_json(output / "audit.json", summary)
    print(f"Checks: {sum(c['passed'] for c in checks)}/{len(checks)} passed; "
          f"tests: {tests['tests_run']}; available controls: 3/72; final verified: 0/72")
    print(f"Evidence: {output}")
    return 0 if summary["all_checks_passed"] else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    root = Path(__file__).resolve().parents[2]
    parser.add_argument("--output", type=Path, default=root / "Jesher/results/local_audit")
    args = parser.parse_args()
    output = args.output.resolve()
    try:
        return audit(root, output)
    except (ValueError, OSError, KeyError, TypeError) as error:
        # Preserve detailed check failures; all other failures invalidate older
        # CSV evidence too. No partial metrics/manifest CSVs are published.
        output.mkdir(parents=True, exist_ok=True)
        status_file = output / "audit.json"
        current = json.loads(status_file.read_text(encoding="utf-8")) if status_file.exists() else {}
        current.update(status="failed", all_checks_passed=False,
                       csv_evidence_valid=False, error=str(error))
        write_json(status_file, current)
        print(f"Audit failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
