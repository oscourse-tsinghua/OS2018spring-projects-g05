EMPTY	:=
SPACE	:= $(EMPTY) $(EMPTY)
SLASH	:= /

ON_FPGA :=y

V       := @

#GCCPREFIX:=mips-sde-elf-
GCCPREFIX ?= /home/guest/cpu/build-gcc/mips_gcc/bin/mips-sde-elf-

# eliminate default suffix rules
.SUFFIXES: .c .S .h

# define compiler and flags

HOSTCC		:= gcc
HOSTCFLAGS	:= -g -Wall -O2

GDB		:= $(GCCPREFIX)gdb

THUMIPSCC		:= ./thumips-cc
CLANG := clang
CC :=$(GCCPREFIX)gcc
CFLAGS	:=  -fno-builtin -nostdlib  -nostdinc -g  -EL -G0 -fno-delayed-branch -Wa,-O0
CTYPE	:= c S

LD      := $(GCCPREFIX)ld
AS      := $(GCCPREFIX)as -EL -g -mips32
AR      := $(GCCPREFIX)ar
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


MODULES   := init libs debug driver trap mm sync process schedule syscall fs fs/vfs fs/sfs fs/devs
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

ifeq  ($(ON_FPGA), y)
USER_APPLIST:= sh #ls 
INITRD_BLOCK_CNT:=300 
FPGA_LD_FLAGS += -S
MACH_DEF := -DMACH_FPGA
else
USER_APPLIST:= pwd cat sh ls forktest yield hello faultreadkernel faultread badarg waitkill pgdir exit sleep
# 2M
INITRD_BLOCK_CNT:=4000 
MACH_DEF := -DMACH_QEMU
endif

USER_SRCDIR := user
USER_OBJDIR := $(OBJDIR)/$(USER_SRCDIR)
USER_LIB_OBJDIR := $(USER_OBJDIR)/libs
USER_INCLUDE := -I$(USER_SRCDIR)/libs

USER_APP_BINS:= $(addprefix $(USER_OBJDIR)/, $(USER_APPLIST))

