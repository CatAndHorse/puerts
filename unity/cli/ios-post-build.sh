#!/bin/bash

# iOS Post-Build Script
# Purpose: Merge static libraries and clean up unnecessary .meta files
# Usage: ./ios-post-build.sh <plugins_dir> <backend>

set -e

PLUGINS_DIR="$1"
BACKEND="$2"

if [ -z "$PLUGINS_DIR" ] || [ -z "$BACKEND" ]; then
    echo "Usage: $0 <plugins_dir> <backend>"
    echo "Example: $0 unity/Assets/core/upm/Plugins/iOS mult"
    exit 1
fi

echo "=== iOS Post-Build Processing ==="
echo "Plugins Directory: $PLUGINS_DIR"
echo "Backend: $BACKEND"

cd "$PLUGINS_DIR"

# Step 1: Merge static libraries for mult backend
if [ "$BACKEND" = "mult" ]; then
    echo ""
    echo "Step 1: Merging static libraries..."
    
    # Check if libraries exist
    if [ ! -f "libpuerts.a" ]; then
        echo "Error: libpuerts.a not found"
        exit 1
    fi
    
    # For mult backend, puerts.a already contains all backend code
    # We just need to rename it for clarity
    if [ -f "libv8backend.a" ] || [ -f "libqjsbackend.a" ]; then
        echo "Warning: Found separate backend libraries, but they should be merged into libpuerts.a"
        echo "Removing separate backend libraries..."
        rm -f libv8backend.a libqjsbackend.a
        rm -f libv8backend.a.meta libqjsbackend.a.meta
    fi
    
    echo "✓ Static libraries processed"
else
    echo ""
    echo "Step 1: Single backend mode, no merge needed"
fi

# Step 2: Clean up unnecessary .meta files
echo ""
echo "Step 2: Cleaning up unnecessary .meta files..."

# List of .meta files that should exist (corresponding to actual .a files)
VALID_LIBS=(
    "libpuerts.a"
    "libwee8.a"
)

# If mult backend, these are the only valid libraries
if [ "$BACKEND" = "mult" ]; then
    VALID_LIBS+=(
        # No additional libraries for mult backend
    )
fi

# Remove .meta files that don't have corresponding .a files
REMOVED_COUNT=0
for meta_file in *.meta; do
    if [ -f "$meta_file" ]; then
        lib_file="${meta_file%.meta}"
        
        # Check if this is a valid library
        is_valid=false
        for valid_lib in "${VALID_LIBS[@]}"; do
            if [ "$lib_file" = "$valid_lib" ]; then
                is_valid=true
                break
            fi
        done
        
        # If not valid and the .a file doesn't exist, remove the .meta
        if [ "$is_valid" = false ] && [ ! -f "$lib_file" ]; then
            echo "  Removing: $meta_file (no corresponding library)"
            rm -f "$meta_file"
            ((REMOVED_COUNT++))
        fi
    fi
done

echo "✓ Removed $REMOVED_COUNT unnecessary .meta files"

# Step 3: Summary
echo ""
echo "=== Build Summary ==="
echo "Final libraries:"
ls -lh *.a 2>/dev/null || echo "No .a files found"

echo ""
echo "Final .meta files:"
ls -1 *.meta 2>/dev/null || echo "No .meta files found"

echo ""
echo "=== Post-Build Processing Complete ==="
