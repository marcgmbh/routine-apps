#!/bin/bash

# Script to set up user-specific Xcode scheme with API keys
# This creates a local scheme that won't be committed to git

USER_SCHEME_DIR="routine-apps.xcodeproj/xcuserdata/$(whoami).xcuserdatad/xcschemes"
USER_SCHEME_FILE="$USER_SCHEME_DIR/routine-apps.xcscheme"
SHARED_SCHEME="routine-apps.xcodeproj/xcshareddata/xcschemes/routine-apps.xcscheme"

echo "Setting up user-specific Xcode scheme..."

# Create the user scheme directory if it doesn't exist
mkdir -p "$USER_SCHEME_DIR"

# Copy shared scheme to user scheme
cp "$SHARED_SCHEME" "$USER_SCHEME_FILE"

# Load environment variables from .env if it exists
if [ -f ".env" ]; then
    echo "Loading API keys from .env file..."
    source .env
    
    # Replace placeholders with actual values in user scheme
    sed -i '' "s/\$(REPLICATE_API_KEY)/$REPLICATE_API_KEY/g" "$USER_SCHEME_FILE"
    sed -i '' "s/\$(OPENROUTER_API_KEY)/$OPENROUTER_API_KEY/g" "$USER_SCHEME_FILE"
    
    echo "✅ User scheme created successfully with API keys!"
    echo "📁 Location: $USER_SCHEME_FILE"
    echo "🔒 This file is automatically ignored by git"
else
    echo "❌ .env file not found. Please create it with your API keys first."
    echo "Example .env content:"
    echo "REPLICATE_API_KEY=your_replicate_key_here"
    echo "OPENROUTER_API_KEY=your_openrouter_key_here"
    exit 1
fi
