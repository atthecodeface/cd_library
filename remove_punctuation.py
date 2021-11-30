#!/usr/bin/env python3
import sys
from pathlib import Path
args = sys.argv[1:]
for a in args:
    b = a + ""
    b = b.replace(":", "")
    b = b.replace(";", "")
    b = b.replace(",", "")
    b = b.replace("(", "[")
    b = b.replace(")", "]")
    b = b.replace("?", ".")
    b = b.replace("\"", "'")
    if a!=b:
        pa = Path(a)
        pb = Path(b)
        if pa.exists():
            pa.rename(pb)
            pass
        pass
    pass


