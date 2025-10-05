#!/bin/bash

#flux: --job-name=aC-decompress
#flux: --output='EXAMPLE.{{id}}.out'
#flux: --error='EXAMPLE.{{id}}.err'
#flux: -N 1
#flux: --setattr=thp=always
#flux: --setattr=bank=guests
#flux: --setattr=hugepages=512GB
#flux: -t 60
#flux: -q pdebug


## number of nodes
NN=1
## number of CPUS
NP=`echo "${NN}*4" | bc`
## number of GPUs
NG=`echo "${NN}*4" | bc`

## string variables for the name of your lammps input and logfile names
lmpIn=
lmpLog=

## c program to defrag and optimize memory prior to run
dexe="/g/g10/gonzalez133/bin/hip-dev-defrag.x"
## lammps executable with flags necessary to run in the KOKKOS environment. Must be compiled with KOKKOS package
lexe="/g/g10/gonzalez133/bin/lmp_elcapitan_kokkos_noapu -k on g 1 -sf kk -pk kokkos newton on neigh half"

## variable to be set iff memory defrag fails
memFail=0

export starttime=`date`

echo elcap kokkos_gpu START ${starttime}

## source the "affinity and environment" script to get all resources/paths correct
## we use '.' instead of 'source' since it is more portable and in every shell
. /g/g10/gonzalez133/SUBMISSION_SCRIPTS/elcap_env.sh

# Clear the system wide reserved core setting, since we do a custom set with corespecbal
unset MPIBIND_RESTRICT
## run the defrag code first. This checks to make sure memory is functional and optimal
flux run --exclusive -N 1 --tasks-per-node=1 -x -o cpu-affinity=off -o gpu-affinity=off -l -u --quiet --time-limit=5m -o exit-timeout=none ${USE_SPINDLE} $dexe

if [[ $? -ne 0 ]]; then
  echo "WARNING: The defrag device memory utility failed"
  ## high likely hood your LAMMPS run will crash, so we exit immediately
  ## if you wish to take the chance, remove memFail=1
  memFail=1
fi

## run the job iff memFail flag is unset
if [[ $memFail -eq 0 ]];
then
flux run --exclusive --verbose -N $NN -n $NG -x -c24 -o cpu-affinity=off -o gpu-affinity=off -o mpibind=on,corespecbal:17,smt:1,verbose:1 -l -u ${USE_SPINDLE} $lexe -in ${lmpIn} > ${lmpLog}
fi
