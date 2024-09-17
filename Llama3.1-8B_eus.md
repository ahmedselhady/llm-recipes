
# On Leonardo Cenica
## Loading modules
```
module load profile/deeplrn
module load python/3.10.8--gcc--11.3.0
module load cuda/11.8
module load openmpi/4.1.4--gcc--11.3.0-cuda-11.8
module load zlib/1.2.13--gcc--11.3.0
module load git-lfs
```

## Creating virtual environment

```
 python -m venv $WORK/environments/llm-recipe-env
```

## Activate the environment

```
 source $WORK/environments/llm-recipe-env/bin/activate
```

# Install

