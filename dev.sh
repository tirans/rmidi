#!/bin/bash
# R2MIDI Development and Build Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    echo "R2MIDI Development and Build Script"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  test           - Run structure validation tests"
    echo "  server         - Run the server in development mode"
    echo "  client         - Run the client in development mode"
    echo "  build-all      - Build both server and client packages"
    echo "  build-server   - Build server package only"
    echo "  build-client   - Build client package only"
    echo "  clean          - Clean build artifacts"
    echo "  setup          - Initial project setup"
    echo "  help           - Show this help message"
    echo ""
    echo "Platform-specific builds:"
    echo "  build-macos    - Build for macOS"
    echo "  build-windows  - Build for Windows"
    echo "  build-linux    - Build for Linux"
}

# Test project structure
run_tests() {
    print_status "Running project structure tests..."
    python3 test_structure.py
    print_success "Tests completed"
}

# Run server in development mode
run_server() {
    print_status "Starting R2MIDI server in development mode..."
    python3 run.py
}

# Run client in development mode
run_client() {
    print_status "Starting R2MIDI client in development mode..."
    cd r2midi_client
    python3 main.py
    cd ..
}

# Build functions
build_server() {
    print_status "Building R2MIDI server..."
    briefcase create r2midi
    briefcase build r2midi
    briefcase package r2midi
    print_success "Server build completed"
}

build_client() {
    print_status "Building R2MIDI client..."
    briefcase create r2midi-client
    briefcase build r2midi-client
    briefcase package r2midi-client
    print_success "Client build completed"
}

build_all() {
    print_status "Building both server and client..."
    build_server
    build_client
    print_success "All builds completed"
}

# Platform-specific builds
build_macos() {
    print_status "Building for macOS..."
    briefcase package r2midi macOS
    briefcase package r2midi-client macOS
    print_success "macOS builds completed"
}

build_windows() {
    print_status "Building for Windows..."
    briefcase package r2midi windows
    briefcase package r2midi-client windows
    print_success "Windows builds completed"
}

build_linux() {
    print_status "Building for Linux..."
    briefcase package r2midi linux
    briefcase package r2midi-client linux
    print_success "Linux builds completed"
}

# Clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    if [ -d "build" ]; then
        rm -rf build/r2midi/*/app/
        rm -rf build/r2midi-client/*/app/
        print_success "Build artifacts cleaned"
    else
        print_warning "No build directory found"
    fi
}

# Initial project setup
setup_project() {
    print_status "Setting up R2MIDI project..."

    # Install briefcase if not already installed
    if ! command -v briefcase &> /dev/null; then
        print_status "Installing briefcase..."
        pip install briefcase
    fi

    # Install project dependencies
    print_status "Installing project dependencies..."
    pip install -r requirements.txt

    # Run initial test
    run_tests

    print_success "Project setup completed"
}

# Main script logic
case "${1:-help}" in
    test)
        run_tests
        ;;
    server)
        run_server
        ;;
    client)
        run_client
        ;;
    build-all)
        build_all
        ;;
    build-server)
        build_server
        ;;
    build-client)
        build_client
        ;;
    build-macos)
        build_macos
        ;;
    build-windows)
        build_windows
        ;;
    build-linux)
        build_linux
        ;;
    clean)
        clean_build
        ;;
    setup)
        setup_project
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
