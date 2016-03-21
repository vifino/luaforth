#!/bin/sh

inotifywait --quiet --recursive --monitor --event modify --format "%w%f" . \
| while read change; do
  clear
  make test
done
