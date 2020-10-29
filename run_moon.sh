#!/bin/bash

cd E:/a327ex/Anchor # change to the directory of the current project
engine/love/moonc.exe main.moon # add more moonscript files to be compiled if necessary
engine/love/love.exe --console .
