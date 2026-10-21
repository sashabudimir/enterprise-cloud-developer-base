"""Build a portable Lambda ZIP without Jest or other development dependencies."""
import sys
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

name = sys.argv[1]
if name not in ("coupons_get_by_id", "coupons_update"):
    raise SystemExit("Unsupported Part 2 function")
root = Path(__file__).resolve().parent.parent
folder = root / "lambda" / name
with ZipFile(root / f"{name}.zip", "w", ZIP_DEFLATED) as package:
    for relative in ("index.js", "package.json"):
        package.write(folder / relative, relative)
    for file in (folder / "node_modules").rglob("*"):
        if file.is_file():
            package.write(file, file.relative_to(folder).as_posix())
