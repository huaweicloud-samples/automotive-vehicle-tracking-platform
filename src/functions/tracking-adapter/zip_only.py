import os
import zipfile

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, "dist", "_build")
os.makedirs(os.path.join(BASE, "dist"), exist_ok=True)

for name in ["gps-adapter", "sim-adapter", "ais140-adapter"]:
    out = os.path.join(BASE, "dist", f"{name}.zip")
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(SRC):
            for f in files:
                p = os.path.join(root, f)
                z.write(p, os.path.relpath(p, SRC))
    print(out, os.path.getsize(out), "bytes")
