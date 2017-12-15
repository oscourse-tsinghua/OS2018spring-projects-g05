PROJ	:= 5
EMPTY	:=
SPACE	:= $(EMPTY) $(EMPTY)
SLASH	:= /

V       := @

GCCPREFIX:=mips-sde-elf-

# eliminate default suffix rules
.SUFFIXES: .c .S .h

# define compiler and flags

HOSTCC		:= gcc
HOSTCFLAGS	:= -g -Wall -O2

GDB		:= $(GCCPREFIX)gdb

THUMIPSCC		:= ./thumips-cc
CLANG := clang
#CC :=$(GCCPREFIX)gcc
CFLAGS	:= -fno-builtin -nostdlib  -nostdinc
CTYPE	:= c S

LD      := $(GCCPREFIX)ld
AS      := $(GCCPREFIX)as -EL -g -mips32
LDFLAGS	+= -nostdlib

OBJCOPY := $(GCCPREFIX)objcopy
OBJDUMP := $(GCCPREFIX)objdump

COPY	:= cp
MKDIR   := mkdir -p
MV		:= mv
RM		:= rm -f
AWK		:= awk
SED		:= sed
SH		:= sh
TR		:= tr
TOUCH	:= touch -c

TAR		:= tar
ZIP		:= gzip

OBJDIR	:= obj
BINDIR	:= bin
SRCDIR  := kern
DEPDIR  := dep


MODULES   := init libs debug driver trap mm sync
SRC_DIR   := $(addprefix $(SRCDIR)/,$(MODULES))
BUILD_DIR := $(addprefix $(OBJDIR)/,$(MODULES))
DEP_DIR   := $(addprefix $(DEPDIR)/,$(MODULES))
VPATH     += $(SRC_DIR)

SRC       := $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
OBJ       := $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(SRC))
ASMSRC    := $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.S))
OBJ       += $(patsubst $(SRCDIR)/%.S, $(OBJDIR)/%.o, $(ASMSRC))
INCLUDES  := $(addprefix -I,$(SRC_DIR))
INCLUDES  += -I$(SRCDIR)/include

DEPENDS := $(patsubst $(SRCDIR)/%.c, $(DEPDIR)/%.d, $(SRC))

MAKEDEPEND = $(CLANG) -M $(CFLAGS) $(INCLUDES) -o $(DEPDIR)/$*.d $<
#vpath %.c $(SRC_DIR)
#vpath %.S $(SRC_DIR)

.PHONY: all checkdirs clean 

all: checkdirs obj/ucore-kernel

$(shell mkdir -p $(DEP_DIR))


obj/ucore-kernel:   $(OBJ) tools/kernel.ld
	@echo LINK
	$(LD) -nostdlib -n -G 0 -static -T tools/kernel.ld $(OBJ) -o $@

$(DEPDIR)/%.d: $(SRCDIR)/%.c
	@echo DEP $<
	@set -e; rm -f $@; \
		$(CLANG) -MM -MT "$(OBJDIR)/$*.o $@" $(CFLAGS) $(INCLUDES) $< > $@; 

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	/opt/CodeSourcery/Sourcery_CodeBench_Lite_for_MIPS_ELF/bin/mips-sde-elf-gcc -c -EL -G0 $(INCLUDES) $(CFLAGS)  $<  -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.S
	$(CLANG) $(INCLUDES) -D__ASSEMBLY__ -E $< | $(AS) -o $@

checkdirs: $(BUILD_DIR) $(DEP_DIR)

$(BUILD_DIR):
	@mkdir -p $@

$(DEP_DIR):
	@mkdir -p $@

clean:
	-rm -rf $(BUILD_DIR)
	-rm -rf $(DEPDIR)


ifneq ($(MAKECMDGOALS),clean)
-include $(DEPENDS)
endif




