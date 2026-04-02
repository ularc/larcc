.. _interactive_job:

Interactive Jobs
================

.. note::

    Interactive jobs are mainly for testing. For larger workloads, batch jobs are recommended.

These jobs are meant for users who need to run commands or scripts interactively on a compute node.
For example, if you want to run a program or script and see its output or error messages in real time,
or if you need to test something quickly.

You can submit an interactive job in two ways:

1. Submitting interactive jobs with ``salloc``
----------------------------------------------

Use the ``salloc`` command to request resources. Once you do, your terminal's prompt will change but you
will still be on the login node. The change signifies you have been granted an allocation. Here is an example:

.. code-block:: text

    [jd01@larcc-login1 ~]$ salloc --partition=gpu --job-name=tensorflow --time=5:00:00 --nodes=1 --ntasks=2 --gpus-per-task=1 --cpus-per-task=24
    salloc: Granted job allocation 3844
    salloc: Nodes larcc-gpu4 are ready for job
    bash-5.1$

You can see in the output above how the prompt changes from ``[jd01@larcc-login1 ~]$`` to ``bash-5.1$`` and messages
are displayed informing you of the job id and node assigned to your allocation.

Here is an example submission line:

.. code-block:: bash

    salloc --job-name=tensorflow --partition=gpu --nodes=1 --ntasks-per-node=2 --gpus-per-task=1 --cpus-per-task=24 --mem-per-gpu=128463M --time=5:00:00

When you submit an interactive job using ``salloc``, it follows a specific lifecycle:

- **Job Queuing:** If the scheduler accepts your request, ``salloc`` will pause while your job waits in the queue for resources to become available. This is normal behavior—your session won't start until the requested resources are allocated.

- **Resource Allocation & Shell Access:** Once the job is allocated, ``salloc`` will launch an interactive shell session on the assigned node(s). You'll be dropped into a command-line environment where you can run commands directly.

    - At this point, you can:
    
        - Launch one or more job steps using the srun command.
        - Or, if preferred, SSH into the allocated node and manually run your application.

- **Job Completion:** When you exit the shell session (e.g., by typing exit or closing the terminal), salloc will automatically mark the job as completed and release the allocated resources back to the cluster for other users.


2. Submitting interactive jobs with ``srun``
--------------------------------------------

Run ``srun`` directly to both allocate resources and launch a single jobstep at the same time. This has the disadvantage
that once the job step finishes, so will the allocation.
Users typically use the following template:

.. code-block:: bash

    srun --partition=<partition> --nodes=<nodes> --ntasks-per-node=<cpus> --time=<walltime> --pty /bin/bash -i

Here, ``<nodes>`` specifies the number of nodes, 
``<cpus>`` denotes processors per node, and ``<walltime>`` sets the maximum duration for the session.
Additional options like ``--mem`` can be included to customize job requirements
(see `Slurm's srun manual <https://slurm.schedmd.com/srun.html>`_ for more information).

Upon starting an interactive job, the system provides feedback:

.. code-block::

    srun: job 12345 queued and waiting for resources
    srun: job 12345 has been allocated resources

The user is then logged into an allocated node. Ending the session will terminate the job.
Jobs exceeding walltime or memory limits will be automatically aborted.

Interactive Job Example
-----------------------

.. code-block:: bash

    # 1. log into the cluster
    ssh user@larcc.hpc.louisville.edu
    # 2. start a job in the compute queue with the following specifications:
    #    a) The maximum time allowed for the job to run is 5h (--time=5:00:00)
    #    b) The maximum memory that can be used by the job is 10G (--mem=10G)
    #    c) Run on a single node (--nodes=1)
    #    d) Allocate 4 cores for this job on the node (--ntasks-per-node=4)
    #    e) Instead of hanging and waiting for resources to be available, exit immediately (-i)
    #    f) Specify the task (a shell in this case) to execute (--pty /bin/bash)
    srun --partition=compute --time=5:00:00 --mem=10G --ntasks-per-node=4 --nodes=1 --pty /bin/bash -i

.. note::
    The ``-i`` option for ``srun`` is optional. It prevents your terminal from hanging
    if the job is queued due to unavailable resources when the command is executed.

Keeping an interactive job alive
--------------------------------

To prevent premature termination of interactive jobs due to connection disruptions,
using a terminal multiplexer like ``tmux`` is recommended. Follow these steps:

1. Log into the cluster.
2. Run ``tmux new -s session_name``, where ``session_name``
   can be any name you choose. **Your terminal will change**, showing a green strip at the bottom,
   indicating you are in a tmux session. The session name appears at the bottom left, and the node's
   hostname is at the bottom right.
3. Launch your interactive job within the tmux session.

If disconnected, reconnect to the login node and use ``tmux attach -t session_name`` to resume your session.
For multiple sessions, use ``tmux list-session`` (or, even shorter, ``tmux ls``) to list them.
