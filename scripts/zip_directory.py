"""Portable replacement for zip -r when using Git Bash on Windows."""
import sys
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
archive = Path(sys.argv[1]).resolve()
folder = Path(sys.argv[2]).resolve()
with ZipFile(archive, 'w', ZIP_DEFLATED) as package:
    for file in folder.rglob('*'):
        if file.is_file() and file.absolute() != archive:
            package.write(file, file.relative_to(folder).as_posix())