USER_LIB_SRCDIR := $(USER_SRCDIR)/libs
USER_LIB_SRC := $(foreach sdir,$(USER_LIB_SRCDIR),$(wildcard $(sdir)/*.c))
USER_LIB_OBJ := $(patsubst $(USER_LIB_SRCDIR)/%.c, $(USER_LIB_OBJDIR)/%.o, $(USER_LIB_SRC))
USER_LIB_OBJ += $(USER_LIB_OBJDIR)/initcode.o
USER_LIB    := $(USER_OBJDIR)/libuser.a

BUILD_DIR   += $(USER_LIB_OBJDIR)
BUILD_DIR   += $(USER_OBJDIR)


DEPENDS := $(patsubst $(SRCDIR)/%.c, $(DEPDIR)/%.d, $(SRC))

MAKEDEPEND = $(CLANG) -M $(CFLAGS) $(INCLUDES) -o $(DEPDIR)/$*.d $<
#vpath %.c $(SRC_DIR)
#vpath %.S $(SRC_DIR)

.PHONY: all checkdirs clean 

all: checkdirs boot/loader.bin obj/ucore-kernel-initrd

$(shell mkdir -p $(DEP_DIR))


obj/ucore-kernel:   $(OBJ) tools/kernel.ld
	@echo LINK $@
	$(LD) -nostdlib -n -G 0 -static -T tools/kernel.ld $(OBJ) -o $@

obj/ucore-kernel-piggy: $(BUILD_DIR)  $(OBJ) $(USER_APP_BINS) tools/kernel.ld
	@echo LINK $@
	$(LD) -nostdlib -n -G 0 -static -T tools/kernel.ld $(OBJ) \
					$(addsuffix .piggy.o, $(USER_APP_BINS)) -o $@

$(DEPDIR)/%.d: $(SRCDIR)/%.c
	@echo DEP $<
	@set -e; rm -f $@; \
		$(CC) -MM -MT "$(OBJDIR)/$*.o $@" $(CFLAGS) $(INCLUDES) $< > $@; 

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) -c -mips1 $(INCLUDES) $(CFLAGS) $(MACH_DEF) $<  -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.S
	$(CC) -mips32 -c -D__ASSEMBLY__ $(MACH_DEF) $(INCLUDES) -g -EL -G0  $<  -o $@

checkdirs: $(BUILD_DIR) $(DEP_DIR)

$(BUILD_DIR):
	@mkdir -p $@

$(DEP_DIR):
	@mkdir -p $@

clean:
	-rm -rf $(BUILD_DIR)
	-rm -rf $(DEPDIR)
	-rm -rf boot/loader.o boot/loader boot/loader.bin


ifneq ($(MAKECMDGOALS),clean)
-include $(DEPENDS)
endif

#user lib

$(USER_LIB): $(BUILD_DIR) $(USER_LIB_OBJ)
	@echo "Building USERLIB"
	$(AR) rcs $@ $(USER_LIB_OBJ)

#user applications
define make-user-app
$1: $(BUILD_DIR) $(addsuffix .o,$1) $(USER_LIB)
	@echo LINK $$@
	$(LD) $(FPGA_LD_FLAGS) -T $(USER_LIB_SRCDIR)/user.ld  $(addsuffix .o,$1) $(USER_LIB) -o $$@
	$(SED) 's/$$$$FILE/$(notdir $1)/g' tools/piggy.S.in > $(USER_OBJDIR)/piggy.S
	$(AS) $(USER_OBJDIR)/piggy.S -o $$@.piggy.o
endef

$(foreach bdir,$(USER_APP_BINS),$(eval $(call make-user-app,$(bdir))))

$(USER_OBJDIR)/%.o: $(USER_SRCDIR)/%.c
	$(CC) -c -mips1  $(USER_INCLUDE) -I$(SRCDIR)/include $(CFLAGS)  $<  -o $@

$(USER_OBJDIR)/%.o: $(USER_SRCDIR)/%.S
	$(CC) -mips32 -c -D__ASSEMBLY__ $(USER_INCLUDE) -I$(SRCDIR)/include -g -EL -G0  $<  -o $@


# filesystem
TOOL_MKSFS := tools/mksfs
ROOTFS_DIR:= $(USER_OBJDIR)/rootfs
ROOTFS_IMG:= $(USER_OBJDIR)/initrd.img
$(TOOL_MKSFS): tools/mksfs.c
	$(HOSTCC) $(HOSTCFLAGS) -o $@ $^

$(OBJDIR)/ucore-kernel-initrd:  $(BUILD_DIR) $(TOOL_MKSFS) $(OBJ) $(USER_APP_BINS) tools/kernel.ld
	rm -rf $(ROOTFS_DIR) $(ROOTFS_IMG)
	mkdir $(ROOTFS_DIR)
	cp $(USER_APP_BINS) $(ROOTFS_DIR)
	cp -r $(USER_SRCDIR)/_archive/* $(ROOTFS_DIR)/
	dd if=/dev/zero of=$(ROOTFS_IMG) count=$(INITRD_BLOCK_CNT)
	#touch $(ROOTFS_IMG)
	$(TOOL_MKSFS) $(ROOTFS_IMG) $(ROOTFS_DIR)
	$(SED) 's%_FILE_%$(ROOTFS_IMG)%g' tools/initrd_piggy.S.in > $(USER_OBJDIR)/initrd_piggy.S
	$(AS) $(USER_OBJDIR)/initrd_piggy.S -o $(USER_OBJDIR)/initrd.img.o
	@echo LINK $@
	$(LD) $(FPGA_LD_FLAGS) -nostdlib -n -G 0 -static -T tools/kernel.ld $(OBJ) \
				 $(USER_OBJDIR)/initrd.img.o -o $@
	rm -rf $(ROOTFS_DIR)

boot/loader.bin: boot/bootasm.S
	$(CC) $(CFLAGS) -g -c -o boot/loader.o $^
	$(LD) -EL -n -G0 -Ttext 0xbfc00000 -o boot/loader boot/loader.o
	$(OBJCOPY) -O binary -j .text -S boot/loader $@
