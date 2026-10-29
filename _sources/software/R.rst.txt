.. _R:

R
###

Using R
=======

There are three ways to use R in the cluster:

#. Using a Conda environment (see our :ref:`Conda documentation<conda>` for more information). The conda package for R is called
   ``r-base`` and you specify a version of R like this: ``r-base=<version>``. For example, the command below creates a conda
   environment named ``R_44`` that uses R version ``4.4``. 

   .. code-block:: bash

      module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
      conda create -n R_44 r-base=4.4

#. Using an ``Apptainer`` container with R pre-installed. The
   `Rocker Project <https://rocker-project.org/>`_ has many of these, including images with packages that
   are generally difficult to install (e.g. the geospatial toolkit for R, or Rstudio).

   .. code-block:: bash

      # load the apptainer module in LARCC
      module load apptainer/1.3.4-gcc-11.5.0-as2nnsb
      # Download the container image and store it as
      # file geo.sif
      apptainer pull geo.sif docker://rocker/geospatial:latest

#. Using a cluster provided module. This is generally discouraged unless the performace gain from doing so
   is strictly necessary. Researchers generally require multiple versions of R and maintaining an optimized
   stack of packages for each version is not scalable.

If a version of R you require is not available as a module, you should use Conda (or an Apptainer container)
to create a custom environment with the precise version you need:

#. Load the Miniforge module: ``module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym``.
#. Create an environment for R: ``conda create --name R_env``.
   See :ref:`this <conda_create_env>` section of our Conda documentation for more information on
   creating environments.
#. Activate newly created environment: ``conda activate R_env``.
#. Install ``r-base`` and ``r-essentials``: ``conda install r-base r-essentials``.
   See :ref:`this <conda_install_pkgs>` section of our Conda documentation for more information on specifying
   a particular version or R you want installed.
#. You can then launch R!

If you are using a module, then you can start using R right after loading the module.

Installing R Packages
=====================

When using R within a Conda environment, we recommend installing packages through Conda itself when posible.
**Many CRAN packages are available through Conda**, often with an ``r-`` prefix. e.g., ``r-dplyr``.

If a package is not available through conda, we recommend using the ``pak`` package manager within R 
(See Section :ref:`Using the pak Package Manager <r_pak_manager>` for more information), but
you are also welcome to use the default ``install.package()``, ``devtools``, etc.

Keep in mind that if you are using a system-built version of R though a modulefile,
you need to provide a custom installation location.
See Section :ref:`Installing R packages in custom locations <r_custom_install_location>` for more
information.

.. _r_custom_install_location:

Installing R packages in custom locations
=========================================

**If you are using an R module as opposed to Conda**,
R packages are stored by default in system directories that users cannot write to.
As a result, commands like:

.. code-block:: R

    install.packages("readr")
    install.packages(c("readr", "ggplot2", "tidyr"))

will fail with a "permission denied" error.

To install packages successfully, you should specify a custom library path—typically within your home directory:

1. Create a directory for your R packages (adjust the version as needed):

   .. code-block:: bash

       mkdir -p /home/user/R_lib/4.4.1

2. Launch R and install packages to that directory:

   .. code-block:: R

       install.packages(c("readr", "ggplot2", "tidyr"), lib="/home/user/R_lib/4.4.1")
       library("readr", lib.loc="/home/user/R_lib/4.4.1")

You can also specify a custom location when invoking ``install.packages`` within a conda-installed R,
but this is generally not necessary as R packages are installed to
``/home/<user>/.conda/envs/<env>/lib/R/library`` (where ``<user>`` is your username
and ``<env>`` is the name of the Conda environment), which avoids collisions between packages installed
on different environments.

Installing R Packages with External Library Dependencies
=========================================================

Some R packages rely on external libraries that may not be located in standard system paths. When installing such packages manually,
you must explicitly inform R of the location of these libraries.

Example: Installing the ``units`` Package
-----------------------------------------

The ``units`` package depends on the external library ``libudunits2``. Suppose the environment variable ``UDUNITS_ROOT`` contains
the path to the directory where ``libudunits2`` was built. You can install the package in R using:

.. code-block:: r

   # Install the units package
   udunits2_root <- Sys.getenv("UDUNITS_ROOT")
   udunits2_lib <- paste(udunits2_root, "/lib", sep = "")
   udunits2_inc <- paste(udunits2_root, "/include", sep = "")
   units_config <- paste("--with-udunits2-lib=", udunits2_lib,
                         " --with-udunits2-include=", udunits2_inc, sep = "")
   install.packages("units", configure.args = units_config)

Here, you're explicitly specifying the paths to the ``lib`` and ``include`` directories using
the ``--with-udunits2-lib`` and ``--with-udunits2-include`` options. Note that different packages may require different configuration flags,
so you'll need to consult their documentation or source code to determine the correct options.

Example: Installing the ``sf`` Package
--------------------------------------

The ``sf`` package depends on several components, including the ``units`` R package, and the external libraries ``proj`` and ``sqlite3``.
Assuming the environment variables ``PROJ_ROOT`` and ``SQLITE_ROOT`` point to the respective installation directories, you can install ``sf`` as follows:

.. code-block:: r

   # Install the sf package
   proj_root <- Sys.getenv("PROJ_ROOT")
   proj_lib <- paste(proj_root, "/lib", sep = "")
   proj_inc <- paste(proj_root, "/include", sep = "")
   sqlite_root <- Sys.getenv("SQLITE_ROOT")
   sqlite_lib <- paste(sqlite_root, "/lib", sep = "")
   sf_config <- paste("--with-proj-include=", proj_inc,
                      " --with-proj-lib=", proj_lib,
                      " --with-proj-api=no",
                      " --with-sqlite3-lib=", sqlite_lib, sep = "")
   install.packages("sf", configure.args = sf_config)

As you can see, manually managing external dependencies can be tedious and does not scale well—essentially replicating the work of a package manager.

Simplifying with Conda
----------------------

Many of these challenges can be avoided by using Conda, which automatically installs and configures external libraries for supported R packages.
While Conda doesn't cover every CRAN package, it supports a substantial subset.

For example, you can install both ``units`` and ``sf`` with a single command:

.. code-block:: bash

   conda install r-units r-sf

This will also install ``libudunits2``, ``proj``, ``sqlite3``, and other required dependencies within your Conda environment, streamlining the setup process.

.. _r_pak_manager:

Using the ``pak`` Package Manager
=================================

While ``install.packages()`` works for CRAN, many workflows require packages from Bioconductor, GitHub, or custom sources.
Tools like ``remotes``, ``devtools``, and ``BiocManager`` help, but managing dependencies across them can be complex.

We recommend using ``pak``, a unified package manager that supports CRAN, Bioconductor, GitHub, URLs, git repositories, and local files.
It simplifies installation and improves dependency handling.

Example usage:

.. code-block:: R

    # Install pak to your custom library
    install.packages("pak", lib="/home/user/R_lib/4.4.1")
    library("pak", lib.loc="/home/user/R_lib/4.4.1")

    # Install from CRAN or Bioconductor
    pak::pkg_install("ggplot2", lib="/home/user/R_lib/4.4.1")

    # Install from GitHub
    pak::pkg_install("tidyverse/tibble", lib="/home/user/R_lib/4.4.1")
