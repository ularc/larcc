.. _ansys-mech:

Remote Solver Manager (RSM)
===========================

Setup
^^^^^
The RSM is used by ANSYS Workbench to submit jobs to the cluster directly from Workbench on an user's desktop.

.. warning::
  To use this feature Phineas users must have Ansys 2023R2 installed on their desktops.

#. Open the Ansys RSM application in your workstation and click on the "Add Cluster" button:

    .. code-block:: RST
      :caption: TODO: Create new image

      .. image:: images/ansys_rsm_1.png
           :width: 800

#. In the "HPC Resource" tab fill in the fields and checkboxes as shown below. On the "Submit host" field indicate the IP address of the cluster (submit a ticket to Speed IT to get the IP if you do not already have it):

    .. code-block:: RST
      :caption: TODO: Create new image

      .. image:: images/ansys_rsm_2.png
           :width: 800

#. In the "File Management" tab fill in the fields and checkboxes as shown below. Replace the word **USERNAME** with your actual username **in the cluster**.
    .. code-block:: RST
      :caption: TODO: Create new image

      .. image:: images/ansys_rsm_3.png
           :width: 800

#. Before continuing to the "Queues" tab, navigate to the "credentials" section located at the left-most pane. Then, under section "Accounts" (on the mid pane) ensure that your user is spelled **EXACTLY** as in the cluster. If a default user appears and it is not spelled as your cluster username, delete using the "Delete button" and create a new one using the "Create button" as shown in the image below.

    .. warning::
      If you are using a computer from the university, your default username will show up with the prefix "AD\\", which is **INCORRECT**.

    .. code-block:: RST
      :caption: TODO: Create new image

      .. image:: images/ansys_rsm_4.png
           :width: 800

#. Click on the "Phineas" section on the left-most pane and navigate to the "Queues" tab. Then click the "Discover button" as shown below.

    .. code-block:: RST
      :caption: TODO: Create new image

      .. image:: images/ansys_rsm_5.png
           :width: 800

Usage
^^^^^

Start watching `this Ansys Tutorial <https://youtu.be/QPld56j93wc>`_ from minute 5:55.

Mechanical APDL (MAPDL)
=======================

Basics
^^^^^^

There are two executables that can be used to invoke the solver from the command line:

- ``mapdl``
- ``ansysYYR`` (``YY`` is the corresponding release's year
  and ``R`` the release number. For instance, for Ansys R2023-1 the
  executable is named ``ansys231``)

Since ``ansysYYR`` is a symlink to ``mapdl``, invoking the solver through either
executable works the same. 

.. note::
   Users may prefer to call ``mapdl`` instead of ``ansysYYR`` on their batch scripts to make them
   portable across ansys versions.

Parallel and distributed modes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``mapdl`` can be invoked with support for 3 processing mechanisms: *Shared-memory parallel (SMP)*,
*Distributed-memory parallel (DMP)* and *Mixed DMP-SMP*. As per Ansys documentation:

    **DMP mode:** All features in the simulation support distributed-memory parallelism, and it is used throughout the solution. This mode typically provides optimal performance.

    **Mixed mode:** The simulation involves a particular set of computations that do not support DMP processing. Examples include certain equation solvers and remeshing due to mesh nonlinear adaptivity. In these cases, distributed-memory parallelism is used throughout the solution, except for the unsupported set of computations. When that step is reached, the worker processes simply wait while the master process uses shared-memory parallelism to perform the computations. After the computations are finished, the worker processes continue to compute again until the entire solution is completed.

    **SMP mode:** The simulation involves an analysis type or feature that does not support DMP processing. In this case, distributed-memory parallelism is disabled at the onset of the solution, and shared-memory parallelism is used instead. The worker processes are not involved at all in the solution but simply wait while the master process uses shared-memory parallelism to compute the entire solution.

The following table shows the capabilities of each solver to run on each of the aforementioned modes:

.. csv-table:: Parallel Capability in SMP, DMP, and Hybrid Parallel Processing
  :header-rows: 1
  :widths:  8, 2, 8
  :stub-columns: 1
  :file: csv/ansys_mapdl_parallel_capabilities.csv

Command line options
^^^^^^^^^^^^^^^^^^^^

The table below shows some of the most useful options to invoke ``mapdl`` with. To have
more detailed information about what other options are available, please refer to 
chapter 4 of the ANSYS Mechanical APDL Operations Guide.

