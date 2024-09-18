#!/bin/bash
#SBATCH -A EUHPC_E02_013
#SBATCH -p boost_usr_prod
#SBATCH --time 12:00:00         # format: HH:MM:SS
#SBATCH --nodes 1               # 4 node
#SBATCH --ntasks-per-node=4     # 4 tasks out of 32
#SBATCH --gres=gpu:2            # 4 gpus per node out of 4
#SBATCH --mem=494000MB              # memory per node out of 494000MB
#SBATCH --output=.slurm/preprocess_data.out
#SBATCH --error=.slurm/preprocess_data.err
#SBATCH --exclusive
#SBATCH --requeue

#--open-mode=append

# setup the virtual env
# load leonardo modules
module load profile/deeplrn
module load python/3.10.8--gcc--11.3.0
module load cuda/11.8
module load openmpi/4.1.4--gcc--11.3.0-cuda-11.8
module load zlib/1.2.13--gcc--11.3.0
module load git-lfs


source ${WORK}/environments/llm-recipe-env/bin/activate

DATASET_DIR=/leonardo_scratch/large/userexternal/amohamed/eus_data_jsonl/jsonl
OUTPUT_DIR=/leonardo_scratch/large/userexternal/amohamed/eus_data_jsonl/preprocessed

mkdir -p ${OUTPUT_DIR}


cd $HOME/llm-recipes
splits=("train" "test" "valid")

# Loop over the data types
for split in "${splits[@]}"; do
    echo "Processing ${split}"

    python megatron_lm/tools/preprocess_data.py \
    --input ${DATASET_DIR}/${split}_combined_output.jsonl.gz \
    --output-prefix ${OUTPUT_DIR}/${split}_text_documents \
    --tokenizer-type Llama3Tokenizer \
    --tokenizer-model $HOME/llama3tokenizer/ \
    --append-eod \
    --workers 64

done
