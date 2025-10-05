#!/bin/bash

## put this in your src/ directory. 
## put elcap_env.sh in your src/ directory
## Run ./build_lammps.sh after you have 

. elcap_env.sh

make clean-all

make yes-KOKKOS
make yes-ML-SNAP
make yes-SHOCK

make elcapitan_kokkos_noapu -j 16
#make elcapitan_kokkos -j 16
