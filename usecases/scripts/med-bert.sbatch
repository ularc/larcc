#!/bin/bash
#SBATCH --partition=compute
#SBATCH --time=3-00:00:00
#SBATCH --ntasks=128
#SBATCH --ntasks-per-core=1

PROJECT_NAME="Med-BERT"
PROJECT_DIR="/home/$USER/$PROJECT_NAME"
SCRATCH_DIR="/mnt/scratch/local/$USER"
WDIR="$SCRATCH_DIR/$SLURM_JOB_ID"
PRETRAIN_DIR="$WDIR/$PROJECT_NAME/Pretraining_Code"
OUTDIR="$WDIR/out"

# Copy project to scratch space to speed-up reading and writting of data.
# Checkpoints will be written to scratch too. You want to avoid writting to
# your home storage as it's orders of magnitude slower for read/write operations.
mkdir -p "$WDIR"
mkdir -p "$OUTDIR"
cp -r "$PROJECT_DIR" "$WDIR"
cd "$PRETRAIN_DIR"

# BACKUP settings:
#   These variables control how often and where the checkpoints produced
#   by the pretraining code is copied over to persistent storage.
BACKUP_DIR="$PROJECT_DIR/Pretraining_Code/checkpoint_$SLURM_JOB_ID"
BACKUP_FREQUENCY=600 # i.e. checkpoint every 10m
BACKUP_LOCK="$SCRATCH_DIR/backup_in_progress_$SLURM_JOB_ID"
BACKUP_CMD="rsync -a $OUTDIR/ $BACKUP_DIR/"

# Start background process to copy any produced checkpoint back to
# persistent storage
bash -c "
  while [ -e /proc/$$ ]; do
    sleep $BACKUP_FREQUENCY
    touch $BACKUP_LOCK
    $BACKUP_CMD
    rm $BACKUP_LOCK
  done
" &
backup_pid=$!

module load miniforge3
conda activate my_tf1

python3 run_EHRpretraining.py \
        --input_file="$PRETRAIN_DIR/Data_Pre-processing_Code/ehr_tf_features" \
        --output_dir="$OUTDIR" \
        --do_train=True \
        --do_eval=True \
        --bert_config_file="$PRETRAIN_DIR/config.json" \
        --train_batch_size=32 \
        --max_seq_length=64 \
        --max_predictions_per_seq=1 \
        --num_train_steps=4500000 \
        --num_warmup_steps=10000 \
        --learning_rate=5e-5

# Wait for active backup (if any) to finish
while [ -e $BACKUP_LOCK ]; do sleep 1; done
# Prevent any more auto-backups from starting and perform
# final backup
kill -9 $backup_pid
$BACKUP_CMD