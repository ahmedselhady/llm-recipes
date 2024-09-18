#!/bin/bash

data_folders=(
    "cultura-x"
    "euscrawl_v1"
    "hplt_v1"
    "booktegi_bsc"
    "colossal-oscar_1.0__05-06-23"
    "egunkaria__01-06"
    "wikipedia__20231101"
    "euscrawl_v1.202311"
)
splits=("train" "test" "valid")


for folder in "${data_folders[@]}"; do
    for split in "${splits[@]}"; do
        cp ${WORK}/data/ilenia/v1/jsonl/${folder}/${split}.jsonl.gz /leonardo_scratch/large/userexternal/amohamed/eus_data_jsonl/${folder}_${split}.jsonl.gz
    done
done



