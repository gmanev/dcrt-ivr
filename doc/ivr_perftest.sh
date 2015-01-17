#!/bin/sh

sipp -i 127.0.0.1 -mi 127.0.0.1 -p 5080 -sf ivr_perftest.xml -l 96 -m 10000 -r 10 -s 1000 127.0.0.1

