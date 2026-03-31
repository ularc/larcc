Basic Slurm Terminology
=======================

Partition (a.k.a. Queue)
------------------------

A partition is a logical grouping of compute nodes, similar to a queue. Each partition may have different hardware, time limits, or access policies.
Use ``sinfo`` to list available partitions.

To check the current status of available queues and nodes, use the ``sinfo`` command.
This command provides a snapshot of which nodes are idle, allocated, or down, along with their associated partitions and time limits.

Example output:

.. code-block::

    PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    compute*     up 3-00:00:00      1  alloc larcc-cpu3
    compute*     up 3-00:00:00      9   idle larcc-cpu[1-2,4-10]
    gpu          up 2-00:00:00      3  alloc larcc-gpu[1-3]
    gpu          up 2-00:00:00      7   idle larcc-gpu[4-10]

In this example:

- The compute partition has 10 nodes, 1 of which is currently in use (alloc) and 9 are idle.
- The gpu partition has 10 nodes, with 3 allocated and 7 idle.
- The TIMELIMIT column shows the maximum wall time allowed per job in each partition.

Node
----

A node is a physical machine in the cluster. Each node has a specific number of CPU cores, memory, and possibly GPUs.

To get detailed information about a specific node, use:

.. code-block::

    scontrol show node <nodename>

For example:

.. code-block::
     
    scontrol show node larcc-cpu1

This will return detailed specs and current usage for the node:

.. code-block:: text

    NodeName=larcc-cpu1 Arch=x86_64 CoresPerSocket=64 
       CPUAlloc=0 CPUEfctv=128 CPUTot=128 CPULoad=0.00
       AvailableFeatures=(null)
       ActiveFeatures=(null)
       Gres=(null)
       NodeAddr=larcc-cpu1 NodeHostName=larcc-cpu1 Version=24.11.4
       OS=Linux 5.14.0-503.38.1.el9_5.x86_64 #1 SMP PREEMPT_DYNAMIC Wed Apr 16 16:38:39 UTC 2025 
       RealMemory=515002 AllocMem=0 FreeMem=505959 Sockets=2 Boards=1
       State=IDLE ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
       Partitions=compute 
       BootTime=2025-05-15T13:30:56 SlurmdStartTime=2025-07-30T13:57:36
       LastBusyTime=2025-09-22T16:10:19 ResumeAfterTime=None
       CfgTRES=cpu=128,mem=515002M,billing=128
       AllocTRES=
       CurrentWatts=240 AveWatts=180

Key fields to note:

- CPUTot: Total number of CPU cores available.
- RealMemory: Total memory available on the node.
- State: Current status (e.g., IDLE, ALLOC, DOWN).
- Partitions: Indicates which queue(s) the node belongs to.

Job
---

A job is a unit of work submitted to Slurm. It can be a single task or a collection of tasks (e.g., simulations, data processing).

Jobs are submitted using sbatch (batch jobs) or srun (interactive jobs).

A Job can have 5 states:

- PD (Pending): Waiting for resources.
- R (Running): Currently executing.
- CG (Completing): Finishing up.
- CD (Completed): Finished successfully.
- F (Failed): Encountered an error.

To view jobs currently in the queue or running, use: ``squeue``.

Example output:

.. code-block::

                    JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 3777   compute matlab_p jd01  R    4:02:04      1 larcc-cpu3
    3852_[226-241%20]       gpu Ecthelio jd02 PD       0:00      1 (QOSMaxNodePerUserLimit)
             3852_224       gpu Ecthelio jd02  R       2:00      1 larcc-gpu3
             3852_225       gpu Ecthelio jd02  R       2:00      1 larcc-gpu3
             3852_222       gpu Ecthelio jd02  R       2:01      1 larcc-gpu2
             3852_223       gpu Ecthelio jd02  R       2:01      1 larcc-gpu2
                 3343       gpu sno_pv80 jd03  R    4:02:05      1 larcc-gpu1

Explanation of columns:

- JOBID: Unique identifier for each job.
- PARTITION: Queue the job was submitted to.
- NAME: Job name.
- USER: Submitting user.
- ST: Job status (R = Running, PD = Pending).
- TIME: Runtime so far.
- NODELIST(REASON): Node(s) assigned or reason for pending status.


Job Steps
----------

A job step is a unit of work executed within a running job. 
While a job defines the overall resource allocation (e.g., number of nodes, CPUs, memory, time),
job steps are the actual commands or tasks that run using those resources.

Key Characteristics of a Job Step:

- **Executed with srun:** Job steps are typically launched using the ``srun`` command inside a job script or interactively.
- **Shares job resources:** All job steps run within the resource allocation defined by the parent job (``sbatch``).
- **Can run in parallel:** Multiple job steps can be launched simultaneously, each using a subset of the allocated resources.
- **Useful for multi-task jobs:** Ideal when you want to run several independent tasks (e.g., simulations, analyses) within a single job submission.
