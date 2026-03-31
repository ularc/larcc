.. _batch_job:

Batch Jobs
==========

These are jobs that are submitted to run in the background without requiring direct user interaction
once they start. The user submits the job to a queue, and Slurm schedules the job to run when resources
become available. This is ideal for large, non-interactive computational tasks, simulations, data analysis, etc.

Here, you write a job script (typically a shell script) that contains the commands to execute your task,
along with Slurm directives to specify resource requirements (e.g., number of nodes, CPUs, memory, etc.).
Once submitted, the job runs automatically without user interaction. 

Submitting batch jobs
---------------------

The command ``sbatch`` serves as the means to submit batch jobs to Slurm,
typically in the form of a shell script written in the bash command language.

.. note::

    A shell script is essentially a text file containing instructions
    that are parsed and executed by a shell or command-line interpreter.

When submitting a job to Slurm, the shell script must adhere to the following requirements:

1. The first line of the script should specify the shell to be used.
   This is accomplished by including a shebang (``#!``) followed by ``/bin/env``, a space,
   and the name of the desired shell. For example, for a bash script: ``#!/bin/env bash``.
   Alternatively, the path to the shell can be used directly: ``#!/bin/bash``.

2. The lines following lines should define a set of parameters in the form of comments
   (lines preceded by the ``#`` symbol). These parameters are utilized by Slurm
   to establish job priority and resource requirements. Each parameter should begin
   with the word ``SBATCH`` and should be placed on its own separate line. For instance:

   .. code-block:: bash
   		
      #!/bin/env bash
      #SBATCH --job-name=some_job_name
      #SBATCH --time=01:00

.. warning::

  DO NOT place anything between the first line of the script (i.e ``#!/bin/bash`` or ``#!/bin/env bash``) and the ``#SBATCH`` directives
  as doing so prevents Slurm from properly parsing the job parameters. For example:

  **This is correct:**

  .. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=...
    #SBATCH --partition=...
    #SBATCH --nodes=...
    #SBATCH --ntasks-per-node=...
    #SBATCH --gpus-per-task=...
    #SBATCH --cpus-per-task=...
    #SBATCH --time=...
    #SBATCH --output=...
    #SBATCH --error=...
    some command

  **This is incorrect:**

  .. code-block:: bash

    #!/bin/bash
    some command
    #SBATCH --job-name=...
    #SBATCH --partition=...
    #SBATCH --nodes=...
    #SBATCH --ntasks-per-node=...
    #SBATCH --gpus-per-task=...
    #SBATCH --cpus-per-task=...
    #SBATCH --time=...
    #SBATCH --output=...
    #SBATCH --error=...

A list of common sbatch options is provided below for convenience:

.. csv-table:: Common sbatch options
  :header-rows: 1
  :widths:  5, 8, 5, 4
  :stub-columns: 1
  :file: csv/sbatch_cmds.csv

For more comprehensive details, please consult 
`Slurm's sbatch manual <https://slurm.schedmd.com/sbatch.html>`_.

Once the necessary parameters have been incorporated into the script,
users should proceed to configure the environment for the application they intend to execute.
If the job uses a software installed within the cluster,
users are encouraged to load the corresponding modulefiles within the script using
the ``module load <modulefile>`` command.
Alternatively, users can load their custom modulefiles or manually set
the required environmental variables.
Any additional tasks such as directory or file creation, among others,
should be performed at this stage. Note that the submission script
essentially functions as a shell script with additional comments at the beginning.
As such, any actions that a user would typically carry out in a regular shell session
can be executed within the script.

Finally, the script should encompass the core job tasks, 
which typically involve executing simulations, experiments, or other relevant operations.
During this phase, users would typically initiate the necessary scientific software required
for their specific needs.

Batch Job Example
-----------------

Consider the following bash script:

..  code-block:: bash
    :caption: Example bash script to launch a batch job

     #!/bin/bash
     #SBATCH --job-name=example_batch_job
     #SBATCH --error=/home/user/%x.%j.err
     #SBATCH --output=/home/user/%x.%j.out
     #SBATCH --time=05:30:00
     #SBATCH --ntasks-per-node=128
     #SBATCH --nodes=2
     #SBATCH --partition=compute
     
     # print list of nodes assigned to the job.
     # Example output:
     # larcc-cpu1
     # larcc-cpu2
     scontrol show hostnames $SLURM_JOB_NODELIST


In this script, the job is assigned the name *example_batch_job* using the ``#SBATCH --job-name``
directive. The maximum allowed running time is set to 5 hours and 30 minutes through the 
``#SBATCH --time`` directive. The job is configured to utilize 2 nodes (``#SBATCH --nodes``)
and 128 processors per node (``#SBATCH --ntasks-per-node``). It is intended to run in the *compute* queue
(``#SBATCH --partition``). Any encountered error messages are to be stored in the file 
``/home/user/%x.%j.out``, where ``%x`` is replaced with the job name specified with the
``#SBATCH --job-name`` directive and ``%j`` is replaced with the job ID assigned by Slurm.
Similarly, non-error messages are directed to the file ``/home/user/%x.%j.err``
for logging purposes. The environmental variable ``SLURM_JOB_NODELIST`` is passed
to the script by slurm (see section :ref:`Slurm environmental variables <slurm_env_vars>`).

Suppose this script is located at path: ``/home/user/example_batch_job.sh``. Then,
the command below would submit the batch job to slurm:

..  code-block:: bash
    
    sbatch /home/user/example_batch_job.sh

.. _job_arrays:

Job Arrays
==========

Job arrays are a powerful feature in Slurm that allow you to submit and manage multiple similar jobs efficiently using a single job script. This is especially useful when you need to run the same program many times with different input parameters, files, or configurations.

Instead of writing and submitting dozens (or hundreds) of separate job scripts, you can use a single script and let Slurm handle the rest.

How Job Arrays Work
-------------------

When you use the ``#SBATCH --array`` directive in your job script, Slurm creates multiple jobs, each with a unique index called ``SLURM_ARRAY_TASK_ID``. This environment variable is automatically set by Slurm and can be used inside your script to control behavior for each job.

Each array index corresponds to a separate job instance. For example, ``#SBATCH --array=1-3``
will submit three jobs, with ``SLURM_ARRAY_TASK_ID`` set to 1, 2, and 3 respectively. You can use this variable to select input files, set parameters, or control logic in your script.

.. warning::

    **Important:** The order in which array jobs run is not guaranteed. For example, the job with SLURM_ARRAY_TASK_ID=2 may run before or after the one with ID 3.

Array Syntax Options
--------------------

You can define array indices in several ways:

.. list-table:: 

    * -

      - **Description**

      - **Example**

      - **Example Outcome**

    * - Explicit list

      - Comma separated list of array IDs.

      - 
        .. code-block:: bash

            #SBATCH --array=1,2,3,7,10
    
      - Runs 5 jobs with Array Task IDs 1, 2, 3, 7, 10.

    * - Range

      - Interval of array IDs. Both endpoints are inclusive.

      -
        .. code-block:: bash

            #SBATCH --array=1-10

      - Runs 10 jobs with Array Task IDs 1, 2, 3, 4, ..., 9, 10.

    * - Range with an offset to skip array indexes.

      - Interval of array IDs.

      - 
        .. code-block:: bash

            #SBATCH --array=1-10:2
    
      - Runs 5 jobs with Array Task IDs 1, 3, 5, 7, 9.

    * - Limit concurrent jobs

      - Indicate how many arrays jobs are submitted to the queue at a given time.

      - 
        .. code-block:: bash

            #SBATCH --array=0-49%20
    
      - Submit 50 jobs, with Array Task IDs 0, 1, 2, ..., 48, 49, but only 20 run at a time.

Example Job Array Script
------------------------

.. code-block:: bash

    #!/bin/bash
    #SBATCH --partition=compute
    #SBATCH --array=1-10
    #SBATCH --ntasks=1
    #SBATCH --cpus-per-task=4
    #SBATCH --mem=8G
    #SBATCH --time=01:00:00
    #SBATCH --output=job_%A_%a.out
    #SBATCH --error=job_%A_%a.err
    #SBATCH --job-name=array_example

    module load my_program

    # Use SLURM_ARRAY_TASK_ID to select input file
    INPUT_FILE="input_${SLURM_ARRAY_TASK_ID}.dat"

    # Run the program with the selected input
    my_program --input $INPUT_FILE --output output_${SLURM_ARRAY_TASK_ID}.dat

**Explanation:**

- ``#SBATCH --array=1-10``: Submits 10 jobs, each with a unique array index from 1 to 10.
- ``#SBATCH --ntasks=1``: Each job runs a single task (i.e., spawns one process).
- ``#SBATCH --cpus-per-task=4``: Each job requests 4 CPU cores. Since --ntasks=1, this likely means the process will use 4 threads.
- ``#SBATCH --mem=8G``: Each job requests 8 GB of RAM.
- ``#SBATCH --time=01:00:00``: Each job can run for up to 1 hour.
- ``#SBATCH --output=job_%A_%a.out`` and ``#SBATCH --error=job_%A_%a.err``
    - ``%A``: Replaced with the job ID of the array.
    - ``%a``: Replaced with the array index (i.e., the value of SLURM_ARRAY_TASK_ID).
- Each job runs independently with its own input and output.

**Resource Considerations:**

Since these jobs are submitted to the compute partition, we can estimate how they will be scheduled:

- **CPU usage:** 10 jobs * 1 task * 4 cores = 40 cores total. Each node in the compute queue has 128 cores, so all jobs can likely run on a single node.

- **Memory usage:** 10 jobs * 8 GB = 80 GB total. Each node in the compute queue has ~515 GB of RAM, so memory is not a limiting factor.

This means the scheduler may place all 10 jobs on the same node, depending on availability and other jobs in the queue.
