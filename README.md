git-split – split an arbitrary commit
=====================================

Use case: You want to clean up your git history before pushing it and notice that one commit contains to many (unrelated) changes.

Installation:
Put into a directory in you PATH, for example:
```
cp git-split.sh ~/bin/git-split
chmod +x ~/bin/git-split
```

Usage:
```
git split [-p] [--auto-stash] <commit>

    -p             Split patch wise instead of file wise
    --auto-stash   Stash and unstash changes in the current working tree
```

Example:
Split the commit `abc1234` into multiple commits, so that each commit edits only one file:
```
$ git log --oneline --stat
3ec599e (HEAD -> main) weiter3
 [...]
abc1234 file3~2: Huge commit
 file1 | 2 +-
 file2 | 2 +-
 file3 | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)
9d3b901 Init
 [...]

$ git split abc1234

$ git log --oneline
3ec599e (HEAD -> main) weiter3
 [...]
ad5687a file3: Huge commit
 file3 | 2 +-
 1 files changed, 1 insertions(+), 1 deletions(-)
55d5d31 file2: Huge commit
 file2 | 2 +-
 1 files changed, 1 insertions(+), 1 deletions(-)
c27e7a1 file1: Huge commit
 file1 | 2 +-
 1 files changed, 1 insertions(+), 1 deletions(-)
9d3b901 Init
 [...]
```
