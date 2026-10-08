#!/usr/bin/env python3
"""Export the practice-data scripts from the app's Swift sources into scripts/python and scripts/r.

The app is the source of truth: the *Practice datasets* lesson shows these scripts, so this keeps the
downloadable copies identical. Run it after editing a generator, then regenerate the bundled data:

    python3 tools/export_scripts.py            # rewrite scripts/
    python3 tools/export_scripts.py --check    # exit 1 if scripts/ is out of date (used by CI)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = sorted((ROOT / "akstats").glob("Curriculum*.swift"))
SCRIPTS = ["generate_data", "generate_more_data", "generate_extra_data", "generate_simulations", "selfcheck"]


def raw_string_after(text: str, start: int, label: str) -> str:
    """The contents of the `label: #\"\"\" … \"\"\"#` Swift raw string after position `start`, dedented."""
    opening = re.compile(rf'{label}: #"""\n')
    match = opening.search(text, start)
    if not match:
        raise ValueError(f"no {label} string after position {start}")
    closing = re.compile(r'\n([ \t]*)"""#')
    end = closing.search(text, match.end())
    indent = end.group(1)
    body = text[match.end():end.start()]
    lines = [line[len(indent):] if line.startswith(indent) else line.lstrip(" ") for line in body.split("\n")]
    return "\n".join(lines).rstrip("\n") + "\n"


def extract() -> dict:
    files = {}
    for name in SCRIPTS:
        for source in SOURCES:
            text = source.read_text(encoding="utf-8")
            caption = re.search(rf'caption: "{name} —', text)
            if caption:
                files[f"python/{name}.py"] = raw_string_after(text, caption.end(), "python")
                files[f"r/{name}.R"] = raw_string_after(text, caption.end(), "r")
                break
        else:
            raise SystemExit(f"couldn't find the {name} script in the Swift sources")
    return files


def main() -> None:
    check = "--check" in sys.argv
    stale = []
    for relative, content in extract().items():
        path = ROOT / "scripts" / relative
        if path.exists() and path.read_text(encoding="utf-8") == content:
            continue
        stale.append(relative)
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
    if check and stale:
        sys.exit("scripts/ is out of date with the app (run python3 tools/export_scripts.py): " + ", ".join(stale))
    print("up to date" if not stale else "updated: " + ", ".join(stale))


if __name__ == "__main__":
    main()
