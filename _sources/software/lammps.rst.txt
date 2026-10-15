.. _lammps:

LAMMPS
######

The cluster provides the following versions of LAMMPS:

.. list-table:: Available versions of LAMMPS
   :widths: 3 3 3 3 3 7 10
   :header-rows: 1

   * - Version
     - MPI support
     - CPU support
     - GPU support
     - Binary name
     - Modulefile
     - Packages
   * - 20240829.2
     - yes
     - yes
     - yes (**preferred**)
     - ``lmp_mpi_gpu``
     - ``lammps/20240829.2-nvhpc-25.5``
     - GPU, KOKKOS, KSPACE, MANYBODY, MOLECULE, REAXFF, RIGID, OPENMP, EXTRA-MOLECULE, EXTRA-COMPUTE, EXTRA-DUMP, EXTRA-FIX

Running LAMMPS
==============

The current LAMMPS built in the cluster is designed to run with one MPI process per GPU. Each process spawns multiple OpenMP threads,
ideally bound to separate CPU cores. For example, on a node with 2 GPUs and 48 CPU cores, use:

- **2 MPI processes** (1 per GPU)
- **24 OpenMP threads per process** (48 cores / 2 processes)

This ensures optimal utilization of both CPU and GPU resources.

Example Slurm Job Script
------------------------

.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=lammps_gpu
    #SBATCH --partition=gpu
    #SBATCH --nodes=1
    #SBATCH --gpus-per-node=2
    #SBATCH --ntasks-per-node=2
    #SBATCH --cpus-per-task=24
    #SBATCH --gpus-per-task=1
    #SBATCH --time=02:00:00
    #SBATCH --output=lammps_%j.out
    #SBATCH --error=lammps_%j.err

    # All requirements will be automatically loaded
    module load lammps/20240829.2-nvhpc-25.5
    
    # Activate any environment variables or paths if needed
    export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
    export OMP_PLACES=cores
    export OMP_PROC_BIND=close

    # Path to your LAMMPS executable.
    # NOTE: The LAMMPS_ROOT variable is set by the lammps module above
    LAMMPS_EXEC=$LAMMPS_ROOT/bin/lmp_mpi_gpu

    ulimit -l unlimited

    # Run the simulation
    mpirun -np $SLURM_NTASKS --bind-to core \
        -x OMP_NUM_THREADS \
        -x OMP_PLACES \
        -x OMP_PROC_BIND \
        $LAMMPS_EXEC -in input.lmp

Building LAMMPS
===============

This example demonstrates how to build LAMMPS version `29Aug2024_update2` with GPU support using NVIDIA's HPC SDK (``nvhpc``) 25.5 and CUDA 12.9.

LAMMPS provides a set of CMake presets to simplify configuration. These are located in: ``stable_29Aug2024_update2/cmake/presets/``.
This example uses the following presets:

- ``basic.cmake`` - Enables core packages: KSPACE, MANYBODY, MOLECULE, RIGID
- ``kokkos-cuda.cmake`` - Enables the KOKKOS package with CUDA and OpenMP support
- ``nvhpc.cmake`` - Configures compilers and MPI settings for NVIDIA's HPC toolkit

.. code-block:: bash

    INSTALL_PREFIX=/path/to/lammps/install

    # Download and extract the specified LAMMPS version
    wget https://github.com/lammps/lammps/archive/refs/tags/stable_29Aug2024_update2.tar.gz
    tar xf stable_29Aug2024_update2.tar.gz
    mkdir -p stable_29Aug2024_update2/build
    cd stable_29Aug2024_update2/build

    # Load required modules
    module load cmake/3.30.5-gcc-11.5.0-zxhlylf
    module load nvhpc/25.5

    # Update the Kokkos preset to match the GPU architecture (e.g., H100 = HOPPER90)
    sed -i 's/^set(Kokkos_ARCH_.*/set(Kokkos_ARCH_HOPPER90 ON CACHE BOOL "" FORCE)/' ../cmake/presets/kokkos-cuda.cmake
    # Update the Kokkos preset to add NATIVE architecture
    sed -i -e '/set(Kokkos_ARCH_HOPPER90 ON CACHE BOOL "" FORCE)/a\' -e 'set(Kokkos_ARCH_NATIVE ON CACHE BOOL "" FORCE)' ../cmake/presets/kokkos-cuda.cmake

    # Configure the build
    cmake -C ../cmake/presets/basic.cmake \
          -C ../cmake/presets/kokkos-cuda.cmake \
          -C ../cmake/presets/nvhpc.cmake \
          -D BUILD_SHARED_LIBS=ON \
          -D LAMMPS_MACHINE=mpi_gpu \
          -D CMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
          -D CMAKE_PREFIX_PATH="$NVHPC_ROOT;$NVHPC_ROOT/cuda/12.9;$NVHPC_ROOT/math_libs;$NVHPC_ROOT/cuda/12.9/targets/x86_64-linux/lib/cmake" \
          -D CMAKE_BUILD_TYPE=Release \
          -D CUDAToolkit_INCLUDE_DIRECTORIES=$NVHPC_ROOT/cuda/12.9/include \
          -D CMAKE_CXX_STANDARD=17 \
          -D LAMMPS_MEMALIGN=64 \
          -D PKG_REAXFF=ON \
          -D PKG_GPU=ON \
          -D PKG_OPENMP=ON \
          ../cmake

    # Build and install
    make
    make install
