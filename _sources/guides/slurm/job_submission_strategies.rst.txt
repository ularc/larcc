.. _slurm_single_job_multiple_steps:

Single Job with Multiple Job Steps
==================================

If your workload consists of many small, independent tasks (e.g., 50 simulations), and each task uses only a few cores,
you can submit a single job that launches multiple parallel job steps within the script.

**Example Setup:**

- Each node in the compute queue has 128 cores.
- Request 2 nodes. So, 256 cores total.
- Divide 256 cores across 50 tasks. That is ~5 cores per task (``floor(256/50)``).
- Each node has ~515 GB of memory. That is ~4023 MB per core (``floor(515GB/128)``).

Assuming each individual task takes up to 6 hours and all tasks run in parallel, the overall runtime should also be around 6 hours.
However, in practice, delays or unexpected hang-ups can occur. To account for this, it's a good idea to request additional time as a buffer.

For example, adding a 2-hour grace period brings the total requested runtime to 8 hours,
which helps ensure the job completes successfully even if a few tasks take longer than expected.

**Sample Slurm Script:**

.. code-block:: bash

    #SBATCH --partition=compute
    #SBATCH --nodes=2
    #SBATCH --ntasks=256
    #SBATCH --time=08:00:00
    #SBATCH --mem-per-cpu=4023M
    #SBATCH --error=job.err
    #SBATCH --output=job.out
    #SBATCH --name=my_simulations

    module load your_program

    for i in {1..50}; do
      # --exact       Each job step is only given the resources it requested to avoid contention
      # --exclusive   Ensures srun uses distinct CPUs for each job step
      # The & makes each job step run in parallel
      srun --exact --exclusive --cpus-per-task=5 your_program ... &
    done

    # wait for all job steps to finish
    wait

**This approach:**

- Submits only one job, staying within the 20-job limit.
- Maximizes utilization of your allowed 2 nodes.

.. _slurm_job_array_submission:

Job Arrays
==========

If you prefer to submit each task as a separate job, use Slurm job arrays.
Each array index counts as a job, so you must limit concurrent jobs to 20.

**Example Setup:**

- 50 tasks total, so ``--array=0-49%20`` (only 20 run at a time).
- 2 nodes have 256 cores. So, with 20 array jobs running at a time you can maximize utilization with 12 cores per array job (``floor(256/20)``).
- Memory per task: 12 cores * 4023 MB = 48276 MB.

**Sample Slurm Script:**

.. code-block:: bash

    #SBATCH --partition=compute
    #SBATCH --ntasks=12
    #SBATCH --mem=48276M
    #SBATCH --array=0-49%20
    #SBATCH --time=08:00:00
    #SBATCH --error=array_%A_%a.err
    #SBATCH --output=array_%A_%a.out
    #SBATCH --name=my_array_jobs

    module load your_program

    your_program ...

**This approach:**

- Uses job arrays to manage many tasks.
- Keeps concurrent jobs within the allowed limit.

Requesting CPU Nodes with Multiple Parallel Tasks
=================================================

This is perhaps the most straightforward scenario and is ideal when you're running an application that uses only CPUs. Below are basic templates for both batch and interactive jobs.

**Batch Job Template**

.. code-block:: bash

    #!/bin/bash
    #SBATCH --partition=compute
    #SBATCH --nodes=<nodes>
    #SBATCH --ntasks-per-node=<processes>
    #SBATCH --cpus-per-task=<threads>
    #SBATCH --time=<walltime>

**Interactive Job Template**

.. code-block:: text

    salloc --partition=compute --nodes=<nodes> --ntasks-per-node=<processes> --cpus-per-task=<threads> --time=<walltime>

Now, let's break down how to choose values for ``<nodes>``, ``<processes>``, and ``<threads>`` depending on how your application behaves:

Case 1: Threaded Applications (e.g., OpenMP, TBB, MPI threads)
--------------------------------------------------------------

If your application internally distributes work across threads (e.g., using OpenMP or similar), and does not spawn multiple processes, then:

- nodes = 1
- processes = 1
- threads = 128 (assuming you're using a full node with 128 cores)

This setup gives your application full access to all cores on a single node for threading.

Case 2: Multi-Process Applications (Single Node)
------------------------------------------------

If your application spawns multiple processes that should run within the same node (and does not benefit from distribution across multiple nodes), then:

- nodes = 1
- processes = 128
- threads = 1

This configuration runs 128 independent processes, each using one core.

Case 3: Hybrid Parallelism (Multiple Processes, Each with Threads)
------------------------------------------------------------------

If your application runs multiple processes, and each process uses multiple threads (e.g., VASP without GPU support), then:

- nodes = 1
- processes = <number of processes>
- threads = <threads per process>

This allows you to fine-tune how many cores each process uses, while keeping everything within a single node.

Case 4: Multi-Node Jobs
-----------------------

If your workload requires multiple nodes, set:

- nodes = <number of nodes>
- processes >= number of nodes (at minimum)

.. warning::

    Be mindful of per-user node limits. Requesting more nodes than allowed will result in job rejection or queuing delays.

Additional Options
------------------

You can further customize how your tasks run:

- Use multiple job steps within a single job (see: :ref:`Single Job with Multiple Job Steps <slurm_single_job_multiple_steps>`)
- Use job arrays to manage many similar tasks efficiently (see: :ref:`Job Arrays <slurm_job_array_submission>`)

These approaches help you stay within job submission limits while maximizing resource utilization.


Single GPU node with one task per GPU and CPU cores evenly distributed across tasks
===================================================================================

This setup is ideal for applications that leverage GPU acceleration and can run multiple tasks in parallel.

**Hardware Overview (Per GPU Node)**

- There are 2 GPUs per node in the ``gpu`` partition, so 2 tasks total.
- There are 48 CPU cores per node in the ``gpu`` partition, so 24 cpus per task (``48 cpus / 2 tasks``)
- Slurm recognizes 256926MB of RAM on each GPU node, so
  CPU memory per task (i.e. RAM) = CPU memory per gpu (since we have 1 task per GPU) = 256926MB/2 = 128463MB.

With these numbers in mind, here are the basic templates:

**Batch Job Template**

.. code-block:: bash

    #!/bin/bash
    #SBATCH --partition=gpu
    #SBATCH --nodes=<nodes>
    #SBATCH --ntasks-per-node=2
    #SBATCH --gpus-per-task=1
    #SBATCH --cpus-per-task=24
    #SBATCH --mem-per-gpu=128463M
    #SBATCH --time=<walltime>

**Interactive Job Template**

.. code-block:: text

    salloc --partition=gpu --nodes=1 --ntasks-per-node=2 --gpus-per-task=1 --cpus-per-task=24 --mem-per-gpu=128463M --time=<walltime>

This configuration ensures that each task gets exclusive access to one GPU and a fair share of CPU and memory resources. It's particularly useful for GPU-enabled applications that:

- Run two independent tasks per node, each using one GPU.
- Benefit from dedicated CPU cores for preprocessing, I/O, or hybrid CPU-GPU workloads.
- Require large memory allocations, such as deep learning models or molecular simulations.

If your application only uses one GPU per node, you can adjust ``--ntasks-per-node=1`` and scale up the CPU and memory accordingly.

When arrays keep in mind that each task is bound to
a GPU, so you can either:

1. Submit 4 array jobs at a time (i.e. ``%4``) if each array job requests a GPU.
2. Submit 2 array jobs at a time (i.e. ``%2``) if each array job requests 2 GPUs.
