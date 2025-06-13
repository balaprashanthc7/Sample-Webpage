#!/bin/bash

# This script installs the correct post-commit Git hook into the current repository.
# Usage: Run this script from the root of your Git repository: ./install_setup.sh

HOOKS_DIR=".git/hooks"
POST_COMMIT_FILE="$HOOKS_DIR/post-commit"

# --- Main Logic ---

# Check if we are in a Git repository
if [ ! -d .git ]; then
    echo "Failure"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR" || { echo "Failure"; exit 1; }

# Content of the CORRECTED post-commit script (no extra echoes)
# Note: Single quotes for the entire content, then escaped inner single quotes.
# This ensures that variables within the post-commit script are evaluated when it RUNS, not when it's written.
POST_COMMIT_SCRIPT_CONTENT='#!/bin/bash

# Automatically send commit data to blockchain backend
# This hook identifies the project by sending its Git remote URL to the backend.

# CONFIGURATION
BACKEND_URL="http://127.0.0.1:5000/git_hook_commits"

# GATHER GIT REPOSITORY URL
# Get the URL of the '\''origin'\'' remote.
# If no remote URL, use the local path of the repository.
REPO_URL=$(git config --get remote.origin.url)
if [ -z "$REPO_URL" ]; then
    REPO_PATH=$(git rev-parse --show-toplevel)
    # Convert backslashes to forward slashes for consistency if on Windows
    REPO_URL="file://$(echo "$REPO_PATH" | sed '\''s/\\\\/\//g'\'')"
fi

# GATHER COMMIT DATA
COMMIT_MSG=$(git log -1 --pretty=%B | head -n 1) # First line of commit message
AUTHOR=$(git log -1 --pretty=%an) # Author name from Git
TIMESTAMP=$(git log -1 --pretty=%at) # Unix timestamp from Git
COMMIT_HASH=$(git rev-parse HEAD) # Full commit hash

# Send commit data to the Flask backend using curl
# -s : Silent mode, prevents curl from showing progress meter or error messages.
# -X POST : Specifies POST request.
# -H "Content-Type: application/json" : Sets the content type header.
# -d : Sends data as POST body.
# & : Runs the curl command in the background so git commit finishes immediately.
curl -s -X POST \
     -H "Content-Type: application/json" \
     -d "{\"message\": \"${COMMIT_MSG}\", \"author\": \"${AUTHOR}\", \"timestamp\": ${TIMESTAMP}, \"gitHash\": \"${COMMIT_HASH}\", \"repoUrl\": \"${REPO_URL}\"}" \
     "${BACKEND_URL}" &
'

# Write the post-commit script to the file
printf "%s" "$POST_COMMIT_SCRIPT_CONTENT" > "$POST_COMMIT_FILE" || { echo "Failure"; exit 1; }

# Make the script executable
chmod +x "$POST_COMMIT_FILE" || { echo "Failure"; exit 1; }

# Verify installation
if [ -f "$POST_COMMIT_FILE" ] && [ -x "$POST_COMMIT_FILE" ]; then
    echo "Success"
else
    echo "Failure"
fi
