.. _gaussian:

Gaussian
########

The cluster provides the following versions of Gaussian:

.. list-table:: Available versions of Gaussian
   :widths: 10 10 10 10 10 
   :header-rows: 1

   * - Version
     - Linda support
     - CPU support
     - GPU support
     - Modulefile
   * - 16-A.03
     - yes
     - yes
     - no
     - ``gaussian/16-A.03-nvhpc-25.5``

Running Gaussian
================

When loading a gaussian module, the ``GAUSS_SCRDIR`` is automatically set to your scratch
space: ``/mnt/scratch/local/$USER`` (see :ref:`our storage guide <storage-on-compute-nodes>` for more information). If you
want to overwrite this value to use a different directory (e.g. ``/mnt/scratch/local/$USER/gaussian``):

- ensure the folder pointed to by ``GAUSS_SCRDIR`` exists. Keep in mind that your scratch folder ``/mnt/scratch/local/$USER`` is local to each node,
  deleted at the end of each job and created when starting a new job (see :ref:`our storage guide <storage-on-compute-nodes>` for more information).
- do so **AFTER** loading the module, else your change will have no effect. For example,

.. code-block:: bash

    # This works
    mkdir -p /mnt/scratch/local/$USER/gaussian
    module load gaussian/16-A.03-nvhpc-25.5
    export GAUSS_SCRDIR="/mnt/scratch/local/$USER/gaussian"

    # This does not
    mkdir -p /mnt/scratch/local/$USER/gaussian
    export GAUSS_SCRDIR="/mnt/scratch/local/$USER/gaussian"
    module load gaussian/16-A.03-nvhpc-25.5

Example Slurm Job Script
------------------------

.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=gaussian_cpu
    #SBATCH --partition=compute
    #SBATCH --nodes=1
    #SBATCH --ntasks-per-node=1
    #SBATCH --cpus-per-task=128
    #SBATCH --time=02:00:00
    #SBATCH --output=gaussian_%j.out
    #SBATCH --error=gaussian_%j.err

    module load gaussian/16-A.03-nvhpc-25.5

    # (OPTIONAL) Set Gaussian scratch directory
    # The default is "/mnt/scratch/local/$USER"
    export GAUSS_SCRDIR=/mnt/scratch/local/$USER/gaussian_scratch
    mkdir -p $GAUSS_SCRDIR

    # Gaussian input file
    INPUTFILE="molecule.com"

    # Run Gaussian
    g16 < $INPUTFILE > molecule.log