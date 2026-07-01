#!/bin/bash

# Find discrete GPU (prefer NVIDIA, else AMD with most clock states)
NVIDIA_CARD=$(grep -rl '0x10de' /sys/class/drm/card*/device/vendor 2>/dev/null | head -1 | xargs dirname)
AMD_CARD=$(for v in /sys/class/drm/card*/device/vendor; do
    [[ $(cat "$v" 2>/dev/null) == "0x1002" ]] || continue
    dir=$(dirname "$v")
    echo "$(cat ${dir}/pp_dpm_sclk 2>/dev/null | wc -l) $dir"
done | sort -rn | head -1 | awk '{print $2}')

if [[ -n "$NVIDIA_CARD" ]]; then
    case "$1" in
        usage)   nvidia-smi --query-gpu=utilization.gpu    --format=csv,noheader,nounits 2>/dev/null || echo 0 ;;
        temp)    nvidia-smi --query-gpu=temperature.gpu    --format=csv,noheader,nounits 2>/dev/null || echo 0 ;;
        memory)  nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits 2>/dev/null || echo 0 ;;
        freq)    nvidia-smi --query-gpu=clocks.gr          --format=csv,noheader,nounits 2>/dev/null || echo 0 ;;
    esac
else
    CARD="$AMD_CARD"
    case "$1" in
        usage)   cat ${CARD}/gpu_busy_percent 2>/dev/null || echo 0 ;;
        temp)    cat ${CARD}/hwmon/hwmon*/temp1_input 2>/dev/null | awk '{print int($1/1000)}' || echo 0 ;;
        memory)  rocm-smi --showmemuse --csv 2>/dev/null | awk -F',' 'NR==2{print int($2+0)}' ;;
        freq)    awk '/\*/{gsub(/[^0-9]/,""); print $0+0}' ${CARD}/pp_dpm_sclk 2>/dev/null || echo 0 ;;
    esac
fi