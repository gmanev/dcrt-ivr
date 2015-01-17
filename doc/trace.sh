#!/bin/sh

tcpdump -i lo -s 3000 -G 900 -W 96 -w trace_%Y-%m-%d-%H:%M.pcap port 5060 or port 5080 or portrange 6000-20000

