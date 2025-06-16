#!/bin/bash
sudo apt update
sudo apt install -y python3 python3-venv curl
python3 -m venv server
source venv/bin/activate
curl -sS https://bootstrap.pypa.io/get-pip.py | python3