.. _vasp:

VASP
####

License Restrictions
====================

VASP is licensed software. Only users in the ``vasp`` group are authorized to use it.
To check your group membership run the command ``groups``.

If you're not a member and attempt to load a VASP module, you'll see an error like:

.. code-block:: text

    Lmod has detected the following error:  Access denied: user '<username>' is not in group 'vasp' 
    While processing the following module(s):
        Module fullname                   Module Filename
        ---------------                   ---------------
        vasp/6.5.1-nvhpc-25.5-mkl-2025.1  /opt/shared/modulefiles/manual/vasp/6.5.1-nvhpc-25.5-mkl-2025.1.lua

Running VASP
============

.. list-table:: Available versions of VASP
   :widths: 3 4 3 3 4 7 7
   :header-rows: 1

   * - Version
     - MPI support
     - CPU support
     - GPU support
     - Compilers and Libraries
     - Binaries
     - Modulefile
   * - 6.5.1
     - yes (openmpi)
     - yes
     - yes (**preferred**)
     - ``nvhpc``, ``intel-mkl``
     - ``vasp_gam``, ``vasp_ncl``, and ``vasp_std``
     - ``vasp/6.5.1-nvhpc-25.5-mkl-2025.1``
   * - 6.5.1
     - yes (openmpi)
     - yes
     - no
     - ``amd-aocc``, ``amd-aocl``
     - ``vasp_gam``, ``vasp_ncl``, and ``vasp_std``
     - ``vasp/6.5.1-aocc-5.0.0-openmpi-5.0.5-aocl-5.0``
   * - 6.4.3
     - yes (openmpi)
     - yes
     - yes (**preferred**)
     - ``nvhpc``, ``intel-mkl``
     - ``vasp_gam``, ``vasp_ncl``, and ``vasp_std``
     - ``vasp/6.4.3-nvhpc-25.5-mkl-2025.1``
   * - 6.4.3
     - yes (intel-mpi)
     - yes
     - no
     - ``intel-oneapi``, ``intel-mkl``
     - ``vasp_gam``, ``vasp_ncl``, and ``vasp_std``
     - ``vasp/6.4.3-oneapi-2025.0.0-mkl-2025.1``

VASP on GPU nodes
-----------------

VASP is designed to run with one MPI process per GPU. Each process spawns multiple OpenMP threads,
ideally bound to separate CPU cores. For example, on a node with 2 GPUs and 48 CPU cores, use:

- **2 MPI processes** (1 per GPU)
- **24 OpenMP threads per process** (48 cores / 2 processes)

This ensures optimal utilization of both CPU and GPU resources.

VASP on CPU-only nodes
-----------------------

MPI Ranks per Socket
~~~~~~~~~~~~~~~~~~~~

A common recommendation is to launch 2 MPI ranks per socket, especially when each socket has a large number of cores
(e.g., 48 or 96). This setup helps balance communication overhead and computational efficiency,
particularly for Gamma-point-only calculations.

Our CPU-only nodes have 2 sockets with 64 cores each, so this setting is appropriate.

Use of NCORE
~~~~~~~~~~~~

NCORE defines the number of cores used per MPI rank for FFT parallelization.
A good heuristic is to set NCORE to match the number of cores per socket or divide the total cores per node by the number of MPI ranks.
For example, on our dual-socket nodes with 64 cores per socket (128 total),
using 2 MPI ranks per socket (4 total) would suggest NCORE = 32.

Avoid Over-Parallelization
~~~~~~~~~~~~~~~~~~~~~~~~~~

Using more MPI ranks than necessary can lead to diminishing returns due to increased communication overhead.
It's generally advised not to exceed the number of physical cores per socket with MPI ranks.

Benchmarking
~~~~~~~~~~~~

The best configuration often depends on the specific system and calculation type.
Use the LOOP: cpu time entry in the OUTCAR file to compare performance across different configurations.


Example Slurm Job Script
------------------------

