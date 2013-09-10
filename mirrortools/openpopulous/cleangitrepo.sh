set -e

git filter-branch --force --prune-empty --tree-filter 'if [ -e trunk ]; then git ls-tree --name-only $GIT_COMMIT trunk/ | grep '^trunk/' | xargs -I files mv files . && rmdir trunk; fi' --tag-name-filter cat -- --all

UNWANTED=""
UNWANTED="$UNWANTED objs/*"
UNWANTED="$UNWANTED bin/*.pdb bin/*.exe bin/*.dll bin/*.ilk"
UNWANTED="$UNWANTED projects/*.suo.old projects/*.sdf projects/*.ncb"
UNWANTED="$UNWANTED projects/*.suo projects/*.dll"
git filter-branch --force --index-filter "git rm -r --cached --ignore-unmatch $UNWANTED"  --prune-empty --tag-name-filter cat -- --all
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now
# Don't know why I need to do this twice...
git filter-branch --force --index-filter "git rm -r --cached --ignore-unmatch $UNWANTED"  --prune-empty --tag-name-filter cat -- --all
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now
