
Job Dependencies
################

In many HPC workflows, tasks must be executed in a specific order. For example, you might need to run a preprocessing job before launching a simulation, or wait for multiple simulations to finish before starting a post-processing step. Slurm allows you to manage these relationships using **job dependencies**.

What Is a Job Dependency?
=========================

A **job dependency** tells Slurm to delay the start of a job until another job (or set of jobs) meets a specific condition—such as completing successfully. This helps automate workflows and ensures that jobs run in the correct sequence without manual intervention.

Basic Syntax
============

To create a job dependency, use the ``--dependency`` option with ``sbatch``. The general format is:

.. code-block:: bash

    sbatch --dependency=<type>:<job_id> your_script.sh

Where:

- ``<type>`` is the dependency condition.
- ``<job_id>`` is the ID of the job you want to depend on.

Common Dependency Types
=======================

+--------------+-------------------------------------------------------------+
| Type         | Description                                                 |
+==============+=============================================================+
| after        | Run after the specified job starts.                         |
+--------------+-------------------------------------------------------------+
| afterok      | Run only if the specified job completes successfully.       |
+--------------+-------------------------------------------------------------+
| afternotok   | Run only if the specified job fails.                        |
+--------------+-------------------------------------------------------------+
| afterany     | Run after the specified job finishes (success or failure).  |
+--------------+-------------------------------------------------------------+
| singleton    | Run only if no other job with the same name is running.     |
+--------------+-------------------------------------------------------------+

Example: Simple Sequential Workflow
===================================

Let's say you have two jobs: ``preprocess.sh`` and ``simulate.sh``. You want ``simulate.sh`` to run only after ``preprocess.sh`` completes successfully.

.. code-block:: bash

    # Submit the first job
    jobid=$(sbatch --parsable preprocess.sh)

    # Submit the second job with a dependency
    sbatch --dependency=afterok:$jobid simulate.sh

Here, ``$(sbatch --parsable preprocess.sh)`` is read as *"run the command ``sbatch --parsable preprocess.sh`` in a sub-shell"*. The ``--parsable`` flag
indicates ``sbatch`` to only print the job id, which is subsequently storedinto the ``jobid`` variable.

Example: Multiple Dependencies
==============================

You can also specify multiple job IDs:

.. code-block:: bash

    sbatch --dependency=afterok:12345:12346:12347 postprocess.sh

This job will run only after jobs 12345, 12346, and 12347 all complete successfully.

Example: Using Job Arrays with Dependencies
===========================================

Suppose you submit a job array and want a post-processing job to run after all array tasks finish:

.. code-block:: bash

    # Submit the array
    array_jobid=$(sbatch --array=0-9 simulation_array.sh | awk '{print $4}')

    # Submit the dependent job
    sbatch --dependency=afterok:$array_jobid postprocess.sh

Note: The dependency applies to the entire array, not individual tasks.

Tips
====

- You can chain jobs together to build complex workflows.
- Use ``squeue`` to monitor job status and verify dependencies.
- Combine dependencies with job names and ``singleton`` to avoid duplicate runs.