.. warning::

   If you plan to use the scripts provided below, please keep the following in mind:

   1. **Case sensitivity matters:** Unlike Windows, Linux treats uppercase and lowercase letters as different characters.
      For example, ``$vasp_exec`` and ``$VASP_EXEC`` refer to two distinct variables.

   2. **Line continuation requires spacing:** In bash, the ``\`` character is used to continue a command onto the next line.
      However, you **must include a space before the backslash** to prevent command-line options from being accidentally
      merged.

      **Example (correct):**

      .. code-block:: bash

         mpirun -np 4 \
         vasp_std

      **Example (incorrect):**

      .. code-block:: bash

         mpirun -np 4\
         vasp_std

      The shell treats the correct example as ``mpirun -np 4 vasp_std`` and the 
      incorrect example as ``mpirun -np 4vasp_std``.

Example VASP on GPU with Openmpi
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=vasp_gpu
    #SBATCH --partition=gpu
    #SBATCH --nodes=1
    #SBATCH --gpus-per-node=2
    #SBATCH --ntasks-per-node=2
    #SBATCH --cpus-per-task=24
    #SBATCH --gpus-per-task=1
    #SBATCH --time=02:00:00
    #SBATCH --output=vasp_%j.out
    #SBATCH --error=vasp_%j.err

    ulimit -l unlimited

    module load vasp/6.4.3-nvhpc-25.5-mkl-2025.1

    # Path to your VASP executable. You can use either of:
    # vasp_gam, vasp_ncl, or vasp_std
    # NOTE: The VASP_ROOT variable is set by the VASP module above.
    VASP_EXEC=$VASP_ROOT/bin/vasp_gam

    mpirun -np $SLURM_NTASKS --map-by node:PE=$SLURM_CPUS_PER_TASK --bind-to core \
        -x OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK \
        -x OMP_STACKSIZE=512m \
        -x OMP_PLACES=cores \
        -x OMP_PROC_BIND=close \
        $VASP_EXEC ...

Example VASP on CPU-only with Openmpi and AMD libraries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=vasp_cpu_amd
    #SBATCH --partition=compute
    #SBATCH --nodes=1
    #SBATCH --ntasks-per-socket=2
    #SBATCH --ntasks=4                # 2 MPI ranks per socket × 2 sockets
    #SBATCH --cpus-per-task=32        # 32 cores per MPI rank
    #SBATCH --time=24:00:00
    #SBATCH --output=vasp_output.log
    #SBATCH --error=vasp_error.log

    ulimit -l unlimited

    module load vasp/6.5.1-aocc-5.0.0-openmpi-5.0.5-aocl-5.0

    # Path to your VASP executable. You can use either of:
    # vasp_gam, vasp_ncl, or vasp_std
    # NOTE: The VASP_ROOT variable is set by the VASP module above.
    VASP_EXEC=$VASP_ROOT/bin/vasp_gam

    mpirun -np $SLURM_NTASKS \
        --map-by ppr:$SLURM_NTASKS_PER_SOCKET:socket:PE=$SLURM_CPUS_PER_TASK \
        --bind-to core \
        -x OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK \
        -x OMP_STACKSIZE=512m \
        -x OMP_PLACES=cores \
        -x OMP_PROC_BIND=close \
        $VASP_EXEC ...

Example VASP on CPU-only with Intel MPI and Intel libraries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=vasp_cpu_intelmpi
    #SBATCH --partition=compute
    #SBATCH --nodes=1
    #SBATCH --ntasks=4                # 2 MPI ranks per socket × 2 sockets
    #SBATCH --cpus-per-task=32        # 32 cores per MPI rank
    #SBATCH --time=24:00:00
    #SBATCH --output=vasp_output.log
    #SBATCH --error=vasp_error.log

    ulimit -l unlimited

    # Load VASP
    module load vasp/6.4.3-oneapi-2025.0.0-mkl-2025.1

    # Path to your VASP executable. You can use either of:
    # vasp_gam, vasp_ncl, or vasp_std
    # NOTE: The VASP_ROOT variable is set by the VASP module above.
    VASP_EXEC=$VASP_ROOT/bin/vasp_gam

    # Run VASP
     mpirun -np $SLURM_NTASKS -genv I_MPI_PIN_DOMAIN=omp -genv I_MPI_PIN=yes \
        -genv OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK -genv OMP_STACKSIZE=512m \
        -genv OMP_PLACES=cores -genv OMP_PROC_BIND=close -genv I_MPI_DEBUG=4 \
        $VASP_EXEC ...
