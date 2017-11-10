# Generate test files
# Please run this on Linux

TEST_SRC := $(shell find sim/source -type f)
TEST_TARGET = $(TEST_SRC:sim/source/%=sim/output/%)

test: $(TEST_TARGET)

.PHONY: test

sim/output/%: sim/source/% hard_tests_gen/template/tb.vhd hard_tests_gen/template/fake_ram.vhd hard_tests_gen/template/test_const.vhd
	cd hard_tests_gen && python3 build.py -i ../$(dir $^) -o ../$(dir $@) -c $(notdir $^)
