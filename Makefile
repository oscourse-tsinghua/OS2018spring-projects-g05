# Generate test files
# Please run this on Linux

TEST_SRC := $(shell find sim/source -type f)
TEST_TARGET = $(TEST_SRC:sim/source/%=sim/output/%)

test: $(TEST_TARGET)

.PHONY: test

sim/output/%: sim/source/%
	cd hard_tests_gen && python3 build.py -i ../$(dir $^) -o ../$(dir $@) -c $(notdir $^)
