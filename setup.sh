#!/bin/sh
set -x -e
python3 -m virtualenv -p python3 .venv
. .venv/bin/activate
pip install scapy