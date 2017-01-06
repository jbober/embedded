
CPU=-mcpu=cortex-m4
FPU=-mfpu=fpv4-sp-d16 -mfloat-abi=softfp

CFLAGS=-mthumb             \
       ${CPU}              \
       ${FPU}              \
       -Os                 \
       -ffunction-sections \
       -fdata-sections     \
       -MD                 \
       -std=c++11            \
       -Wall               \
       -pedantic           \
       -DPART_${PART}      \
       -c
