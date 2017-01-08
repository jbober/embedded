export MAKEFLAGS=--no-print-directory

#CXX_SOURCES := src/main.cpp 
C_SOURCES := src/startup_gcc.c src/blinky.c
ASM_SOURCES :=
CPU=-mcpu=cortex-m4
FPU=-mfpu=fpv4-sp-d16 -mfloat-abi=softfp
# output
# directory variables
ROOT_DIR = $(shell pwd)
BUILD_DIR := $(ROOT_DIR)/build
OUTPUT_DIR := $(ROOT_DIR)/bin
FIRMWARE := $(OUTPUT_DIR)/firmware
PERL_ROOT_DIR := $(subst /,\/,$(ROOT_DIR))
PERL_BUILD_DIR := $(subst /,\/,$(BUILD_DIR))

# linker script
LD_SCRIPT := blinky.ld

PART=LM4F120H5QR
# compiler flags
COMMON_FLAGS := -g -Wall -Wno-unused-parameter \
	-mthumb ${CPU} ${FPU} \
	-pedantic -DPART_${PART} -ffunction-sections -fdata-sections \
	-DTARGET_IS_BLIZZARD_RA1 -nostdlib -fno-exceptions

CXX_FLAGS := $(COMMON_FLAGS) -std=c++11 -fno-rtti
CC_FLAGS := $(COMMON_FLAGS) -std=gnu99

CFLAGS=-Os                 \
       -MD                 \
       -c
# compiler
CC := arm-none-eabi-gcc
CXX := arm-none-eabi-g++
LD := arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
LM4FLASH = lm4flash

TIVAWARE_PATH = /home/bober/workspace/embedded_/from_git/stellaris/

# library linker flags
LD_FLAGS := -T $(LD_SCRIPT) --entry ResetISR --gc-sections \
	#-L $(TIVAWARE_PATH)/driverlib/gcc-cm4f -ldriver-cmd4f \
	#-L $(ARM_NONE_EABI_PATH)

# include flags
INCLUDES := -I. -I$(TIVAWARE_PATH)

# adding prefix to objects, so that they will be put in correct directory
OBJECT_PATH := $(subst $(ROOT_DIR), $(BUILD_DIR), $(shell pwd))
CXX_OBJECTS := $(addprefix $(OBJECT_PATH)/, $(CXX_SOURCES:.cpp=.cpp.o))
C_OBJECTS := $(addprefix $(OBJECT_PATH)/, $(C_SOURCES:.c=.c.o))
ASM_OBJECTS := $(addprefix $(OBJECT_PATH)/, $(ASM_SOURCES:.s=.s.o))

all: directories $(FIRMWARE)
	@echo "Built Firmware"
	@arm-none-eabi-size $(CXX_OBJECTS) $(C_OBJECTS) $(ASM_OBJECTS) $(FIRMWARE).obj -d

# dependency files
DEP_FILES := $(shell find $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) -name '*.d')
-include $(DEP_FILES)

$(OBJECT_PATH)/%.cpp.o: %.cpp
# mkdir will recreate the file structure of the original
	@mkdir -p $(dir $@)
# taking the output of dependency generation, and formatting it correctly
	@$(CXX) -MM $(CXX_FLAGS) $(INCLUDES) $< | \
		perl -pe 's/([a-zA-Z0-9_\/-]*)\.((?!o)[a-zA-Z]*)/$$1.$$2/g' | \
		perl -pe 's/([a-zA-Z0-9_\/-]*)\.o/$(subst /,\/,$(dir $@))$$1.cpp.o/g' > $@.d
	@echo "Object [$@]"
	@$(CXX) $(CXX_FLAGS) $(INCLUDES) -S -o $(addsuffix .s, $(basename $@)) $<
	@$(CXX) $(CXX_FLAGS) $(INCLUDES) -c -o $@ $(addsuffix .s, $(basename $@))

$(OBJECT_PATH)/%.c.o: %.c
# mkdir will recreate the file structure of the original
	@mkdir -p $(dir $@)
# taking the output of dependency generation, and formatting it correctly
	@$(CC) -MM $(CC_FLAGS) $(INCLUDES) $< | \
		perl -pe 's/([a-zA-Z0-9_\/-]*)\.((?!o)[a-zA-Z]*)/$$1.$$2/g' | \
		perl -pe 's/([a-zA-Z0-9_\/-]*)\.o/$(subst /,\/,$(dir $@))$$1.c.o/g' > $@.d
	@echo "Object [$@]"
	@$(CC) $(CC_FLAGS) $(INCLUDES) -S -o $(addsuffix .s, $(basename $@)) $<
	@$(CC) $(CC_FLAGS) $(INCLUDES) -c -o $@ $(addsuffix .s, $(basename $@))

$(OBJECT_PATH)/%.s.o: %.s
# mkdir will recreate the file structure of the original
	@mkdir -p $(dir $@)
	@echo "Object [$@]"
	@$(CC) $(CC_FLAGS) $(INCLUDES) -c -o $@ $<

$(FIRMWARE): $(CXX_OBJECTS) $(C_OBJECTS) $(ASM_OBJECTS)
	@$(LD) $(CXX_OBJECTS) $(C_OBJECTS) $(ASM_OBJECTS) $(LD_FLAGS) -o $(FIRMWARE).obj
	@$(OBJCOPY) -O binary $(FIRMWARE).obj $@.out

clean: 
	@rm -f -r $(BUILD_DIR)
	@rm -f -r $(OUTPUT_DIR)

cleandep:
	@find . -name "*.d" -type f -delete

directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(OUTPUT_DIR)

upload: all
	$(LM4FLASH) $(FIRMWARE).out
	@echo "Finished Upload"

.PHONY: all clean cleandep directories upload $(FIRMWARE)
