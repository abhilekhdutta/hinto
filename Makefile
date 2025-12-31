.PHONY: setup build run clean kill log test format lint help

APP_NAME = Hinto
SCHEME = Hinto
BUILD_DIR = build
APP_PATH = $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app

setup:
	@echo "Setting up local development certificate..."
	@./Scripts/codesign/setup_local.sh
	@echo "Done. You can now run: make build"

build:
	@echo "Building $(APP_NAME)..."
	@xcodebuild -scheme $(SCHEME) -configuration Release -derivedDataPath $(BUILD_DIR) build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" || true

run: kill build
	@echo "Opening $(APP_NAME)..."
	@sleep 0.3
	@open $(APP_PATH)

kill:
	@pkill -9 $(APP_NAME) 2>/dev/null || true

clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR) .build
	@echo "Done."

log:
	@tail -f /tmp/hinto.log

test:
	@echo "Running tests..."
	@swift test 2>&1 | grep -E "(Test Case|passed|failed|error:)" || swift test

format:
	@swiftformat .

lint:
	@swiftformat --lint .

help:
	@echo "Usage:"
	@echo "  make setup  - Create local self-signed certificate (run once)"
	@echo "  make build  - Build the app"
	@echo "  make run    - Kill, build, and run the app"
	@echo "  make kill   - Kill running instance"
	@echo "  make clean  - Remove build directory"
	@echo "  make log    - Tail the log file"
	@echo "  make test   - Run unit tests"
	@echo "  make format - Format code with SwiftFormat"
	@echo "  make lint   - Check code formatting"
