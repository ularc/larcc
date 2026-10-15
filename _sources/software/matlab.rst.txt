.. _matlab:

MATLAB
######

Basics
======

Workers and pools
^^^^^^^^^^^^^^^^^

In MATLAB's terminology, a *worker* is a CPU-core and a *pool* is a
set of workers (i.e. a group of CPU-cores in a machine).  By default, a parallel pool starts
automatically when needed by parallel language features such as ``parfor`` (parallel for-loop),
``parfeval`` (paralle function evaluation), ``mapreduce``, among others.

Users are strongly encouraged to read the `"Run Code on Parallel Pools" section <https://www.mathworks.com/help/parallel-computing/run-code-on-parallel-pools.html>`_
of MathWorks documentation before attempting to parallelize their code.

Parallel and distributed execution
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When reserving a pool of workers for execution, MATLAB handles communication between workers automatically. This
also includes workers running on different machines. Thus, parallel and distributed execution look the same 
from an user's point of view.

.. _matlab-profiles:

Cluster profiles
^^^^^^^^^^^^^^^^
As per MathWorks' documentation, cluster profiles let users define certain properties for a cluster,
then have these properties applied when they create cluster, job, and
task objects in the MATLAB client. For instance, the code below shows an example where
an user creates a cluster profile from MATLAB's command-line. Option ``JobStorageLocation``
specifies the path at the user's workstation (i.e. their local machine) where information about
a job submitted to a cluster is to be stored. Option ``NumWorkers`` represents the number of
workers allowed by the MATLAB license in the cluster (i.e. the remote machine). Option
``ClusterMatlabRoot`` specifies the full path to the MATLAB install folder on the cluster. Option
``OperatingSystem`` specifies the category of the cluster's operating system. Option ``HasSharedFilesystem``
indicates whether or not there is a disk location accessible to the user's workstation
and the workers on the cluster. Option ``PluginScriptsLocation`` specifies the
full path to the plugin script folder that contains the
`matlab-parallel-slurm-plugin <https://github.com/mathworks/matlab-parallel-slurm-plugin#readme>`_ or other
scheduler related plugin.

.. code-block:: matlabsession

    >> cluster = parallel.cluster.Generic( ...
    >> 'JobStorageLocation', 'C:\MatlabJobs', ...
    >> 'NumWorkers', 20, ...
    >> 'ClusterMatlabRoot', '/usr/local/MATLAB/R2025a', ...
    >> 'OperatingSystem', 'unix', ...
    >> 'HasSharedFilesystem', false, ...
    >> 'PluginScriptsLocation', 'C:\MatlabSlurmPlugin\shared');

Some of the functions that support the use of cluster profiles are:
``batch``, ``parpool``, ``parcluster``. Uses of some of these functions alongside a cluster profile
for LARCC's login node are shown later in Sections :ref:`Submitting a batch job <matlab-batch-job>` and
and :ref:`Creating a cluster profile for LARCC <create-matlab-larcc-cluster-profile>` respectively.

Users are encouraged to read more about cluster profiles in the
`"Use Cluster Profiles" section <https://www.mathworks.com/help/parallel-computing/discover-clusters-and-use-cluster-profiles.html>`_
of MathWorks' documentation.

.. _matlab-batch-job:

Submitting a batch job
======================

There are three options to submit MATLAB batch jobs:

#. **Using a Batch Script:**
    MATLAB is invoked directly from the shell within the batch script, where the project's main `.m` source file is passed to the MATLAB executable. For a detailed walkthrough, refer to Section :ref:`Submit jobs through a batch script <matlab-batch-job-batch-script>`. This method is often the easiest, but **distributed execution is not available with this option**.

#. **Using MATLAB's Command Prompt:**
    Users initiate the `matlab` command from the head node. Within the MATLAB prompt, they load the relevant cluster profile and leverage the `batch` option, as detailed in Section :ref:`Submit jobs through MATLAB's command prompt <matlab-batch-job-matlab-prompt>`.

