#!/bin/bash

# This script automates the installation of a post-commit Git hook.

# --- Configuration for the Installer Script ---
HOOK_FILENAME="post-commit"
GIT_HOOKS_DIR=".git/hooks"
INSTALL_PATH="${GIT_HOOKS_DIR}/${HOOK_FILENAME}"

# --- Content of the post-commit hook ---
# IMPORTANT: The PROJECT_ID is a placeholder here.
# You MUST manually change it in the installed script after running this installer.
read -r -d '' HOOK_CONTENT << 'EOF'
#!/bin/bash

# Automatically send commit data to blockchain backend
# This hook identifies the project by sending its Git remote URL to the backend.

# --- CONFIGURATION ---
BACKEND_URL="http://127.0.0.1:5000/git_hook_commits"

# MANUAL PROJECT IDENTIFIER
# IMPORTANT: Manually set the unique ID for this specific project/repository.
# This ID should correspond to how your backend identifies projects (e.g., "my-web-app", "backend-service", "docs-repo").
PROJECT_ID="300787" # <--- ADD YOUR PROJECT ID HERE

# --- GATHER COMMIT DATA ---
COMMIT_MSG=$(git log -1 --pretty=%s | sed 's/"/\\"/g') # First line of commit message, escape double quotes
AUTHOR=$(git log -1 --pretty=%an) # Author name from Git
TIMESTAMP=$(git log -1 --pretty=%at) # Unix timestamp from Git
COMMIT_HASH=$(git rev-parse HEAD) # Full commit hash

# --- PREPARE JSON PAYLOAD (Manual Concatenation) ---
# Escape any existing double quotes in the message to prevent JSON parsing issues.
# This is the most critical part for robustness without 'jq'.
ESCAPED_COMMIT_MSG=$(echo "$COMMIT_MSG" | sed 's/"/\\"/g')

JSON_PAYLOAD="{\"projectId\": \"${PROJECT_ID}\", \"message\": \"${ESCAPED_COMMIT_MSG}\", \"author\": \"${AUTHOR}\", \"timestamp\": ${TIMESTAMP}, \"gitHash\": \"${COMMIT_HASH}\"}"

# --- SEND DATA TO BACKEND ---
# Using curl to send the data.
# -sS: Silent but show errors.
# -X POST: Specify POST request.
# -H "Content-Type: application/json": Set the content type header.
# -d "${JSON_PAYLOAD}": Send the dynamically created JSON payload.
# --connect-timeout 5: Set a timeout for connection.
# --max-time 10: Set a max time for the whole operation.
# & : Run in the background to not block the Git operation.
curl -sS -X POST \
     -H "Content-Type: application/json" \
     -d "${JSON_PAYLOAD}" \
     --connect-timeout 5 \
     --max-time 10 \
     "${BACKEND_URL}" &
EOF

# --- Installation Logic ---

echo "Attempting to install Git ${HOOK_FILENAME} hook..."

# Check if we are inside a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a Git repository. Please navigate to your Git project directory."
    exit 1
fi

# Create the .git/hooks directory if it doesn't exist
if [ ! -d "${GIT_HOOKS_DIR}" ]; then
    echo "Creating directory: ${GIT_HOOKS_DIR}"
    mkdir -p "${GIT_HOOKS_DIR}"
    if [ $? -ne 0 ]; then
        echo "Error: Could not create ${GIT_HOOKS_DIR}. Check permissions."
        exit 1
    fi
fi

# Write the hook content to the file
echo "${HOOK_CONTENT}" > "${INSTALL_PATH}"
if [ $? -ne 0 ]; then
    echo "Error: Could not write hook content to ${INSTALL_PATH}. Check permissions."
    exit 1
fi

# Make the hook executable
chmod +x "${INSTALL_PATH}"
if [ $? -ne 0 ]; then
    echo "Error: Could not make ${INSTALL_PATH} executable. Check permissions."
    exit 1
fi

echo "Successfully installed ${HOOK_FILENAME} hook to: ${INSTALL_PATH}"
echo "---------------------------------------------------------"
echo "IMPORTANT: You need to manually edit the installed script to set your PROJECT_ID."
echo "Open the file: ${INSTALL_PATH}"
echo "Look for 'PROJECT_ID=\"your-project-id-here\"' and replace 'your-project-id-here' with your actual project ID."
echo "---------------------------------------------------------"
echo "The script will now run automatically after each 'git commit'."
