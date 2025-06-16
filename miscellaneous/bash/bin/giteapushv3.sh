#!/bin/bash
# Genesis Radio Git Auto-Push
# With Auto-Retry if Push Fails

# Move to the top of the git repo automatically
cd "$(git rev-parse --show-toplevel)" || { echo "❌ Not inside a Git repo. Exiting."; exit 1; }

# Log the current location
echo "📂 Working in $(pwd)"

# Stage all changes (new, modified, deleted)
git add -A

# Check if there's anything to commit
if ! git diff --cached --quiet; then
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    git commit -m "Auto-commit from giteapush.sh at $TIMESTAMP"
    
    echo "📡 Attempting to push to origin/main..."
    
    # Push with retry up to 3 times
    tries=0
    max_tries=3
    until git push origin main; do
        tries=$((tries+1))
        if [ "$tries" -ge "$max_tries" ]; then
            echo "❌ Push failed after $max_tries attempts. Manual intervention needed."
            exit 1
        fi
        echo "⚠️ Push failed. Retrying ($tries/$max_tries) in 5 seconds..."
        sleep 5
    done

    echo "✅ Changes committed and pushed successfully at $TIMESTAMP"
else
    echo "ℹ️ No changes to commit."
fi

# Always show repo status at the end
echo "📋 Repo status:"
git status -sb
