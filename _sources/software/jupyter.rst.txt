.. _jupyter:

Jupyter
#######

.. warning::
    Users are encouraged to use Jupyter primarily for testing or prototyping code, 
    rather than for running large, resource-intensive workloads.
    By default, Jupyter imposes limits on cache, memory, and other settings,
    which can slow down execution or cause failures.

    While these settings can be adjusted at launch, it's often simpler
    and more efficient to run Python scripts directly using the Python interpreter,
    especially for heavier tasks.

There are multiple ways to launch jupyer in the cluster. At the moment, all of them require users
to have basic familiarity with conda environments or, alternatively, the
python ``venv`` module (See `Python's venv documentation <https://docs.python.org/3/library/venv.html>`_).

.. _jupyter_batch:

Launching Jupyter through a batch job
=====================================

For the convenience of users, the cluster already comes with
pre-defined conda environments where
jupyter is installed: ``pytorch``, ``tensorflow``.
Users can use  any of these environments or create their own.

1. (Optional) Create a jupyter environment
------------------------------------------

Login into the cluster and create a jupyter environment, plus any
additional packages you need as follows:

.. tabs::

    .. group-tab:: conda
    
        .. code-block:: bash

            module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
            conda create -n jupyter_env python numpy pandas notebook
    
    .. group-tab:: venv

        .. code-block:: bash

            python -m venv jupyter_env
            source jupyter_env/bin/activate
            pip3 install jupyter numpy pandas notebook

2. Create the submission script
-------------------------------

Login to the cluster and create the following sbatch script:

.. tabs::

    .. group-tab:: conda

        .. literalinclude:: scripts/jupyter_conda.sbatch
         :language: bash
         :linenos:

    .. group-tab:: venv

        .. literalinclude:: scripts/jupyter_venv.sbatch
         :language: bash
         :linenos:

3. Connect to jupyter from your web browser
-------------------------------------------

The script will print to the standard error file 
(the one indicated in the ``#SBATCH --error`` option in the sbatch file)
the instructions on how to connect to the jupyer web instance. Example output:

.. code-block:: text

    1. SSH tunnel from your workstation using the following command:

        ssh -N -L 10178:larcc-hs-gpu1:10178 user@larcc.hpc.louisville.edu

        and point your web browser to http://localhost:10178

    2. log in to Jupyter using the following password: Oc/ieDDJ0yulxiRP96Wt

       When done using Jupyter, terminate the job by issuing the following command on the login node:

        scancel -f 177
    
.. note::
    ``10178`` is a randomly picked port and 
    the password ``Oc/ieDDJ0yulxiRP96Wt`` is randomly generated. This means users will be
    provided a new port and password upon a new job submission.

.. _jupyter_interactive:

Launching Jupyter through an interactive job
============================================

For the convenience of users, the cluster already comes with
pre-defined python virtual environments where
jupyter is installed: ``pytorch``, ``tensorflow``.
Users can use  any of these environments or create their own.

1. (Optional) Create a jupyter environment
------------------------------------------

Login into the cluster and create a jupyter environment, plus any
additional packages you need as follows:

    .. code-block:: bash

        module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
        conda create -n jupyter python numpy pandas notebook

2. Submit an interactive job
----------------------------

Here is an example, but users should change the parameters as they see fit

    .. code-block:: bash

        srun --partition=gpu --job-name jupyter --time=5:00:00 --nodes=1 --pty /bin/bash -i
    
3. Manually launch Jupyter
--------------------------

When you land on the assigned compute node, take note of the hostname of the server assigned 
to your job as you will need it for the following steps 
(you can use the ``hostname | sed 's/larcc-/larcc-hs-/'`` command).
Then, start a jupyter server as follows:

.. code-block:: bash

    module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
    # CHANGE THIS TO THE CONDA ENVIRONMENT YOU SEE FIT
    conda activate jupyter
    PORT=`comm -23 <(seq 1024 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1`
    PASS=`openssl rand -base64 15`
    HASHED_PASS=`python -c "from jupyter_server.auth import passwd; print(passwd('$PASS'))"`
    echo "THIS IS YOUR PASSWORD: ${PASS}"
    echo "THIS IS THE PORT JUPYTER IS RUNNING ON: ${PORT}"
    jupyter notebook --no-browser --port=$PORT \
        --ServerApp.ip=0.0.0.0 \
        --PasswordIdentityProvider.hashed_password="$HASHED_PASS"

4. Access Jupyter from your workstation
---------------------------------------

.. code-block:: bash
    
    ssh -N -L ${PORT}:${HOSTNAME}:${PORT} ${SLURM_JOB_USER}@larcc.hpc.louisville.edu

For example, assume you landed on the server ``larcc-gpu1`` on step 2 and jupyter is using port 7070,
then you would run: ``ssh -N -L 7070:larcc-hs-gpu1:7070 username@larcc.hpc.louisville.edu``.

Access jupyter through **your (personal) workstation's web browser** by entering in the navigation bar:
``localhost:<port>``. Following the example from step 4, you would use ``localhost:7070``. Then, enter
the password printed in step 3.


Transitioning from Jupyter to Python Script
===========================================

Jupyter Notebooks are great for interactive development and prototyping, but for production or large-scale execution, Python scripts are often more efficient and maintainable. This guide outlines the steps to convert your notebook into a Python script.

1. Export the Notebook
-----------------------

In Jupyter:

- Go to the top menu: ``File > Download as > Python (.py)``
- This will generate a ``.py`` file with all your code and markdown cells converted to comments.

2. Clean Up the Script
-----------------------

- Open the exported ``.py`` file in a text editor or IDE.
- Remove or convert markdown comments (lines starting with ``#``) as needed.
- Delete any unused cells or outputs.
- Consolidate code into functions or a main block for better structure:

  .. code-block:: python

     def main():
         # your code here

     if __name__ == "__main__":
         main()

3. Replace Notebook-Specific Features
--------------------------------------

- Remove magic commands like ``%matplotlib inline``.
- Replace interactive display functions with standard Python equivalents.
- **Save plots and images to disk** using ``plt.savefig("filename.png")`` instead of displaying them with ``plt.show()``.

4. Handle File Paths and Inputs
-------------------------------

- Use relative or absolute paths for reading/writing files.
- Consider using ``argparse`` to handle command-line arguments for flexibility.

5. Test the Script
-------------------

- Run the script from the terminal:

  .. code-block:: bash

     python your_script.py

- Check for errors and ensure outputs match expectations.

By following these steps, you can turn your interactive notebook into a
reusable Python script suitable for larger workflows or automated execution.
