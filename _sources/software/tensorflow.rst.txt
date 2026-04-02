.. _tensorflow:

Tensorflow
##########

To use TensorFlow on the cluster, start by reviewing the :ref:`Conda <conda>` installer and
how to manage :ref:`Conda environments <conda_create_env>`.

There are two main ways to use TensorFlow:

1. **Using the Global Conda Environment**

   The cluster provides a pre-configured global Conda environment with TensorFlow.
   Note that only administrators can modify this environment, so you're limited to the installed packages.

   .. code-block:: bash

       module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
       conda env list
       conda activate tensorflow

2. **Creating a Custom Conda Environment**

  .. note::
    TensorFlow is typically installed via ``pip`` in Conda environments.
    Ensure your environment includes a version of TensorFlow built with GPU support (e.g., ``tensorflow==2.15.0`` or later).

   You can create your own environment in two ways:

   - **Clone the global** ``tensorflow`` **environment**  
     Refer to :ref:`Cloning an Environment <conda_clone_env>`. After exporting the environment,
     you can edit the ``environment.yml`` file before creating your custom environment,
     or use it as-is and install additional packages as needed.

   - **Create a new environment from scratch**  
     This gives you full control over the packages and versions you include.

        .. code-block:: bash

            module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
            conda create --name my_tensorflow_env tensorflow-gpu 

Verifying GPU Availability
==========================

After activating your environment, verify that TensorFlow detects the GPUs:

.. code-block:: python

    import tensorflow as tf

    print("Num GPUs Available:", len(tf.config.list_physical_devices('GPU')))
    print("GPU Devices:", tf.config.list_physical_devices('GPU'))

If GPUs are available, you should see output listing one or more GPU devices.

Single Node, Multi-GPU Training
===============================

TensorFlow automatically uses all visible GPUs. You can control GPU memory growth and device placement as follows:

.. code-block:: python

    import tensorflow as tf

    gpus = tf.config.list_physical_devices('GPU')
    for gpu in gpus:
        tf.config.experimental.set_memory_growth(gpu, True)

    strategy = tf.distribute.MirroredStrategy()

    with strategy.scope():
        model = tf.keras.models.Sequential([
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dense(1)
        ])
        model.compile(optimizer='adam', loss='mse')

    # Dummy data
    import numpy as np
    x = np.random.randn(1000, 10)
    y = np.random.randn(1000, 1)

    model.fit(x, y, epochs=5, batch_size=64)

TensorFlow guesses the optimal number of threads (CPU cores) to use, but you can
manually control this by

a. Setting environmental variables like ``TF_NUM_INTEROP_THREADS`` and ``TF_NUM_INTRAOP_THREADS``
   in your batch submission script or within your python script. For example,

  .. code-block:: python

    import os
    import tensorflow as tf

    os.environ["TF_NUM_INTEROP_THREADS"] = "2"
    os.environ["TF_NUM_INTRAOP_THREADS"] = "4"

b. or by modifying TensorFlow's runtime configuration with:

  .. code-block:: python

    # Num threads for parallelism between independent operations
    tf.config.threading.set_inter_op_parallelism_threads(num)
    # Num threads for parallelism within an individual operation
    tf.config.threading.set_intra_op_parallelism_threads(num)

**Slurm script for single-node, multi-GPU training:**

.. code-block:: bash

    #SBATCH --job-name=tf_single_node
    #SBATCH --nodes=1
    #SBATCH --gpus-per-node=2
    #SBATCH --ntasks-per-node=2
    #SBATCH --cpus-per-task=24
    #SBATCH --time=01:00:00
    #SBATCH --partition=gpu

    module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
    conda activate my_tensorflow_env

    python train_tf.py
..
    Multi-Node, Multi-GPU Training
    ------------------------------

    For tensorflow-gpu>=2.16.x, tf.distributed.MultiWorkerMirroredStrategyis not compatible with keras>3.0.0, so if anyone wants to run on a distributed manner, they would need tensorflow<2.16.0 and keras<3.0.0. This would restrictict users to  python<=3.9.15. Here is the source: https://github.com/ray-project/ray/issues/47464
    the tensorflow binaries in conda for tensorflow<2.16.0 are not compatible with cuda capability 9.0 GPUs (i.e. our GPUs). This means that even if they use tensorflow<2.16.0 and keras<3.0.0, running on the GPUs won't be possible on multi-node, multi-gpu.

    .. warning::
        This mode of operation is only supported with ``tensorflow<2.16.0`` ``keras<3.0.0``

    For multi-node training, use ``tf.distribute.MultiWorkerMirroredStrategy``
    (Read more at `TensorFlow's MultiWorkerMirrorStrategy documentation <https://www.tensorflow.org/api_docs/python/tf/distribute/MultiWorkerMirroredStrategy>`_).
    TensorFlow uses the ``TF_CONFIG`` environment variable to coordinate workers
    (Read more at `TensorFlow's  TF_CONFIG documentation <https://www.tensorflow.org/guide/distributed_training#TF_CONFIG>`_).

    **Slurm script for 2 nodes with 2 GPUs each:**

    .. code-block:: bash

        #SBATCH --job-name=tf_multi_node
        #SBATCH --nodes=2
        #SBATCH --ntasks-per-node=1
        #SBATCH --gpus-per-node=4
        #SBATCH --cpus-per-task=8
        #SBATCH --time=02:00:00
        #SBATCH --partition=gpu

        module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
        conda activate my_tensorflow_env

        # Get node list and assign roles
        nodes=($(scontrol show hostnames $SLURM_JOB_NODELIST | sed 's/larcc-/larcc-hs-/g'))
        master=${nodes[0]}
        port=`comm -23 <(seq 1024 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1`
        worker_id=$SLURM_NODEID

        export TF_CONFIG='{
            "cluster": {
                "worker": ["'"${nodes[0]}"':'$port'", "'"${nodes[1]}"':'$port'"]
            },
            "task": {"type": "worker", "index": '"$worker_id"'}
        }'

        python train_tf_multi.py

    **train_tf_multi.py** should use:

    .. code-block:: python

        import tensorflow as tf
        import numpy as np

        strategy = tf.distribute.MultiWorkerMirroredStrategy()

        with strategy.scope():
            model = tf.keras.models.Sequential([
                tf.keras.layers.Dense(128, activation='relu'),
                tf.keras.layers.Dense(1)
            ])
            model.compile(optimizer='adam', loss='mse')

        x = np.random.randn(1000, 10)
        y = np.random.randn(1000, 1)

        model.fit(x, y, epochs=5, batch_size=64)

