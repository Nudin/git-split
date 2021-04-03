#!/usr/bin/env bash

# TODO:
## TRAP
## --auto-stash
## -p

if [ "${#*}" != 1 ]; then
   echo "Usage:"
   echo "git split <commit>"
   exit 1
fi

if [ "$(git status --porcelain --untracked-files=no | wc -l)" != 0 ]; then
   echo "Can't split commit, work dir or stagging not clear"
   exit 2
fi

original_hash="$(git rev-parse --short @)"
original_abbrev="$(git rev-parse --abbrev-ref @)"
if [ "$original_abbrev" == "HEAD" ]; then
   original_abbrev="$original_hash"
fi
target_hash="$(git rev-parse --short "$1")"
message="$(git log --pretty=format:'%s' -n1 "$target_hash")"

echo "Split commit $target_hash ($message)"

git checkout -q "$target_hash"

if [ "$(git status --porcelain --untracked-files=no | wc -l)" = 0 ]
then
   git reset --soft HEAD^  # removing --soft works perfectly fine?
fi

git status --porcelain --untracked-files=no | while read -r status file _ new_file
do
   if [ "$status" = "M" ]
   then
      git add "$file"
      git commit -n "$file" -m "$file: $message"
   elif [ "$status" = "A" ]
   then
      git add "$file"
      git commit -n "$file" -m "added $file: $message"
   elif [ "$status" = "D" ]
   then
      git rm "$file"
      git commit -n "$file" -m "removed $file: $message"
   elif [ "$status" = "R" ]
   then
      git mv "$file" "$new_file"
      git commit -n "$file" -m "moved $new_file: $message"
   # TODO: Add C
   else
      echo "unknown status $file"
      exit 3
   fi
done

newbranch="$(git rev-parse HEAD)"

git checkout -q "$original_abbrev"
git rebase -q "$newbranch"

if [ "$(git diff  "$original_hash")" != "" ]; then
   echo -e "ERROR: SOMETHING WENT WRONG."
   echo -e "revert to original_hash commit"
   git reset --hard "$original_hash"
   exit 3
fi
