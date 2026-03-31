.. _pytorch:

PyTorch
#######

To use PyTorch on the cluster, start by reviewing the :ref:`Conda <conda>` installer
and how to manage :ref:`Conda environments <conda_create_env>`.

.. note::
    Newer PyTorch versions are not available via Conda, but you can install them using ``pip`` within Conda environments.

There are two main ways to use PyTorch:

1. **Using the Global Conda Environment**

   The cluster provides a pre-configured Conda environment with PyTorch.
   Only administrators can modify this environment, so you're limited to the installed packages.

   .. code-block:: bash

       module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
       conda env list
       conda activate pytorch

2. **Creating a Custom Conda Environment**

   You can create your own environment and install PyTorch via ``pip``.
   Note that cloning the global ``pytorch`` environment won't include PyTorch itself, as it was installed via ``pip``.
   Our GPUs support CUDA up to 12.9. Below are installation examples:

   .. tabs::

       .. tab:: PyTorch 2.7.1 + CUDA 11.8

           .. code-block:: bash

               module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
               conda create --name my_pytorch_cuda11.8
               conda activate my_pytorch_cuda11.8
               pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

       .. tab:: PyTorch 2.7.1 + CUDA 12.6

           .. code-block:: bash

               module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
               conda create --name my_pytorch_cuda12.6
               conda activate my_pytorch_cuda12.6
               pip install torch torchvision torchaudio

       .. tab:: PyTorch 2.7.1 + CUDA 12.8

           .. code-block:: bash

               module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
               conda create --name my_pytorch_cuda12.8
               conda activate my_pytorch_cuda12.8
               pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

Verifying GPU Availability
==========================

After installing PyTorch and activating your environment,
you can verify that PyTorch detects the available GPUs by using
the following Python commands on a GPU node:

.. code-block:: python

    import torch

    print("CUDA available:", torch.cuda.is_available())
    print("Number of GPUs:", torch.cuda.device_count())
    if torch.cuda.is_available():
        print("Current GPU:", torch.cuda.get_device_name(torch.cuda.current_device()))

Remember you'll need to request an interactive or batch job
to be able to ssh into a GPU node. For example:

.. code-block:: bash

    # Submit interactive job
    srun --partition=gpu --job-name test_my_pytorch_env \
        --time=05:00 --nodes=1 --gpus=1 --ntasks-per-node=1 \
        --pty /bin/bash -i
    
    # Create python file to test pytorch
    cat <<EOF > pytorch_test.py
    import torch

    print("CUDA available:", torch.cuda.is_available())
    print("Number of GPUs:", torch.cuda.device_count())
    if torch.cuda.is_available():
        print("Current GPU:", torch.cuda.get_device_name(torch.cuda.current_device()))
    EOF

    # Execute the test program
    module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
    conda activate my_pytorch_env
    python pytorch_test.py

If CUDA is available and at least one GPU is detected, you should see output similar to:

.. code-block:: text

    CUDA available: True
    Number of GPUs: 1
    Current GPU: NVIDIA H100 NVL

.. note::
    If `torch.cuda.is_available()` returns `False`, ensure that:
    
    - You are running on a compute node with GPU access (not a login or cpu node).
    - **Your job explicitely requests 1 or more GPUs** (e.g. ``--gpus=2``, ``--gpus-per-node=2``)
    - Your environment includes a PyTorch build with CUDA support.
    - The appropriate GPU drivers and CUDA libraries are available on the system.

Using GPUs in PyTorch
=====================

Once you've confirmed that your custom PyTorch environment detects the GPUs,
you can start using it for computations. Below are common usage patterns:

Moving Tensors to GPU
----------------------

You can move tensors to the GPU using the ``.to()`` or ``.cuda()`` methods:

.. code-block:: python

    import torch

    # Create a tensor on the CPU
    x_cpu = torch.randn(3, 3)

    # Move it to the GPU (if available)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    x_gpu = x_cpu.to(device)

    print("Tensor device:", x_gpu.device)

Model Training on GPU
----------------------

To train a model on the GPU, both the model and the data must be moved to the GPU:

.. code-block:: python

    import torch
    import torch.nn as nn
    import torch.optim as optim

    # Dummy model
    class SimpleModel(nn.Module):
        def __init__(self):
            super().__init__()
            self.linear = nn.Linear(10, 1)

        def forward(self, x):
            return self.linear(x)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    model = SimpleModel().to(device)
    criterion = nn.MSELoss()
    optimizer = optim.SGD(model.parameters(), lr=0.01)

    # Dummy data
    inputs = torch.randn(32, 10).to(device)
    targets = torch.randn(32, 1).to(device)

    # Training step
    outputs = model(inputs)
    loss = criterion(outputs, targets)
    loss.backward()
    optimizer.step()

    print("Training step completed on:", device)

Monitoring GPU Usage
----------------------

You can monitor GPU usage with:

.. code-block:: bash

    nvidia-smi

This command shows GPU memory usage, active processes, and more.

Multi-GPU Usage in PyTorch
===========================

PyTorch supports single-node multi-GPU training. We present detailed examples below.
Users are encourages to read `torchrun (Elastic Launch) documentation <https://docs.pytorch.org/docs/stable/elastic/run.html>`_
for more information and use cases.

Single Node, Multi-GPU (DataParallel or DDP)
--------------------------------------------

For simple use cases, you can use `torch.nn.DataParallel`, 
but for better performance and scalability, `torch.nn.parallel.DistributedDataParallel` (DDP) is recommended.

