from pathlib import Path
import base64, gzip, hashlib, re, sys

ROOT = Path(__file__).resolve().parents[1]

BASE_GZ_SHA = "e44a69d8848230144965f5a3cd71554ab2db844619c2267155da3a9cf4db3898"
BASE_SHA = "434d8e4c4f7143e71a4b4f32069c3452f4fa3c0e7ce18de1f6427d61cda010b2"
PATCH_GZ_SHA = "6e7e1431da21e38dc1904742e38d4ba6c7799283f013361e5dcdcba7ee35f01b"
PATCH_SHA = "ee4c329fbf978725209bd6fb18866da4bda2d8c11201970aa3dfaeb550c8390a"
FINAL_SHA = "c7b4ee5c6dd7118f6357b10767e2c812cff67053928c0992bffdb45ad63235e5"

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def join_text(paths):
    return "".join(Path(p).read_text(encoding="utf-8").strip() for p in paths)

def apply_unified(base: bytes, patch: bytes) -> bytes:
    src = base.decode("utf-8").splitlines(keepends=True)
    d = patch.decode("utf-8").splitlines(keepends=True)
    out = []
    si = 0
    i = 0
    while i < len(d) and not d[i].startswith("@@ "):
        i += 1
    hunk_re = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")
    while i < len(d):
        if not d[i].startswith("@@ "):
            i += 1
            continue
        m = hunk_re.match(d[i])
        if not m:
            raise RuntimeError("Encabezado de parche inválido: " + d[i].rstrip())
        old_start = int(m.group(1)) - 1
        if old_start < si:
            raise RuntimeError("Parche fuera de orden")
        out.extend(src[si:old_start])
        si = old_start
        i += 1
        while i < len(d) and not d[i].startswith("@@ "):
            line = d[i]
            if line.startswith("\\ No newline"):
                i += 1
                continue
            if not line:
                i += 1
                continue
            tag = line[0]
            body = line[1:]
            if tag == " ":
                if si >= len(src) or src[si] != body:
                    raise RuntimeError(f"Contexto no coincide en línea fuente {si+1}")
                out.append(src[si]); si += 1
            elif tag == "-":
                if si >= len(src) or src[si] != body:
                    raise RuntimeError(f"Eliminación no coincide en línea fuente {si+1}")
                si += 1
            elif tag == "+":
                out.append(body)
            else:
                raise RuntimeError("Línea de parche desconocida: " + line[:40])
            i += 1
    out.extend(src[si:])
    return "".join(out).encode("utf-8")

base_parts = [ROOT / "build52/html" / f"part_0{i}" for i in range(5)]
patch_parts = [ROOT / "build53/patch/part_00", ROOT / "build53/patch/part_01"]

base_gz = base64.b64decode(join_text(base_parts), validate=True)
if sha(base_gz) != BASE_GZ_SHA:
    raise SystemExit("SHA GZIP 5.2 incorrecto")
base = gzip.decompress(base_gz)
if sha(base) != BASE_SHA:
    raise SystemExit("SHA HTML 5.2 incorrecto")

patch_gz = base64.b64decode(join_text(patch_parts), validate=True)
if sha(patch_gz) != PATCH_GZ_SHA:
    raise SystemExit("SHA GZIP parche incorrecto")
patch = gzip.decompress(patch_gz)
if sha(patch) != PATCH_SHA:
    raise SystemExit("SHA parche incorrecto")

final = apply_unified(base, patch)
if sha(final) != FINAL_SHA:
    raise SystemExit("SHA HTML 5.3 incorrecto: " + sha(final))

out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build53/generated/MiAgenda_5.3.html"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(final)

text = final.decode("utf-8")
for marker in ('miagenda-version" content="5.3"', "miagenda-sync-v2-encrypted", "runSyncSelfTest"):
    if marker not in text:
        raise SystemExit("Falta marcador 5.3: " + marker)

print("MI AGENDA 5.3 EXACTA: OK")
print("SHA256=" + FINAL_SHA)
print("OUTPUT=" + str(out))
