#!/bin/sh
set -x -e
virtualenv -p python3 .venv
. .venv/bin/activate
pip install scapy