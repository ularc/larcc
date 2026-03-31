#!/bin/sh
#SBATCH --job-name="rstudio-server"
#SBATCH --time=08:00:00
#SBATCH --signal=USR2
#SBATCH --nodes=1
#SBATCH --partition=compute
#SBATCH --mem=515002
#SBATCH --output=/home/%u/rstudio-server.%j.out
#SBATCH --error=/home/%u/rstudio-server.%j.err

module load apptainer/1.3.4-gcc-11.5.0

## CHANGE ME!!! #############################################
# You can set this to a specific R version if you would like
# For example, VERSION_OF_R=4.5
VERSION_OF_R=latest
# Folder where the apptainer/singularity instances are saved
FOLDER_CONTAINER_INSTANCES=$HOME
############################################################

CONTAINER=${FOLDER_CONTAINER_INSTANCES}/rstudio_${VERSION_OF_R}.sif

if ! [ -f $CONTAINER ]; then
    printf "Please run apptainer pull docker://rocker/rstudio:${VERSION_OF_R} and, once the download finishes, make sure the rstudio_${VERSION_OF_R}.sif file is placed in ${FOLDER_CONTAINER_INSTANCES}" 1>&2
fi

# Create temporary directory to be populated with directories to bind-mount in the container
# where writable file systems are necessary. Adjust path as appropriate for your computing environment.
workdir=$(mktemp -d)

# Set R_LIBS_USER to an existing path specific to rocker/rstudio to avoid conflicts with
# personal libraries from any R installation in the host environment

cat > ${workdir}/rsession.sh <<END
#!/bin/sh
export R_LIBS_USER=\${HOME}/R/rocker-rstudio/${VERSION_OF_R}
mkdir -p "\${R_LIBS_USER}"
## custom Rprofile & Renviron (default is \$HOME/.Rprofile and \$HOME/.Renviron)
# export R_PROFILE_USER=/path/to/Rprofile
# export R_ENVIRON_USER=/path/to/Renviron
exec /usr/lib/rstudio-server/bin/rsession "\${@}"
END

chmod +x ${workdir}/rsession.sh

export APPTAINER_BIND="${workdir}/rsession.sh:/etc/rstudio/rsession.sh"

# Do not suspend idle sessions.
# Alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export APPTAINERENV_RSTUDIO_SESSION_TIMEOUT=0

export APPTAINERENV_USER=$(id -un)
export APPTAINERENV_PASSWORD=$(openssl rand -base64 15)
# get unused socket per https://unix.stackexchange.com/a/132524
# tiny race condition between the python & singularity commands
readonly PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
cat 1>&2 <<END
1. SSH tunnel from your workstation using the following command:

   ssh -N -L 8787:`hostname | sed 's/larcc-/larcc-hs-/'`:${PORT} ${APPTAINERENV_USER}@larcc.hpc.louisville.edu

   and point your web browser to http://localhost:8787

2. log in to RStudio Server using the following credentials:

   user: ${APPTAINERENV_USER}
   password: ${APPTAINERENV_PASSWORD}

When done using RStudio Server, terminate the job by:

1. Exit the RStudio Session ("power" button in the top right corner of the RStudio window)
2. Issue the following command on the login node:

      scancel -f ${SLURM_JOB_ID}
END

singularity exec --cleanenv \
                 --scratch /run,/tmp,/var/lib/rstudio-server \
                 --workdir ${workdir} \
                 ${CONTAINER} \
    rserver --www-port ${PORT} \
            --auth-none=0 \
            --auth-pam-helper-path=pam-helper \
            --auth-stay-signed-in-days=30 \
            --auth-timeout-minutes=0 \
            --server-user=$(whoami) \
            --rsession-path=/etc/rstudio/rsession.sh
printf 'rserver exited' 1>&2
