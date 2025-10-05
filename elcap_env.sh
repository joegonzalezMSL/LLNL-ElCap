#!/bin/bash

## Written by Stan Moore from LAMMPS. Nothing should need to be adjusted unless you 
## want/require different behavior of the verbosity 

module load craype-accel-amd-gfx942
module load PrgEnv-cray
module load rocm/6.2.1
module list
export LD_LIBRARY_PATH=${CRAY_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}

export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU

### FIXME ### Need a system wide install of libfabric from SHS 11 (or newer)
export LD_LIBRARY_PATH=/usr/workspace/wsb/accept/packages-2024/SHS11_lib:${LD_LIBRARY_PATH}

USE_SPINDLE='-o userrc=/collab/usr/global/tools/spindle/toss_4_x86_64_ib_cray/etc/spindle/spindle.rc -o spindle'

export CRAYPE_MPICH_GTL_DIR=${CRAY_MPICH_ROOTDIR}/gtl/lib
export CRAYPE_MPICH_GTL_LIBS=-lmpi_gtl_hsa

export HIP_PATH=`hipconfig -p`
export LD_LIBRARY_PATH=${HIP_PATH}/lib:${LD_LIBRARY_PATH}

### Tell libfabric to only look for the ROCm runtime, not cuda, etc.
export FI_HMEM="rocr"

# Record/setup the compiler and FLAGS used to build LAMMPS and mpidevicemem
#export MPI_CXX_COMPILER=${HIP_PATH}/bin/hipcc
#export MY_MPI_CXX_FLAGS="-fdenormal-fp-math=ieee -fgpu-flush-denormals-to-zero -munsafe-fp-atomics -I${MPICH_DIR}/include"
#export MY_MPI_LINK_FLAGS="-L${MPICH_DIR}/lib -lmpi -L${CRAYPE_MPICH_GTL_DIR} ${CRAYPE_MPICH_GTL_LIBS} -lxpmem ${HUGEPAGES_LINK_FLAGS}"

############### start Huge Pages settings ###############

  # Share the read-only parts of executables built for libhugetlbfs
  # Don't do this because it creates persistent files in the hugetlbfs!
  # If the flux epilog properly cleans these up, then this would be safe to use
  #export HUGETLB_SHARE=1

  # Have shmget() calls use huge pages... does MPI do shmget()?
  # export HUGETLB_SHM=yes

  # Have malloc() calls use huge pages
  export HUGETLB_MORECORE=yes

  # Link flags to use libhugetlbfs, and align the exe segments to best do so
  export HUGEPAGES_LINK_FLAGS="-lhugetlbfs"
  # -Wl,--hugetlbfs-align isn't supported by the default linker
  # export HUGEPAGES_LINK_FLAGS="-lhugetlbfs -Wl,--hugetlbfs-align"

  # restrict libhugetlbfs to be enabled for these executables only:
  export HUGETLB_RESTRICT_EXE="defrag:lmp_elcap_kokkos_gpu"

  # Increase verbosity of libhugetlbfs
  #export HUGETLB_VERBOSE=3

  # Debug libhugetlbfs itself
  # export HUGETLB_DEBUG=1

  ############### end Huge Pages settings ###############

export HSA_XNACK=1



