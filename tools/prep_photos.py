#!/usr/bin/env python3
"""Prepare photos for Keyframe (macOS only; uses the built-in `sips` tool).

Copies every photo under SOURCE into DEST as a TV-sized JPG, keeping the same
folder layout so folders still work as albums. It also turns sideways photos
upright: phones often store a photo rotated plus a "turn me" tag, and Roku
ignores that tag.

    python3 tools/prep_photos.py SOURCE DEST [--size 1920]

Originals are never modified. Use --size 3840 for a 4K TV.
"""
import argparse
import os
import struct
import subprocess
import sys

PHOTO_TYPES = {".jpg", ".jpeg", ".png", ".gif", ".heic", ".heif", ".tif", ".tiff", ".bmp"}

# EXIF orientation value -> clockwise degrees needed to turn the pixels upright
ROTATION = {3: 180, 6: 90, 8: 270}


def find_orientation(data):
    """Returns (offset of the orientation value, byte order, value) or None."""
    start = data.find(b"Exif\x00\x00")
    if start < 0:
        return None
    tiff = start + 6
    order = "<" if data[tiff:tiff + 2] == b"II" else ">"
    try:
        ifd = tiff + struct.unpack(order + "I", data[tiff + 4:tiff + 8])[0]
        count = struct.unpack(order + "H", data[ifd:ifd + 2])[0]
        for n in range(count):
            entry = ifd + 2 + 12 * n
            if struct.unpack(order + "H", data[entry:entry + 2])[0] == 0x0112:
                value = struct.unpack(order + "H", data[entry + 8:entry + 10])[0]
                return entry + 8, order, value
    except struct.error:
        pass
    return None


def longest_side(path):
    """Longest side in pixels, or 0 if it cannot be read."""
    result = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", path],
                            capture_output=True, text=True)
    sides = [int(line.split()[-1]) for line in result.stdout.splitlines()
             if "pixel" in line and line.split()[-1].isdigit()]
    return max(sides) if sides else 0


def make_upright(path):
    """Rotates the pixels of a JPG to match its orientation tag, then clears the tag."""
    with open(path, "rb") as f:
        found = find_orientation(f.read(256 * 1024))
    if not found or found[2] not in ROTATION:
        return False
    subprocess.run(["sips", "-r", str(ROTATION[found[2]]), path],
                   check=True, capture_output=True)
    with open(path, "rb") as f:
        data = bytearray(f.read())
    found = find_orientation(data)
    if found and found[2] != 1:
        offset, order, _ = found
        data[offset:offset + 2] = struct.pack(order + "H", 1)
        with open(path, "wb") as f:
            f.write(data)
    return True


def main():
    parser = argparse.ArgumentParser(description="Prepare photos for Keyframe.")
    parser.add_argument("source", help="folder of original photos")
    parser.add_argument("dest", help="folder to write TV-ready JPGs into")
    parser.add_argument("--size", type=int, default=1920,
                        help="longest side in pixels (default 1920; use 3840 for 4K)")
    args = parser.parse_args()

    source = os.path.abspath(args.source)
    dest = os.path.abspath(args.dest)
    if not os.path.isdir(source):
        sys.exit(f"Not a folder: {source}")
    if dest == source or dest.startswith(source + os.sep):
        sys.exit("DEST must be outside SOURCE, so originals and copies stay separate.")

    done = rotated = failed = 0
    small = []
    for folder, subfolders, files in os.walk(source):
        subfolders[:] = sorted(d for d in subfolders if not d.startswith("."))
        out_folder = os.path.join(dest, os.path.relpath(folder, source))
        used = set()
        for name in sorted(files):
            base, ext = os.path.splitext(name)
            if name.startswith(".") or ext.lower() not in PHOTO_TYPES:
                continue
            os.makedirs(out_folder, exist_ok=True)

            # Avoid clashes such as IMG_1.heic and IMG_1.jpg in one folder
            out_name, n = base, 2
            while out_name.lower() in used:
                out_name, n = f"{base}-{n}", n + 1
            used.add(out_name.lower())
            out_path = os.path.join(out_folder, out_name + ".jpg")

            in_path = os.path.join(folder, name)
            longest = longest_side(in_path)
            command = ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "90"]
            if longest > args.size:
                # Only ever shrink; enlarging a small photo adds size, not detail
                command += ["-Z", str(args.size)]
            elif 0 < longest < 1000:
                small.append(os.path.relpath(in_path, source))
            result = subprocess.run(command + [in_path, "--out", out_path],
                                    capture_output=True)
            if result.returncode != 0 or not os.path.exists(out_path):
                failed += 1
                print(f"  could not convert: {in_path}")
                continue
            done += 1
            if make_upright(out_path):
                rotated += 1

    print(f"Prepared {done} photos in {dest}")
    print(f"Turned upright: {rotated}")
    if failed:
        print(f"Could not convert: {failed}")
    if small:
        print(f"Too small to look sharp on a TV (under 1000 pixels): {len(small)}")
        for path in small:
            print(f"  {path}")


if __name__ == "__main__":
    main()
