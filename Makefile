# Linux Code Signing Toolkit 1.1 - Makefile
# Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

.PHONY: all clean install uninstall deps osslsigncode test

# Configuration
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share/codesign-toolkit
VERSION = 1.1

# Build targets
all: deps codesign-toolkit

# Install dependencies and build osslsigncode
deps: check-deps
	@echo "Installing dependencies..."
	@if [ ! -d "osslsigncode" ]; then \
		git clone https://github.com/mtrojnar/osslsigncode.git; \
	fi
	@cd osslsigncode && \
	if [ ! -d "build" ]; then \
		mkdir build; \
	fi && \
	cd build && \
	cmake -S .. && \
	cmake --build . && \
	sudo cmake --install .

# Build the main toolkit
codesign-toolkit: codesign-toolkit.sh
	@echo "Building codesign-toolkit..."
	@chmod +x codesign-toolkit.sh
	@cp codesign-toolkit.sh codesign-toolkit

# Check if required dependencies are installed
check-deps:
	@echo "Checking dependencies..."
	@command -v cmake >/dev/null 2>&1 || { echo "cmake is required but not installed. Aborting." >&2; exit 1; }
	@command -v java >/dev/null 2>&1 || { echo "Java JDK is required but not installed. Aborting." >&2; exit 1; }
	@command -v javac >/dev/null 2>&1 || { echo "Java compiler is required but not installed. Aborting." >&2; exit 1; }

# Install the toolkit
install: all
	@echo "Installing codesign-toolkit to $(BINDIR)..."
	@sudo mkdir -p $(BINDIR)
	@sudo cp codesign-toolkit $(BINDIR)/
	@sudo mkdir -p $(DATADIR)
	@sudo cp -r scripts $(DATADIR)/
	@echo "Installation complete!"

# Uninstall the toolkit
uninstall:
	@echo "Uninstalling codesign-toolkit..."
	@sudo rm -f $(BINDIR)/codesign-toolkit
	@sudo rm -rf $(DATADIR)
	@echo "Uninstallation complete!"

# Run tests
test: all
	@echo "Running tests..."
	@./tests/run-tests.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f codesign-toolkit
	@rm -rf osslsigncode/build
	@echo "Clean complete!"

# Show help
help:
	@echo "Linux Code Signing Toolkit 1.1"
	@echo ""
	@echo "Available targets:"
	@echo "  all          - Build everything (default)"
	@echo "  deps         - Install dependencies and build osslsigncode"
	@echo "  install      - Install the toolkit to $(PREFIX)"
	@echo "  uninstall    - Remove the toolkit from $(PREFIX)"
	@echo "  test         - Run test suite"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help message"
