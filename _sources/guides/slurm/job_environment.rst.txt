.. _slurm_env_vars:

Slurm environmental variables
=============================

When launching a job, slurm retains information about the servers allocated, cores assigned,
working directory from which the job was launched, among other things. Slurm passes
this information to the job via environmental variables. The table below shows some variables
commonly used within the shell scripts of batch jobs.

.. csv-table:: Commonly used Slurm environmental variables
  :header-rows: 1
  :widths:  5, 8, 5
  :stub-columns: 1
  :file: csv/slurm_env_vars.csv

For more comprehensive details, please read 
`Section "OUTPUT ENVIRONMENT VARIABLES" of Slurm's sbatch manual <https://slurm.schedmd.com/sbatch.html#SECTION_OUTPUT-ENVIRONMENT-VARIABLES>`_.
