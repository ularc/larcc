HPC System Guide
################

Introduction
============

High-Performance Computing (HPC) clusters are powerful systems used for running large-scale scientific and engineering tasks.
Most HPC clusters run on **Linux**, and you'll interact with them mainly through the **command line**.
This guide will help you get started with the basics:
how to move around the system, use software modules, and run jobs.

Before we dive in, let's go over a few important terms.

What is a Shell?
----------------

A **shell** is a program that lets you talk to the operating system by typing commands.
You use a shell through a **terminal** (a command-line interface) or a **graphical user interface (GUI)**.

Examples:

- On **Windows**, the GUI is called **File Explorer** (``explorer.exe``), and the terminals are **Command Prompt** (``cmd.exe``) and **PowerShell**.
- On **macOS**, the GUI is **Finder**, and the terminal is called **Terminal**.
- On **Linux**, you usually use a terminal with a shell like **bash**.

Most HPC systems use **bash** as the default shell, and that's what you'll be using when you log in.

What is case-sensitivity?
-------------------------

A case-sensitive system is one that distinguishes between uppercase and lowercase letters in text.
If you are a Windows user you may have noticed that a letter is treated the same whether it is lower-case or upper-case.
For example: "hello", "HeLlo", and "HELLO" are all the same. Thus, Windows is NOT a case-sensitive system.

On the other hand, macOS and Linux systems **ARE** case-sensitive. This is an important distinction because when you
navigate through folders, create files, etc.,  in our systems you **MUST ALWAYS USE** the right cases.


Connecting to the Cluster
=========================
To use the cluster, you'll connect to it from your own computer using a tool called **SSH** (Secure Shell).
SSH lets you open a remote session on the cluster so you can run commands as if you were sitting in front of it.

SSH is available by default on:

- **Windows PowerShell** (use ``ssh`` or ``ssh.exe``)
- **macOS Terminal**
- **Linux Terminal**

> ⚠️ If you're on Windows, use **PowerShell**, not Command Prompt.

To connect, use this command:

.. code-block:: bash

   ssh your_username@cluster_name.hpc.louisville.edu

Replace:

- ``your_username`` with your actual HPC username.
- ``cluster_name`` with the name of the cluster (e.g., ``larcc``).

Example:

.. code-block:: bash

   ssh jd01@larcc.hpc.louisville.edu

Once connected, you'll see a prompt like this:

.. code-block:: text

   [jd01@larcc-login1 ~]$

Here's what it means:

- ``jd01`` - Your username.
- ``larcc-login1`` - The login node you're connected to.
- ``~`` - Your home directory (similar to ``C:\Users\yourname`` on Windows).

We'll explain more about the Linux file system in the next section.

.. _understanding_filesystem:

Understanding Filesystems
=========================

What is a Filesystem?
---------------------

A **filesystem** is the method an operating system uses to organize and store data on storage devices
such as hard drives or SSDs. It defines how files and directories are named, stored, accessed, and structured.
Most modern operating systems use a **hierarchical filesystem**, where files are organized in a tree-like
structure starting from a root directory.

.. _filesystem_hierarchies:

Filesystem Hierarchies
-----------------------

All major operating systems—Linux, Windows, and macOS—use hierarchical filesystems,
but they differ in how the root and subdirectories are structured.

.. image:: images/filesystem_hierarchies.png
  :width: 600
  :alt: Filesystem hierarchies

Linux and macOS
~~~~~~~~~~~~~~~

- Both Linux and macOS have a **single root directory**, represented by the forward slash: ``/``.
- All other directories branch off from this root.
- Common directories under ``/`` include:

  - ``/usr`` - Contains installed applications and system utilities.
  - ``/home`` - User directories; similar to ``C:\Users`` in Windows.
  - ``/boot`` - Boot loader files.
  - ``/dev`` - Device files (e.g., drives, network interfaces).
  - ``/etc`` - System configuration files.
  - ``/lib`` - Shared system libraries.

Windows
~~~~~~~

- Windows uses **multiple root directories**, each represented by a drive letter (e.g., ``C:``, ``D:``).
- Each drive has its own independent hierarchy.
- The primary system drive (usually ``C:``) contains:

  - ``C:\Windows`` - Most system files and configurations.
  - ``C:\Program Files`` and ``C:\Program Files (x86)`` - Installed applications.
  - ``C:\Users`` - User directories, analogous to Linux's ``/home``.

