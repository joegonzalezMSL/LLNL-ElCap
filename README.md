# LLNL-ElCap
Environment, build and affinity resources for El Capitan

## Grab this repo and compile the HIP device defragmentation code

```
git clone

``` git clone https://github.com/lammps/lammps.git```
## 


## Compile HIP device defragmentation code

Note here I am using ```--offload-arch=gfx942```, however if you have significant data movement between GPU and CPU, then you will want ```--offload-arch=gfx942apu``` instead. This should match what is defined in the Makefile under ```KOKKOS_ARCH```

```
hipcc --offload-arch=gfx942 HIP-device-defrag.cpp -lamdhip64 -o hip-dev-defrag.x
```
