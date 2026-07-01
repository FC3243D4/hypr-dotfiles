#!/bin/bash

# Get the GPU utilization from nvidia-smi
GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits) 

#Output for waybar
echo "{\"text\": \"$GPU_UTIL%\"}"
