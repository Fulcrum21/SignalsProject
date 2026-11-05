"""Compatibility entry point for the concise sampling-section builder."""
from pathlib import Path
import runpy

if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).with_name("build_sampling_section.py")), run_name="__main__")
