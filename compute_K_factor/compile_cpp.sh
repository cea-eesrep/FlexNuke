#!/bin/bash

if [ -f cpp_credit_K_interprocessing.so ];
then
    echo "Removing cpp_credit_K_interprocessing.so"
    rm cpp_credit_K_interprocessing.so
fi

g++ -shared -O3 -Wall -fPIC -std=c++11 $(python -m pybind11 --includes) cpp_source_K_interprocessing.cpp -o cpp_credit_K_interprocessing.so