Navigating the filesystem
-------------------------

Filesystem locations (aka. paths)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You indentify a location in the filesystem through a **path**, which has 3 elements:
A root, a separator, and a folder or file name.

- Windows:

   - **rule to make a path:** root + separator + folder name + separator + ... + separator + (final) folder or file
   - **root:** A letter followed by ``:``, such as ``C:``, or ``D:``.
   - **separator:** The character ``\``.
   - **example of a path:** ``C:\Windows\System32``

- Linux and macOS:
   - **rule to make a path:** root + folder name + separator + ... + separator + (final) folder or file
   - **root:** The character ``/``.
   - **separator:** The character ``/`` (YES, it's the same as the root. Simply put, the first ``/`` in the path is always the root).
   - **example of a path:** ``/home/jd01``.

   .. image:: images/filesystem_path.png
      :width: 600
      :alt: Filesystem hPath

Our HPC systems use a **Linux-based hierarchical filesystem**, where everything starts from the root directory ``/``
(if this statement confuses you, please read section :ref:`Filesystem Hierarchies <filesystem_hierarchies>`).

Key directories you'll interact with:

- ``/home/<username>`` - Your personal persistent space for scripts, logs, files, etc.
- ``/mnt/scratch/local/<username>`` - Temporary storage for files and job outputs. Only available in compute nodes
  and automatically purged after a set period. This is explained in more detail in section :ref:`Understanding Storage on Compute Nodes <storage-on-compute-nodes>`,
  but we recommend you finish reading this guide before jumping there.
- ``/mnt/lab/<project>`` - Persistent shared space for project teams.

The working directory
~~~~~~~~~~~~~~~~~~~~~

One important concept to understand when using the shell (in our case, ``bash``) to navigate the filesystem is the idea of the **working directory**.
The **working directory** is the folder where the shell assumes you want to work.
Any command you run that creates, deletes, or modifies files will do so in this location—unless you tell it to use a different path.

When you log into one of our HPC systems, you automatically "land" in your **home directory**: ``/home/your_username``.
At that moment, your **working directory** is your home directory. You can confirm this by executing the ``pwd`` command.
This will print the **path** to your current working directory.

**Why does it matter?** Let's say you run the following command:

.. code-block:: bash

   touch notes.txt

This creates a file called ``notes.txt`` in your current working directory. If you're in ``/home/your_username``, the file will be created there.
Now, if you change to another directory:

.. code-block:: bash

   cd /tmp

And run the same command:

.. code-block:: bash

   touch notes.txt

The file will now be created in ``/tmp``, because that's your new working directory.

Managing files and directories
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can move between directories using the ``cd`` command:

- ``cd /path/to/directory`` - Change directory. Here is an example:

   .. image:: images/cmd_cd.png
      :width: 600
      :alt: Example of cd command

- ``cd ..`` - Go up one directory from your working directory. Here is an example:

   .. image:: images/cmd_cd_back_one.png
      :width: 600
      :alt: Example of cd command going back

- ``cd`` - Go back to your home directory at any point.

You can also list files in the current working directory using: ``ls``, or ``ls -a`` to also include hidden files.
Other useful commands include:

- ``pwd`` - Print current working directory.
- ``mkdir /path/to/new/directory`` - Make a new directory
- ``du -sh /path/to/directory`` - Show disk usage of a directory.
- ``find /path/to/directory -name filename`` - Search for files within a directory.
- ``cp /path/to/source /path/to/destination`` - Copy files.
- ``mv /path/to/source /path/to/destination`` - Move or rename files.
- ``rm /path/to/file`` - Delete files.
- ``tar -czf archive.tar.gz /path/to/some/file /path/to/some/other/file`` - Compress files into ``archive.tar.gz``.

Using Modules
-------------

HPC environments use **environment modules** to manage software versions.

Basic commands:

- ``module avail`` - List available modules.
- ``module load <module-name>`` - Load a module.
- ``module list`` - Show currently loaded modules.
- ``module unload <module-name>`` - Unload a module.
- ``module purge`` - Unload all modules.

Example:

.. code-block:: bash

   module load gcc/11.2.0
   module load python/3.10.4

**Note:** Always load required modules in your job scripts to ensure consistency.