#. **Using a Batch Script and a MATLAB Submission Script:**
    This approach mixes elements from the preceding two methods. A job is scheduled using option 1, which, in turn, allocates a second job executing the main project's code in parallel. The process involves creating a batch script, akin to the first option. However, instead of passing the project's main `.m` source file to the MATLAB executable, an intermediate `.m` file, functioning as the MATLAB submission script, is passed. This intermediate file employs the same commands outlined in option 2 to schedule a new job that employs multiple workers.

.. note::
    Most users should default to launching matlab using method 1 (i.e. a simple batch script),
    as it is the easiest and supports parallel execution. Users whose workloads benefit from distributed
    execution should familiarize themselves with :ref:`Matlab Cluster Profiles <matlab-profiles>` first.

.. _matlab-batch-job-batch-script:

Submit jobs through a batch script
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Copy the Matlab project to the cluster. That is, all ``.m`` source code files that are to be passed to matlab for execution. For example, assume the file ``/home/user/test.m`` has the following content:

    .. code-block:: matlab

        p = parpool(str2num(getenv('SLURM_NTASKS')));
        t0 = tic;
        A = 500;
        a = zeros(1000);
        parfor i = 1:1000
        a(i) = max(abs(eig(rand(A))));
        end
        t = toc(t0)
        exit

#. Create a :ref:`batch script <batch_job>`. For example, assume the file ``/home/user/matlab_test.sh`` has the following content:

    .. code-block:: bash

        #!/bin/bash
        #SBATCH -J test_matlab
        #SBATCH -o /home/user/test_matlab-%j.out
        #SBATCH -e /home/user/tmp/test_matlab-%j.err
        #SBATCH -p longjobs
        #SBATCH -n 20
        #SBATCH -t 20:00

        module load matlab/r2025a
        matlab -nosplash -nodesktop < /home/user/test.m

#. Use the ``sbatch`` command to schedule the job. Following the example from previous steps:
   ``sbatch /home/user/matlab_test.sh``.

.. _matlab-batch-job-matlab-prompt:

Submit jobs through MATLAB's command prompt
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Copy the Matlab project to the cluster. That is, all ``.m`` source code files that are to be passed to matlab for execution. For example, assume the file ``/home/user/parallelExample.m`` has the following content:

    .. code-block:: matlab
    
        function t = parallelExample(n)
            t0 = tic;
            A = 500;
            a = zeros(n);
            parfor i = 1:n
                a(i) = max(abs(eig(rand(A))));
            end
            t = toc(t0);
        end

#. Execute MATLAB's prompt by loading the appropriate matlab module and running the command ``matlab -nodisplay -nosplash -nodesktop`` from the head node. For example,

    .. code-block:: bash

        user@larcc-login1:~$ module load matlab/r2023b
        user@larcc-login1:~$ matlab -nodisplay  -nosplash -nodesktop
        
                                                        < M A T L A B (R) >
                                              Copyright 1984-2024 The MathWorks, Inc.
                                         R2025a (25.1.0.2943329) 64-bit (glnxa64)
                                                          April 16, 2025


        To get started, type doc.
        For product information, visit www.mathworks.com.

        >>

#. Once in the prompt, load the cluster profile using the ``parcluster`` command, add additional slurm properties like the job's time limit and queue to submit the job to, and finally execute the job using the ``batch`` command from the object obtained from the ``parcluster`` command. For example:

    .. code-block:: matlabsession

        >> % The following line loads the larcc-local profile
        >> cluster = parcluster('larcc-local');
        >> % The following line sets the job's time limit
        >> cluster.AdditionalProperties.WallTime = '1:00:00';
        >> % The following line sets the queue to where the job will be submitted to
        >> cluster.AdditionalProperties.Partition = 'longjobs';
        >> % The following line submits the job. Here is a breakdown of the line:
        >> % - @parallelExample refers to the function in /home/user/parallelExample.m
        >> % - 1 is the number of outputs returned by the function
        >> % - {1000} are the arguments to be passed to the function
        >> % - 'Pool' indicates matlab to create a pool of workers for parallel
        >> %   (or distributed) execution
        >> % - 8 indicates the number of workers to use in the pool
        >> job = cluster.batch(@parallelExample, 1, {1000}, 'Pool', 8);

#. After the job has been submitted, users can wait for the job to finish and fetch any result not persisted to disk by executing in the prompt ``job.fetchOutputs{:};``.

