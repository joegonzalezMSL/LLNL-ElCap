# LLNL-ElCap
Environment, build and affinity resources for El Capitan

## Grab this repo and compile the HIP device defragmentation code

```
git clone https://github.com/joegonzalezMSL/LLNL-ElCap.git
```

Navigate to the directory and compile the defrag code

```
cd LLNL-ElCap
module load rocm/6.2.1
hipcc --offload-arch=gfx942 HIP-device-defrag.cpp -lamdhip64 -o hip-dev-defrag.x
cd ../
```

Note here I am using ```--offload-arch=gfx942```, however if you have significant data movement between GPU and CPU, then you will want ```--offload-arch=gfx942apu``` instead. This should match what is defined in the Makefile under ```KOKKOS_ARCH```

## Get LAMMPS and build lammps
``` 
git clone https://github.com/lammps/lammps.git
cd lammps/src
cp ../../LLNL-ElCap/elcap_env.sh .
cp ../../LLNL-ElCap/Makefile.elcapitan_kokkos_noapu MAKE/MACHINES/
cp ../../LLNL-ElCap/build-lammps.sh
./build-lammps.sh
cd ..
```



