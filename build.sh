#!/bin/sh
# Packages the app as keyframe.zip, ready to upload to a Roku in Developer Mode.
set -e
cd "$(dirname "$0")"
rm -f keyframe.zip
zip -r -X -q keyframe.zip manifest source components images -x '*/.*'
echo "Built keyframe.zip"