.. csv-table:: Common mapdl options
  :header-rows: 1
  :widths:  3, 8, 8
  :stub-columns: 1
  :file: csv/ansys_mapdl_cmds.csv

Run in a single node 
^^^^^^^^^^^^^^^^^^^^

If running a DMP analysis, use the ``-dis`` option to enable DMP mode
and ``-np`` to specify the number of cores. For example:

.. code-block:: bash

    # "-np 6" means: use 6 cores
    mapdl -dis -np 4 -i input.dat -o solve.out

If running a Mixed (DMP-SMP) analysis, use ``-dis`` option to enable DMP mode,
``-np`` to specify the number of processes and ``-nt`` to specify the number
of threads per process. For example:

.. code-block:: bash

    # "-np 4" and "-nt 4" means:
    # use (num processes) * (threads per process) = 4 * 4 = 16 cores
    mapdl -dis -np 4 -nt 4 -i input.dat -o solve.out

Run in multiple nodes
^^^^^^^^^^^^^^^^^^^^^

This is only supported in DMP mode and can be achieved by using the ``-machines`` option
or an MPI file specified through the ``-mpifile`` option.

**Using** ``-machines``:

Specify the number of cores to use on each machine using the format:
``machine1:NP1:machine2:NP2:...``, where ``NP1`` is the number of cores
``machine1`` should use, ``NP2`` the number of cores ``machine2`` should use and so on.
For example:

.. code-block:: bash

    # "-machines phineas-c01:4:phineas-c04:2" means:
    # run on phineas-c01 and phineas-c04 using 4 cores and 2 cores respectively
    mapdl -dis -machines phineas-c01:4:phineas-c04:2 -i input.dat -o solve.out

**Using** ``-mpifile``:

.. warning::
    The ``-mpifile`` option CANNOT be used in conjunction with the ``-np`` or
    ``-machines`` option.

First, write the appropriate MPI file based on the type of MPI software being used. Ansys
defaults to Intel MPI, but OpenMPI is supported as well. Beware the format used  in the
MPI file differs from one MPI type to another. For example:

.. code-block:: bash

    # FOR INTEL MPI:
    #
    # obtain the location of the ansysdisYYR executable (YY=Ansys release year, R=release number).
    distributed_mapdl=$(which ansysdis231)
    # create an Intel MPI compatible MPI file. Each line with "-host" and "-np" 
    # indicates a machine and the respective number of cores to use. The rest
    # of each line defines ansys parameters like input, output and enabling of DMP mode. 
    cat > mpifile_intelmpi << EOF
    -host phineas-c01 -np 4 $distributed_mapdl -dis -i input.dat -o solve.out
    -host phineas-c04 -np 2 $distributed_mapdl -dis -i input.dat -o solve.out
    EOF
    # run mapdl
    mapdl -dis -mpifile mpifile_intelmpi
    #
    # FOR OPENMPI:
    #
    # create an OpenMPI compatible MPI file
    cat > mpifile_openmpi << EOF
    phineas-c01 slots=4
    phineas-c04 slots=2
    EOF
    # run mapdl
    mapdl -dis -mpi openmpi -mpifile mpifile_openmpi -i input.dat -o solve.out

.. _workbench_export_to_apdl:

Export model from Workbench to APDL
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To export a model (including geometry) from ANSYS Workbench to Mechanical APDL:

1. In ANSYS Workbench, navigate to the project in which the model you wish to
   export is located.
2. Right-click on the model in the Project Schematic and select "Export Model..."
3. In the "Export Model" dialog box, select "Mechanical APDL" as the file format
   and choose a location to save the exported file.
4. Click "OK" to complete the export process.

Submit a MAPDL batch job
^^^^^^^^^^^^^^^^^^^^^^^^

1. Generate an appropriate Mechanical APDL input file. If you are using workbench,
   check Section :ref:`workbench_export_to_apdl` or Ansys Workbench Manual for more
   information on how to export your model to Mechanical APDL.
2. Copy sources (MAPDL input files) to the cluster staging area 
   (somewhere within your home directory).
3. Create a batch script that runs ``mapdl``.
4. Submit the batch script using the ``sbatch`` command.

Batch script
^^^^^^^^^^^^

.. literalinclude:: scripts/ansys_sbatch.sh
  :language: bash
