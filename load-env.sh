#!/bin/bash

# Load environment variables from .env file
if [ -f "${SRCROOT}/.env" ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' "${SRCROOT}/.env" | xargs)
    echo "Environment variables loaded successfully"
else
    echo "Warning: .env file not found at ${SRCROOT}/.env"
    echo "Make sure to create a .env file with your API keys"
fi
