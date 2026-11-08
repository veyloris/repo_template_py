from importlib.metadata import version

import pytest

from my_app.cli import main


def test_version_prints_installed_version(capsys: pytest.CaptureFixture[str]) -> None:
    assert main(["version"]) == 0
    assert capsys.readouterr().out == f"{version('my-app')}\n"


def test_missing_command_exits_with_usage_error(capsys: pytest.CaptureFixture[str]) -> None:
    with pytest.raises(SystemExit) as exit_info:
        main([])
    assert exit_info.value.code == 2
    assert "usage: my-app" in capsys.readouterr().err
