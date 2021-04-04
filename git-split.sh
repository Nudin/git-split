#!/usr/bin/env bash

set -e

trap abort TERM INT SEGV ABRT

abort() {
   echo -e "ERROR: SOMETHING WENT WRONG."
   if [[ "$original_hash" != "" ]]; then
      echo -e "revert to original_hash commit"
      git reset --hard "$original_hash"
   fi
   if [[ "$stash_commit" != "" ]]; then
      git stash apply "$stash_commit"
   fi
   exit 3
}

split_by_patch=false
autostash=false
for _ in 0 1; do
   if [[ "$1" = "--auto-stash" ]]; then
      autostash=true
      shift
   fi

   if [[ "$1" = "-p" ]]; then
      split_by_patch=true
      shift
   fi
done

if [[ "${#*}" != 1 ]]; then
   echo "Usage:"
   echo "git split [-p] [--auto-stash] <commit>"
   exit 1
fi

if $autostash; then
   stash_commit=$(git stash create)
   git reset -q --hard @
fi

if [[ "$(git status --porcelain --untracked-files=no | wc -l)" != 0 ]]; then
   echo "Can't split commit, work dir or stagging not clear"
   exit 2
fi

original_hash="$(git rev-parse --short @)"
original_abbrev="$(git rev-parse --abbrev-ref @)"
if [[ "$original_abbrev" == "HEAD" ]]; then
   original_abbrev="$original_hash"
fi
target_hash="$(git rev-parse --short "$1")"
message="$(git log --pretty=format:'%s' -n1 "$target_hash")"

echo "Split commit $target_hash ($message)"

git checkout -q "$target_hash"

git reset -q --soft HEAD^
status=$(git status --porcelain --untracked-files=no)
git reset -q HEAD

echo -e "$status" | while read -r status file _ new_file
do
   if [[ "$status" = "M" ]]; then
      if $split_by_patch; then
         count=1
         while [[ "$(git status --porcelain --untracked-files=no "$file" | wc -l)" != 0 ]]; do
            echo -e "y\nq" | git commit -n -p "$file" -m "$file: $message" > /dev/null
            if [[  "$(git status --porcelain --untracked-files=no "$file" | wc -l)" != 0 || $count -gt 1 ]]; then
               git commit --amend -m "$file~$count: $message"
            fi
            (( count++ ))
         done
      else
         git add "$file"
         git commit -n "$file" -m "$file: $message"
      fi
   elif [[ "$status" = "A" ]]; then
      git add "$file"
      git commit -n "$file" -m "added $file: $message"
   elif [[ "$status" = "D" ]]; then
      git rm "$file"
      git commit -n "$file" -m "removed $file: $message"
   elif [[ "$status" = "R" ]]; then
      git mv "$file" "$new_file"
      git commit -n "$file" -m "moved $new_file: $message"
   else
      echo "unknown status $file"
      exit 3
   fi
done

newbranch="$(git rev-parse HEAD)"

git checkout -q "$original_abbrev"
git rebase -q "$newbranch"

if [[ "$(git diff  "$original_hash")" != "" ]]; then
   abort
fi

if [[ "$stash_commit" != "" ]]; then
   git stash apply "$stash_commit"
fi
