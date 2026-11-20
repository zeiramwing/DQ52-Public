#!/usr/bin/env python3
"""Put together the web builder's site (for GitHub Pages) in OUTDIR: the
page and its worker, the overlay's picture, and engine.zip, which holds
what the build needs, the engine's sources (native/*.asm) and the tools
(tools/*.py, tools/native/*.py), with the Ophis assembler's Python (its
wheel, given or downloaded from PyPI: MIT licensed). No game data: the
visitor's own ROM is the only source of it, in their browser.

Usage: make_site.py OUTDIR [OPHIS_WHEEL]
"""
import glob
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPHIS = "ophis-asm==2.3.0"


def ophis_wheel(given):
    if given:
        return given
    where = tempfile.mkdtemp()
    subprocess.run([sys.executable, "-m", "pip", "download", OPHIS, "--no-deps", "-q", "-d", where], check=True)
    return glob.glob(os.path.join(where, "*.whl"))[0]


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in ("index.html", "worker.js"):
        shutil.copy(os.path.join(ROOT, "web", name), out)
    shutil.copy(os.path.join(ROOT, "extras", "overlay", "art.png"), out)
    open(os.path.join(out, ".nojekyll"), "w").close()
    wheel = ophis_wheel(sys.argv[2] if len(sys.argv) == 3 else None)
    with zipfile.ZipFile(os.path.join(out, "engine.zip"), "w", zipfile.ZIP_DEFLATED) as z:
        for pattern in ("native/*.asm", "tools/*.py", "tools/native/*.py"):
            for path in sorted(glob.glob(os.path.join(ROOT, pattern))):
                z.write(path, os.path.relpath(path, ROOT))
        with zipfile.ZipFile(wheel) as w:
            for name in w.namelist():
                if name.startswith("Ophis/") or name.endswith("dist-info/LICENSE") or "licenses/" in name:
                    z.writestr(name, w.read(name))
    print(f"make_site: {out} ({os.path.getsize(os.path.join(out, 'engine.zip')) // 1024} KB engine.zip)")


if __name__ == "__main__":
    main()
