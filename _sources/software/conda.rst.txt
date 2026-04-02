.. _conda:

Conda (Anaconda/Miniconda/Miniforge)
####################################

Basics
======

About Anaconda, Miniconda and Miniforge
---------------------------------------

The Conda installer is a package manager and environment manager for
Python, R, and other languages. It comes in 3 flavors:

- **Anaconda:** The Anaconda (company) driven Conda installer with hundreds of scientific packages included.
- **Miniconda:** The Anaconda (company) driven minimalistic Conda installer including only Python by default.
- **Miniforge:** The community (conda-forge) driven minimalistic Conda installer
  using the ``conda-forge`` channel by default.

LARCC only offers support for **Miniforge** as it works just like Anaconda
or Miniconda but is lightweight and specifically built to support
open-source and customizable environments. Compared to the other 2, it:

- is smaller than Anaconda (no preinstalled packages).
- does not rely on the default Anaconda channel, which can sometimes have licensing issues.
- uses conda-forge as its default channel—a large, community-maintained repository of conda packages.

What is a Conda environment?
----------------------------

A Conda environment is a self-contained directory that includes:

- A specific version of Python or R
- Specific versions of packages (like NumPy, TensorFlow, etc.)
- Any other dependencies

Each environment is isolated from others, which means packages in one environment
don't interfere with packages in another.


Why use multiple Conda environments?
------------------------------------

- **Avoid Conflicts Between Packages**. Different projects may need different package
  versions. Maintaining 1 or multiple environments per project can help in
  prototyping and or maintining different versions of your code. For example,
  Assume "Project A" requires TensorFlow 2.15 and "Project B" requires TensorFlow 1.14. 
  If you installed both in the same environment, they would conflict. With Conda, you can do:

   .. code-block:: bash

    conda create --name ProjectA python=3.10 tensorflow=2.15
    conda create --name ProjectB python=3.7 tensorflow=1.14

- **Safe code prototyping and experimenting with new package versions**. If you want to make sure
  your code works on the latest version of a package or you want to try a new exciting feature
  of the latest version of a package, you can create a new environment before updating.

- **Reproducibility**. Environments can be exported and shared 
  to others with ``conda env export > environment.yml`` and later imported by another party
  (or another machine) with ``conda env create -f environment.yml``. For example,
  you could build an environment
  in your local workstation, then export it and rebuild it on the login node of the cluster.

Using Conda
===========

Loading the miniforge3 module and the base environment
------------------------------------------------------

After logging into LARCC, you can start using Miniforge by loading the miniforge3 module with the command:

.. code-block:: bash

    module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym 

After executing this command, you should see your prompt change (it should now start with ``(base)``).

.. _conda_create_env:

Creating and activating an environment
--------------------------------------

Although you can install packages right after loading the miniforge3 module, which
activates the base Miniforge environment for you, it is best to create and use named environments instead.
These are isolated, easier to manage, and allow multiple setups under one base environment.

Miniforge supports both ``conda`` and ``mamba`` for managing environments.
While both work the same way, ``mamba``—written in C++—is faster and more memory-efficient than ``conda``.
We recommend using ``mamba`` for installing packages. However, if you have not run ``mamba init``,
you will need to use ``conda`` to activate or deactivate environments.
For non-installation tasks like listing environments, both tools can be used interchangeably.

For example, to create an environment named ``my_env``:

#. Load the miniforge3 module by typing: ``module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym``.
#. Create the environment with ``mamba create --name my_env`` or ``conda create --name my_env``.

Once you have created your environment, you can use it by executing ``conda activate environment_name_here``.
For example, ``conda activate my_env``. The command prompt will then change from ``(base)`` to ``(my_env)``
to reflect this.

By default, your environments are stored at ``/home/user/.conda/envs/env_name``.
If you want to indicate a different prefix, you can use the ``--prefix`` option instead of the
``--name`` option. For example:

.. code-block:: bash

    conda create --prefix /home/user/ProjectA/my_env

.. _conda_install_pkgs:

Installing packages with conda and mamba
----------------------------------------

Once you have activated an environment, you can install packages with the ``mamba install`` command or the
``conda install`` command. You can also control what version of a package you want installed based on
the following constraints:

.. list-table:: Conda installation constraint types
   :widths: 30 35 35
   :header-rows: 1

   * - Constraint type
     - Syntax
     - Result
   * - Fuzzy
     - ``python=3.11``
     - 3.11.0, 3.11.1, 3.11.2, etc.
   * - Exact
     - ``python==3.11``
     - 3.11.0
   * - Greater than or equal to
     - ``"python>=3.11"``
     - 3.11 or higher
   * - OR
     - ``"python=3.11.1|3.11.3"``
     - 3.11.1, 3.11.3
   * - AND
     - ``"python>=3.11,<3.13"``
     - 3.11, 3.12, not 3.13

