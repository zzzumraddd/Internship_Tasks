#!/bin/bash

cleanup() {
    echo "Caught Ctrl+C (SIGINT), performing cleanup..."
    # Add your cleanup commands here
    echo "Cleanup finished."
    exit 0
}

# Trap the SIGINT signal
trap 'cleanup' SIGINT

echo "Process running. Press Ctrl+C to stop gracefully."
# Example long-running task
while true; do
    sleep 1
done
