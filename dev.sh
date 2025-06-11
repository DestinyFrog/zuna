#!/usr/bin/bash

while true;
do
    clear;
    lua Print.lua example.z1;
    # lua z1/Repl.lua standard example.z1 3d/public/out.svg;
    sleep 0.5;
done