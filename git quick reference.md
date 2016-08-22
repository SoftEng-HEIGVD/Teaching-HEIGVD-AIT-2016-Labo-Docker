### GIT Quick commands

#### Create a branch and checkout directly into it

```bash
git checkout -b <branch name>
```

Example:

```bash
git checkout -b task-1
```

#### Push the branch to the remote repository (GitHub)

If you just want to publish a branch and continue to track the branch, the first
time you push the branch on the remote, you have to add `-u` to the push
command.

```bash
git push -u origin <branch name>
```
Example:

```bash
git branch -u origin task-1
```

#### Push the updates (commits) to the remote repository (GitHub)

Once your branch is already tracked on the remote, you can simply do:

```bash
git push
```

#### Add your new / modified / removed files

When you have updates in your file system, you need to add them to git staging.
For that, you can do it for all the files with:

```bash
git add .
```

or you can specify file path by file path

```bash
git add <path1> <path2> ...
```

#### Commit your modifications

You will not be able to commit your changes if they are not staged. Once your
files are staged, you can simply commit your modifications with:

```bash
git commit -m "<message>"
```

Example:

```bash
git commit -m "Added run script"
```

#### Switch between branches

```bash
git checkout <branch name>
```

Example:

```
git checkout task-1
```

#### Retrieving modifications from the remote

To get the latest updates done on the remote branches, simply do:

```bash
git pull
```

#### Any git issue, ask us for help.
