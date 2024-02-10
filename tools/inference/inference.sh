#!/bin/bash
#$ -l rt_AG.small=1
#$ -l h_rt=1:00:00
#$ -j y
#$ -o outputs/inference/
#$ -cwd
# module load
source /etc/profile.d/modules.sh
module load cuda/11.8/11.8.0
module load cudnn/8.9/8.9.2
module load nccl/2.16/2.16.2-1
module load hpcx/2.12

set -e

# swich virtual env
source .env/bin/activate

# distributed settings
export MASTER_ADDR=$(/usr/sbin/ip a show dev bond0 | grep 'inet ' | awk '{ print $2 }' | cut -d "/" -f 1)
export MASTER_PORT=$((10000 + ($JOB_ID % 50000)))

echo "MASTER_ADDR=${MASTER_ADDR}"

python tools/inference/inference.py \
  --model-path /bb/llm/gaf51275/llama/converted-hf-checkpoint/mistral-7B-VE/okazaki-cc/iter_0004000 \
  --tokenizer-path /bb/llm/gaf51275/llama/converted-hf-checkpoint/mistral-7B-VE/okazaki-cc/iter_0004000 \
  --prompt "Tokyo is the capital of Japan."

python tools/inference/inference.py \
  --model-path /bb/llm/gaf51275/llama/converted-hf-checkpoint/mistral-7B-VE/okazaki-cc/iter_0004000 \
  --tokenizer-path /bb/llm/gaf51275/llama/converted-hf-checkpoint/mistral-7B-VE/okazaki-cc/iter_0004000 \
  --prompt "東京工業大学のキャンパスは"
