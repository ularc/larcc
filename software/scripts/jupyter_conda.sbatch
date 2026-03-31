#!/bin/bash
#SBATCH --job-name="jupyter"
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --partition=gpu
#SBATCH --output=/home/%u/jupyter.%j.out
#SBATCH --error=/home/%u/jupyter.%j.err

module load miniforge3/24.3.0-0-gcc-11.5.0-wkw4vym

# CHANGE THIS TO THE CONDA ENVIRONMENT YOU SEE FIT
conda activate jupyter

# This line prints a random, available port for jupyter to use
PORT=`comm -23 <(seq 1024 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1`
PASS=`openssl rand -base64 15`
HASHED_PASS=`python -c "from jupyter_server.auth import passwd; print(passwd('$PASS'))"`

cat 1>&2 <<END
1. SSH tunnel from your workstation using the following command:

   ssh -N -L ${PORT}:`hostname | sed 's/larcc-/larcc-hs-/'`:${PORT} ${SLURM_JOB_USER}@larcc.hpc.louisville.edu

   and point your web browser to http://localhost:${PORT}

2. log in to Jupyter using the following password: ${PASS}

When done using Jupyter, terminate the job by issuing the following command on the login node:

      scancel -f ${SLURM_JOB_ID}
END

jupyter notebook --no-browser --port=$PORT \
    --ServerApp.ip=0.0.0.0 \
    --PasswordIdentityProvider.hashed_password="$HASHED_PASS"
