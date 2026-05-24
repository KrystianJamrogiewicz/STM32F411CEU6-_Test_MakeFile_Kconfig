# ====================================================================
#  MAKEFILE FOR STM32F411
# ====================================================================

# A Makefile does not execute from top to bottom. Instead, it analyzes 
# the whole file and builds a dependency graph to execute a specific rule.
# Running just the 'make' command will trigger only the first rule at the top (all).
# Other specific rules must be called manually using 'make rule_name'.

# Rules point to other rules via dependencies listed after the ':' character. 
# For example, the 'all' target requires '$(TARGET).bin', which in turn 
# requires '$(TARGET).elf'. This creates an automatic chain reaction.

# ====================================================================
# VARIABLES
# ====================================================================

# Base name for the generated output files (.bin, .elf)
TARGET = Makefile_Kconfig_test

# TOOL DEFINITIONS (ARM Cross-Compiler and helper tools)
CC      = arm-none-eabi-gcc # Compiler that translates C code into ARM processor machine code
OBJCOPY = arm-none-eabi-objcopy # Tool to extract raw binary code (converts from ELF format to BIN)
SIZE    = arm-none-eabi-size # Tool that calculates Flash and RAM memory usage of the program

# List of all source files included in the project
SRCS = main.c startup_stm32f411ceux.s


# ====================================================================
# ARCHITECTURE AND COMPILATION FLAGS
# ====================================================================

# Processor hardware flags (Cortex-M4 core, Thumb mode, hardware FPU support)
MCU_FLAGS = -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16

# Compiler flags for C code (CFLAGS)
CFLAGS = $(MCU_FLAGS) -Wall -O0 -g
# -Wall: Enables all compiler warning messages about potential code errors.
# -O0: Disables code optimization (essential for accurate step-by-step debugging).
# -g: Generates debugging information (allows VS Code to view source lines during debugging).

# Linker flags (LDFLAGS) - merges object files into a single .elf file.
# The .ld script acts as a memory map - it specifies the start addresses of the microcontroller's Flash and RAM.
LDFLAGS = $(MCU_FLAGS) -TSTM32F411CEUX_FLASH.ld -nostartfiles --specs=nano.specs --specs=nosys.specs


# ====================================================================
#  PROJECT BUILD RULES (MAIN)
# ====================================================================

# Default rule (all) - triggered by just typing 'make'. Its goal is to create the .bin file
all: $(TARGET).bin

# Building the executable .elf file. Requires the source code and the current config.h header file
$(TARGET).elf: $(SRCS) config.h
# Runs the compiler to generate the executable .elf file
	$(CC) $(CFLAGS) $(SRCS) $(LDFLAGS) -o $(TARGET).elf
# Displays the final size of individual program sections in the terminal
	$(SIZE) $(TARGET).elf

# Generating a clean .bin binary file based on the built .elf file
$(TARGET).bin: $(TARGET).elf
# Converts the file format using the objcopy tool
	$(OBJCOPY) -O binary $(TARGET).elf $(TARGET).bin


# ====================================================================
#  KCONFIG RULES
# ====================================================================

# Manually launch the text configuration menu (command: make menuconfig)
menuconfig:
# Launches the interactive, blue Kconfig menu in the terminal
	kconfig-mconf Kconfig
# Immediately forces an update of the config.h header based on the new data after closing the menu
	@$(MAKE) config.h

# Automatically generates the C language config.h header file from the .config database
config.h: .config
	@echo "Generating config.h file from Kconfig configuration..."
	@echo "#ifndef CONFIG_H" > config.h
	@echo "#define CONFIG_H" >> config.h
# The sed script parses the text file .config and rewrites lines into C-compatible #define directives
	@sed -n 's/^\(CONFIG_[A-Z0-9_]*\)=\(.*\)/#define \1 \2/p' .config >> config.h
	@sed -i 's/=y/ 1/' config.h
	@echo "#endif" >> config.h

# Fallback rule: if the .config file does not exist, it generates one with default values from Kconfig
.config: Kconfig
	@echo "No .config file found, creating default configuration..."
	kconfig-conf --olddefconfig Kconfig
	@$(MAKE) config.h


# ====================================================================
#  CLEAN RULE (make clean)
# ====================================================================

# Removes all temporary and binary files from the project folder, allowing a fresh build from scratch
clean:
	rm -f *.elf *.bin config.h .config .config.old

# Definition of phony (virtual) targets. Tells make that all, clean, and menuconfig 
# are names of internal commands, not actual physical files on the disk.
.PHONY: all clean menuconfig