Below is a template you can use to run a batch job using DDP on a single node while using 2 GPUs
and all CPU cores.

.. note::
    Keep in mind that when using the ``nccl`` backend with DDP, only 1 process per GPU is allowed. For this case,
    each node has 48 CPU cores and 2 GPUs. Since we are using 1 process per GPU, we are left with 46 cores.
    We want each process to spawn multiple OpenMP threads,
    so we do 46 (CPU cores) / 2 (GPU processes) = 23 threads per GPU process.
    
.. code-block:: bash

    #!/bin/bash
    #SBATCH --job-name=ddp_single_node
    #SBATCH --nodes=1
    #SBATCH --ntasks-per-node=2
    #SBATCH --gpus-per-node=2
    #SBATCH --cpus-per-task=23
    #SBATCH --time=01:00:00
    #SBATCH --partition=gpu

    module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
    conda activate pytorch

    # Each node has 48 CPU cores and 2 GPUs. Since we are using 1
    # process per GPU, we are left with 46 cores. We want each
    # process to spawn multiple OpenMP threads, so we
    # do 46 (CPU cores) / 2 (GPU processes) = 23 (threads per GPU process)
    export OMP_NUM_THREADS=23
    # These are other OpenMP options used to control placement of threads
    # in CPU cores
    export OMP_PLACES=cores
    export OMP_PROC_BIND=close
    export OMP_STACKSIZE=512m

    srun python3 -m torch.distributed.run \
         --standalone \
         --nnodes=1 \
         --nproc-per-node=2 \
        /path/to/train.py

In your ``train.py``, initialize DDP like this:

.. code-block:: python

    import os
    import torch
    import torch.distributed as dist
    from torch.nn.parallel import DistributedDataParallel as DDP

    def main():
        dist.init_process_group("nccl")
        local_rank = int(os.environ["LOCAL_RANK"])
        torch.cuda.set_device(local_rank)

        model = MyModel().to(local_rank)
        ddp_model = DDP(model, device_ids=[local_rank])

        # Training loop here...

    if __name__ == "__main__":
        main()

Here is a working example of the ``train.py``

.. code-block:: python

    import os
    import torch
    import torch.nn as nn
    import torch.optim as optim
    import torch.distributed as dist
    from torch.nn.parallel import DistributedDataParallel as DDP
    from torch.utils.data import Dataset, DataLoader, DistributedSampler

    # Dummy dataset
    class RandomDataset(Dataset):
        def __init__(self, size, length):
            self.len = length
            self.data = torch.randn(length, size)
            self.labels = torch.randn(length, 1)

        def __getitem__(self, index):
            return self.data[index], self.labels[index]

        def __len__(self):
            return self.len

    # Simple model
    class SimpleModel(nn.Module):
        def __init__(self, input_size):
            super(SimpleModel, self).__init__()
            self.linear = nn.Linear(input_size, 1)

        def forward(self, x):
            return self.linear(x)

    def main():
        # Initialize the process group
        dist.init_process_group(backend="nccl")

        local_rank = int(os.environ["LOCAL_RANK"])
        torch.cuda.set_device(local_rank)
        device = torch.device("cuda", local_rank)

        # Create model and move to GPU
        model = SimpleModel(input_size=10).to(device)
        model = DDP(model, device_ids=[local_rank])

        # Create dataset and distributed sampler
        dataset = RandomDataset(size=10, length=1000)
        sampler = DistributedSampler(dataset)
        dataloader = DataLoader(dataset, batch_size=32, sampler=sampler)

        # Loss and optimizer
        criterion = nn.MSELoss()
        optimizer = optim.SGD(model.parameters(), lr=0.01)

        # Training loop
        for epoch in range(5):
            sampler.set_epoch(epoch)
            for batch_idx, (data, target) in enumerate(dataloader):
                data, target = data.to(device), target.to(device)

                optimizer.zero_grad()
                output = model(data)
                loss = criterion(output, target)
                loss.backward()
                optimizer.step()

                if batch_idx % 10 == 0 and local_rank == 0:
                    print(f"Epoch {epoch} | Batch {batch_idx} | Loss {loss.item():.4f}")

        dist.destroy_process_group()

    if __name__ == "__main__":
        main()

..
    Multi-Node, Multi-GPU with Slurm
    --------------------------------

    To scale across multiple nodes, Slurm and PyTorch DDP can be combined. Here's an example for 2 nodes with 4 GPUs each:

..
    .. code-block:: bash
        #SBATCH --job-name=ddp_multi_node
        #SBATCH --nodes=2
        #SBATCH --ntasks-per-node=4
        #SBATCH --gpus-per-node=4
        #SBATCH --cpus-per-task=4
        #SBATCH --time=02:00:00
        #SBATCH --partition=gpu

        module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym
        conda activate pytorch

        export MASTER_ADDR=`ip -j addr | jq -r '.[] | select(.ifname == "bond0") | .addr_info[] | select(.family == "inet") | .local'`
        export MASTER_PORT=`comm -23 <(seq 1024 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1`

        srun python -m torch.distributed.run \
             --nnodes=$SLURM_JOB_NUM_NODES \
             --nproc_per_node=2 \
             --rdzv_id=$SLURM_JOB_ID \
             --rdzv_backend=c10d \
             --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
            train.py


    The `train.py` script remains the same as in the single-node example, as PyTorch handles the multi-node setup via environment variables.

    .. note::
        Ensure that your cluster allows inter-node communication and that the same environment is available on all nodes.
