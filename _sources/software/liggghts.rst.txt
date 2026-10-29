.. _liggghts:

LIGGGHTS
########

The cluster provides the following versions of LIGGGHTS:

.. list-table:: Available versions of LIGGGHTS
   :widths: 3 3 3 3 7 10
   :header-rows: 1

   * - Version
     - MPI support
     - CPU support
     - GPU support
     - Binary name
     - Modulefile
   * - 3.8.0
     - yes
     - yes
     - no
     - ``liggghts``
     - ``liggghts/3.8.0-aocc-5.0.0-openmpi-2qdvhb5``

Running LIGGHTS
===============

Example Slurm Job Script
------------------------

.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=liggghts_job
    #SBATCH --error=liggghts.%j.err
    #SBATCH --output=liggghts.%j.out
    #SBATCH --time=05:00:00
    #SBATCH --ntasks-per-node=128
    #SBATCH --nodes=1
    #SBATCH --mem=515002
    #SBATCH --partition=compute

    module load openmpi/5.0.5-aocc-5.0.0-hzaiun6
    module load liggghts/3.8.0-aocc-5.0.0-openmpi-2qdvhb5

    # Run the simulation
    mpirun liggghts < in.file