Submit jobs through a batch script and a MATLAB submission script
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Copy the Matlab project to the cluster. That is, all ``.m`` source code files that are to be passed to matlab for execution. For example, assume the file ``/home/user/parallelExample.m`` has the following content:

    .. code-block:: matlab
    
        function t = parallelExample(n)
            t0 = tic;
            A = 500;
            a = zeros(n);
            parfor i = 1:n
                a(i) = max(abs(eig(rand(A))));
            end
            t = toc(t0);
            fileToSaveResultTo = "result.txt";
            save(fileToSaveResultTo)
        end

#. Create a MATLAB submission script that invokes project's code. For example, assume the file ``/home/user/matlabSubmissionScript.m`` has the following content:

    .. code-block:: matlab

        % Get the number of workers from the slurm scheduler. The SLURM_NTASKS
        % environmental variable is set automatically by slurm.
        workers = str2num(getenv('SLURM_NTASKS'));
        % Load the larcc-local cluster profile
        cluster = parcluster('larcc-local');
        % Set the job's time limit
        cluster.AdditionalProperties.TimeLimit = '1:00:00';
        % Set the queue to where the job will be submitted to
        cluster.AdditionalProperties.Partition = 'longjobs';
        % Submit the job. Here is a breakdown of the line:
        % - @parallelExample refers to the function in /home/user/parallelExample.m
        % - 1 is the number of outputs returned by the function
        % - {1000} are the arguments to be passed to the function
        % - 'Pool' indicates matlab to create a pool of workers for parallel
        %   (or distributed) execution
        % - 8 indicates the number of workers to use in the pool
        job = cluster.batch(@parallelExample, 1, {1000}, 'pool', workers);

#. Create a sbatch script that invokes the matlab submission script from the previous step.  For example, assume the file ``/home/user/matlab_test.sh`` has the following content:

    .. code-block:: bash

        #!/bin/bash

        #SBATCH -J test_matlab
        #SBATCH -o /home/user/test_matlab-%j.out
        #SBATCH -e /home/user/tmp/test_matlab-%j.err
        #SBATCH -p longjobs
        #SBATCH -n 20
        #SBATCH -t 20:00

        module load matlab/r2025a
        matlab -nodisplay -nosplash -nodesktop -r "matlabSubmissionScript"

#. Use the ``sbatch`` command to schedule the job. Following the example from previous steps: ``sbatch /home/user/matlab_test.sh``

.. _create-matlab-larcc-cluster-profile:

Creating a cluster profile for LARCC
==============================================

The login node acts as a Matlab client in this case. This means that instead of creating a cluster profile
in their personal or university workstation, an user creates a cluster profile in the login node. The steps are as follows:

#. Log into the cluster.
#. Load the matlab module you would like to use. For example, ``module load matlab/r2025a-gcc-11.5.0-cj4bjqf``.
#. Create a cluster profile by running the command below. Make sure to modify the value of variables:
   ``profileName``, ``numWorkers``, and ``jobStorageLocation`` as you see fit.
    
    .. code-block:: bash

        (
        cat << EOF
        profileName = 'larcc-cluster';
        numWorkers = 60;
        jobStorageLocation = '~/.matlab/local_cluster_jobs/r2025a';
        profiles = parallel.listProfiles;
        if ~any(strcmp(profileName, profiles))
            c = parallel.cluster.Generic( ...
                  'JobStorageLocation', jobStorageLocation, ...
                  'NumWorkers', numWorkers, ...
                  'ClusterMatlabRoot', '/opt/shared/apps/manual/matlab/r2025a', ...
                  'OperatingSystem', 'unix', ...
                  'HasSharedFilesystem', true, ...
                  'PluginScriptsLocation', '/opt/shared/apps/manual/matlab/r2025a/toolbox/matlab-parallel-slurm-plugin-2.3.0');
            saveAsProfile(c, profileName);
        end
        EOF
        ) | matlab -nodisplay -nosplash -nodesktop

#. Validate that the cluster profile was saved. To do this,
   execute matlab again as follows: ``matlab -nodisplay -nosplash -nodesktop -batch "disp(parallel.listProfiles)"``.
   The output list should include a cluster profile with the name set in the ``profileName`` variable.
