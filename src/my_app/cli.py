"""Command-line entry point: an argparse parser with one subcommand per verb."""

import argparse
import sys
from collections.abc import Sequence
from importlib.metadata import version


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="my-app", description="Add your description here.")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("version", help="print the installed version")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    match args.command:
        case "version":
            sys.stdout.write(f"{version('my-app')}\n")
            return 0
        case _:
            # argparse rejects unknown subcommands, so this only fires when a
            # subcommand is registered without a branch here.
            raise AssertionError(f"unhandled command: {args.command}")
