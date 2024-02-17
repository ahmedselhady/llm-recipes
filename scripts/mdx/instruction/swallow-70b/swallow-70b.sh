#!/bin/bash
#$ -l rt_AF=16
#$ -l h_rt=0:9:30:00
#$ -j y
#$ -o outputs/instruction/swallow-70b/
#$ -cwd

# module load
source /etc/profile.d/modules.sh
module load cuda/11.8/11.8.0
module load cudnn/8.9/8.9.2
module load nccl/2.16/2.16.2-1
module load hpcx/2.12

# swich virtual env
source .env/bin/activate

# distributed settings
export MASTER_ADDR=$(/usr/sbin/ip a show dev bond0 | grep 'inet ' | awk '{ print $2 }' | cut -d "/" -f 1)
export MASTER_PORT=$((10000 + ($JOB_ID % 50000)))

echo "MASTER_ADDR=${MASTER_ADDR}"

# hostfile

if [[ "$SGE_RESOURCE_TYPE" == "rt_F" ]]; then
  export NUM_GPU_PER_NODE=4
  NODE_TYPE="v100"
elif [[ "$SGE_RESOURCE_TYPE" == "rt_AF" ]]; then
  export NUM_GPU_PER_NODE=8
  NODE_TYPE="a100"
else
  echo "Unrecognized SGE_RESOURCE_TYPE: $SGE_RESOURCE_TYPE"
fi

NUM_NODES=$NHOSTS
NUM_GPUS=$((${NUM_NODES} * ${NUM_GPU_PER_NODE}))

mkdir -p ./hostfile

HOSTFILE_NAME=./hostfile/hostfile_${JOB_ID}
while read -r line; do
  echo "${line} slots=${NUM_GPU_PER_NODE}"
done <"$SGE_JOB_HOSTLIST" >"$HOSTFILE_NAME"

# training config
SEQ_LENGTH=4096
DATA_PARALLEL_SIZE=$NUM_GPUS

MICRO_BATCH_SIZE=1
GLOBAL_BATCH_SIZE=64

# optimizer config
LR=1e-5
MIN_LR=1e-6
WEIGHT_DECAY=0.1
GRAD_CLIP=1

# checkpoint & tokenizer
TOKENIZER_MODEL=/bb/llm/gaf51275/llama/huggingface-checkpoint/Swallow-70b-hf/tokenizer.model
CHECKPOINT_DIR=/bb/llm/gaf51275/llama/huggingface-checkpoint/Swallow-70b-hf
CHECKPOINT_SAVE_DIR="/bb/llm/gaf51275/llama/checkpoints/Swallow-70b-instruct/lr_${LR}-minlr_${MIN_LR}"

mkdir -p ${CHECKPOINT_SAVE_DIR}

# data config

DATASET_DIR=/bb/llm/gaf51275/llama/datasets/instruction/imitative-open-asst2

TRAIN_DATA_PATH=${DATASET_DIR}/train.jsonl
VALID_DATA_PATH=${DATASET_DIR}/val.jsonl

# job name
JOB_NAME="Swallow-70b-VE-imitative-oasst2-BS=${GLOBAL_BATCH_SIZE}-LR=${LR}-MINLR=${MIN_LR}"

# run
mpirun -np $NUM_GPUS \
  --npernode $NUM_GPU_PER_NODE \
  -hostfile $HOSTFILE_NAME \
  -x MASTER_ADDR=$MASTER_ADDR \
  -x MASTER_PORT=$MASTER_PORT \
  -bind-to none -map-by slot \
  -x PATH \
  python examples/finetuning.py \
  --seq-length ${SEQ_LENGTH} \
  --sliding-window-size ${SEQ_LENGTH} \
  --micro-batch-size ${MICRO_BATCH_SIZE} \
  --global-batch-size ${GLOBAL_BATCH_SIZE} \
  --hf-transformer-model-dir ${CHECKPOINT_DIR} \
  --tokenizer-type Llama2Tokenizer \
  --tokenizer-model ${TOKENIZER_MODEL} \
  --instruction-train-data-path ${TRAIN_DATA_PATH} \
  --instruction-valid-data-path ${VALID_DATA_PATH} \
  --epoch 2 \
  --train-iters 500000 \
  --lr ${LR} \
  --min-lr ${MIN_LR} \
  --lr-decay-style cosine \
  --weight-decay ${WEIGHT_DECAY} \
  --grad-clip-norm ${GRAD_CLIP} \
  --optimizer adam \
  --adam-beta1 0.9 \
  --adam-beta2 0.95 \
  --adam-eps 1e-6 \
  --save-interval 500 \
  --eval-interval 100 \
  --eval-iters 10 \
  --bf16 \
  --mixed-precision \
  --base-model ${CHECKPOINT_DIR} \
  --save ${CHECKPOINT_SAVE_DIR} \
  --load ${CHECKPOINT_SAVE_DIR} \
  --low-cpu-fsdp \
  --sharding-strategy FULL_SHARD \
  --checkpoint-type LOCAL_STATE_DICT \
  --fsdp-activation-checkpointing \
  --instruction-tuning \
  --save-sampler-state \
  --use-mpi \
  --wandb-entity "prj-jalm" \
  --wandb-project "Llama-2-70b-instruct" \
  --wandb-name "${JOB_NAME}"
