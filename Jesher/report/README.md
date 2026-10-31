# Current measured MATLAB report section

Prepared 31 October 2026 from the completed run
`Jesher/results/matlab_run_20261030_170138_859`.

Publication includes this report, figures and plain result/evidence tables.
The user chose to keep WAV/ZIP/MAT payloads local. Rebuilding this exact report
requires the owner's local `evaluation.mat`, producer snapshot and audio package;
these are not included on the publication branch. Other teammates can generate
their own fresh evaluation runs. See `../PUBLICATION.md`.

- `metrics_playback_draft.md`: updated editable report section with all current
  measurements, six captioned tables, three captioned figures and limitations.
- `current_matlab_results.html`: browser view of the same text and figures.
- `output/pdf/Jesher_Current_MATLAB_Results.pdf`: seven-page shareable report section.
- `figures/`: high-resolution MATLAB figures regenerated from the exact saved
  arrays, with a readable light theme and consistent panel labels. The original
  run images remain untouched.
- `report_verification.json`: hashes and artifact checks supporting this report.

The report presents three available MATLAB controls. It is not a complete
72-case project report. Listening statements are limited to the user's actual
audible/clear observation. No teammate observations or playback setup are invented.

## Reproduction

In MATLAB, from the repository root:

```matlab
addpath(fullfile(pwd,'Jesher','report'));
Prepare_Current_Report_Figures;
```

Then run `build_current_results.py` with Python, NumPy, SciPy, ReportLab and
Markdown available. The current computer supplies NumPy/SciPy/Markdown through
the normal Python environment and ReportLab through the bundled runtime. The
following PowerShell command uses those installed packages without installing
or changing them:

```powershell
python -X utf8 -c "import sys,runpy; sys.path.append(r'C:\Users\jeshe\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages'); runpy.run_path('Jesher/report/build_current_results.py',run_name='__main__')"
```

The builder recomputes processing and exported-audio metrics independently,
checks rates/counts/bytes/PCM errors, matches all 19 passing MATLAB tests,
verifies the exact ZIP member set and bytes, and writes the three report formats
from common content. It replaces the editable Markdown with generated content;
retain separate copies of later editorial changes before rebuilding.

Before publication, the MATLAB license number was redacted from the session
diary; all 19 passing test rows and run results were retained and rechecked.
The report verification input hash identifies that redacted diary. Its original
copy is kept in an ignored local-only backup directory.

The PDF was rendered into temporary page images for a visual review of every
page. Text, table numbers and figure captions were checked. Temporary renders
are excluded from Git.
