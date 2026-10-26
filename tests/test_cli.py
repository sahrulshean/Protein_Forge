import json
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.mark.parametrize("command", [[sys.executable, "-m", "protein_forge"], [str(Path(sys.executable).with_name("protein-forge"))]])
def test_cli_normalizes_and_reports_length(command, tmp_path):
    result = subprocess.run(command + [" acd ef "], cwd=tmp_path, capture_output=True, text=True)

    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout) == {"sequence": "ACDEF", "length": 5}


@pytest.mark.parametrize("arguments", [["ACX"], [""] , []])
def test_cli_rejects_invalid_or_missing_input(arguments, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "protein_forge", *arguments],
        cwd=tmp_path,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert not result.stdout
    assert "error:" in result.stderr
    assert "Traceback" not in result.stderr
