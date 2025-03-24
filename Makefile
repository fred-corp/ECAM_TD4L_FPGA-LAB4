# Variables
PROJECT_NAME = Robot
TOP_MODULE = top
VHDL_FILES = rtl/top/top.vhd rtl/uart_protocol/uart_protocol.vhd open-logic/src/base/vhdl/olo_base_pkg_attribute.vhd open-logic/src/base/vhdl/olo_base_pkg_logic.vhd open-logic/src/base/vhdl/olo_base_pkg_math.vhd open-logic/src/base/vhdl/olo_base_pkg_array.vhd open-logic/src/base/vhdl/olo_base_strobe_gen.vhd open-logic/src/base/vhdl/olo_base_reset_gen.vhd open-logic/src/intf/vhdl/olo_intf_uart.vhd open-logic/src/intf/vhdl/olo_intf_sync.vhd # open-logic/src/base/vhdl/olo_base_fifo_sync.vhd open-logic/src/base/vhdl/olo_base_ram_sdp.vhd
BUILD_DIR = build

# FPGA specific variables
FPGA_FAMILY = ice40
FPGA_DEVICE = up5k
FPGA_PACKAGE = sg48
FPGA_PINMAP = pinmap.pcf

all : bitstream flash

bitstream:
	@echo "Creating bitstream"
	mkdir -p $(BUILD_DIR)
	yosys -m ghdl -p 'ghdl $(VHDL_FILES) -e $(TOP_MODULE); synth_$(FPGA_FAMILY) -json $(BUILD_DIR)/$(PROJECT_NAME).json'
	nextpnr-$(FPGA_FAMILY) --$(FPGA_DEVICE) --package $(FPGA_PACKAGE) --pcf $(FPGA_PINMAP) --json $(BUILD_DIR)/$(PROJECT_NAME).json --asc $(BUILD_DIR)/$(PROJECT_NAME).asc
	icepack $(BUILD_DIR)/$(PROJECT_NAME).asc $(BUILD_DIR)/$(PROJECT_NAME)_bitstream.bin
	@echo "Done - bitstream location : \"$(BUILD_DIR)/$(PROJECT_NAME)_bitstream.bin\""

flash:
	@echo "Flashing bitstream"
	dfu-util --alt 0 --download $(BUILD_DIR)/$(PROJECT_NAME)_bitstream.bin --reset;

clean:
	@echo "Cleaning up build dir"
	@rm -rf $(BUILD_DIR)
	@echo "Done"

.PHONY: clean