For example,

.. code-block:: bash

    mamba install python=3.11 # or conda install python=3.11
    # NOTE: the quotation marks are necessary 
    # to protect the < and > symbols from the shell.
    mamba install "python>=3.11.1" # or conda install "python>=3.11.1"

Installing packages with pip
----------------------------

.. warning::
    If pip is not installed in your environment, either:
    
    - The shell won't find ``pip``, or  
    - It will use a system-wide version, potentially failing due to lack of permissions to
      install packages system-wide.

    Always check that pip is installed in the environment you activated with
    ``conda list -n env_name pip``. The output should look similar to this:

    .. code-block:: text

        # packages in environment at /home/user/.conda/envs/env_name:
        #
        # Name                    Version                   Build  Channel
        pip                       25.1.1             pyh145f28c_0    conda-forge

We recommend using pip within an environment only if the package you need to install is
not already available in ``conda-forge`` or another (open-source) conda channel. For example,
newer versions of PyTorch are no longer installable via conda and thus must be installed via pip:

.. code-block:: bash

    pip3 install torch torchvision torchaudio


.. _conda_clone_env:

Cloning an environment
----------------------

Sometimes you may want to create a new conda environment based on an existing one. To do this:

#. Activate the environment you want to clone.
#. Export its package list to a YAML file with.
   ``mamba env export > environment.yml`` or ``conda env export > environment.yml``
#. Deactivate the environment.
#. Create the new environment with ``mamba env create --name new_env -f environment.yml``
   or ``conda env create --name new_env -f environment.yml``.

Miscellaneous
-------------

Here are some useful conda commands users are encouraged to get familiar with:

.. list-table:: Some useful Conda commands
   :widths: 40 50
   :header-rows: 1

   * - Command
     - Meaning
   * - ``conda create --name my_env PCKAGE1 PACKAGE2``
     - Create a new environment named ``my_env``, install packages ``PCKAGE1`` and ``PACKAGE2``
   * - ``conda activate my_env``
     - Activate environment ``my_env`` to use packages installed in it
   * - ``conda deactivate``
     - Deactivate a currently activated environment. You can only have one environment activated
       at once, so there is not need to name the environment you want to deactivate.
   * - ``conda env list``
     - Get a list of all available environments. Active environment is shown with *
   * - ``conda env remove --name my_env``
     - Remove environment ``my_env`` and everything in it
   * - ``conda install PACKAGE``
     - Install a package. You can also specify the version of the package by using
       the syntax ``PACKAGE=version``. For example, ``conda install python=3.15``. 
   * - ``conda update PACKAGE``
     - Update a package
   * - ``conda search PACKAGE``
     - Search for package
   * - ``conda config --add channels CHANNEL``
     - Add a channel to your environment. This is especially helpful for those using bioconda 
       (``conda config --add channels bioconda``)

As an example, a typical workflow for python looks like this:

.. code-block:: bash

    module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
    # Create a custom environment. In this case, create
    # an environment named "my_env" and install packages
    # numpy and scipy
    conda create --name my_env python=3.11 numpy scipy
    # Activate the environment "my_env"
    conda activate my_env
    # Suppose you realized you need the pandas package.
    # So, install it!
    conda install pandas

Conda in a batch job
==========================

After creating a virtual environment, you can use it within a batch script. Any program
you install within an environment will become available after said environment is
activated. That means to effectively use a software installed via Conda in a batch job
you need to load the ``miniforge3`` module and then instruct the script to activate the
desired environment.

For example, suppose you created an environment named ``projectA_pytorch``, then you
could use it as follows:

.. code-block:: bash

  #!/bin/bash

  #SBATCH --job-name=projectA_pytorch_job
  #SBATCH --partition=compute
  #SBATCH --output=/home/user/slurm-%x-%j.out 
  #SBATCH --time=1:00:00
  #SBATCH --nodes=1
  #SBATCH --mem=515002

  module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym 
  conda activate projectA_pytorch

  ## Execute the python script that calls pytorch
  python program.py

To see a more concrete example, see our documentation on
how to :ref:`launch jupyter through a batch job <jupyter_batch>`.

Conda in an interactive job
=================================

After creating a virtual environment, you can use it within an interactive job. Any program
you install within an environment will become available after said environment is
activated. That means to effectively use a software installed via Conda
you need to load the ``miniforge3`` module, activate the desired environment and run your program.

For example, suppose you created an environment named ``projectA_pytorch``, then you
could use it as follows:

.. code-block:: bash

  srun --partition=compute --job-name=projectA_pytorch_job --time=1:00:00 --nodes=1 --mem=515002 --pty /bin/bash -i
  module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym 
  conda activate projectA_pytorch

  ## Execute the python script that calls pytorch
  python program.py

To see a more concrete example, see our documentation on
how to :ref:`launch jupyter through an interactive job <jupyter_interactive>`.