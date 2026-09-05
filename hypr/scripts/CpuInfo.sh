#!/bin/bash

# Find CPU manufacturer


get_temp() {
    CPU_VENDOR=$(awk -F: '/vendor_id/{gsub(/ /,"",$2); print $2; exit}' /proc/cpuinfo)
    if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
        CPU_VENDOR="Intel"
        probe=$(grep -l coretemp /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)
        probe=${probe%/name}
    elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
        CPU_VENDOR="AMD"
        probe=$(grep -l k10temp /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)
        probe=${probe%/name}
    else
        echo "Unknown CPU vendor: $CPU_VENDOR" >&2
        exit 1
    fi

    mdeg=$(cat "$probe/temp1_input" 2>/dev/null)
    [ -z "$mdeg" ] && { echo "no thermal data" >&2; exit 1; }
    echo $(( (mdeg + 500) / 1000 ))
}

get_freq() {
    khz=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | sort -n | tail -1)
    [ -z "$khz" ] && { echo "no cpufreq data" >&2; exit 1; }
    ghz=$((khz / 1000))
    echo $ghz
}

get_freq_ghz() {
    khz=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | sort -n | tail -1)
    [ -z "$khz" ] && { echo "no cpufreq data" >&2; exit 1; }
    ghz=$((khz / 1000000))
    frac=$(printf "%02d" $(((khz % 1000000) / 10000)))
    echo "${ghz}.${frac}"
}

get_usage() {
    read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
    sleep 0.5
    read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat
    t1=$((u1+n1+s1+i1+w1+q1+sq1+st1));  ti1=$((i1+w1))
    t2=$((u2+n2+s2+i2+w2+q2+sq2+st2));  ti2=$((i2+w2))
    dt=$((t2-t1)); di=$((ti2-ti1))
    [ $dt -le 0 ] && { echo "no usage change" >&2; exit 1; }
    # percentage with one decimal: compute tenths-of-a-percent
    local tenths=$(( (1000 * (dt-di) + dt/2) / dt ))
    echo "$((tenths / 10)).$((tenths % 10))"
}

case "$1" in
    temp)   get_temp ;;
    freq)   get_freq ;;
    freq-ghz)   get_freq_ghz ;;
    usage)   get_usage ;;
    *)
        echo "usage: $0 temp|freq|usage" >&2; exit 1
        ;;
esac