# Git Worktrees Guide for Format Finder

## What are Git Worktrees?

Git worktrees allow you to have multiple branches checked out simultaneously in different directories. This is incredibly useful when you need to:
- Work on a feature while reviewing a PR
- Quickly fix a bug without stashing your current work
- Compare code between branches side-by-side
- Run different versions of your app simultaneously

## Current Setup

Your repository is located at:
```
/Users/connormurphy/Desktop/Format Finder
```

## Setting Up Worktrees

### Step 1: Navigate to your main repository
```bash
cd "/Users/connormurphy/Desktop/Format Finder"
```

### Step 2: Check existing worktrees
```bash
git worktree list
```

### Step 3: Create a feature development worktree
```bash
# Creates a new worktree in ../feature-dev with a new branch
git worktree add -b feature/new-scoring ../feature-dev

# Or checkout an existing branch
git worktree add ../feature-dev feature/existing-branch
```

### Step 4: Create a bugfix worktree
```bash
git worktree add -b bugfix/navigation-fixes ../bugfix
```

### Step 5: Create an experimental worktree
```bash
git worktree add -b experimental/ai-features ../experimental
```

## Directory Structure After Setup

```
Format Finder/            # Main repository (current branch)
├── FormatFinder.xcodeproj
├── FormatFinder/
└── README.md

Format Finder-feature/    # Feature development worktree
├── FormatFinder.xcodeproj
├── FormatFinder/
└── README.md

Format Finder-bugfix/     # Bug fixes worktree
├── FormatFinder.xcodeproj
├── FormatFinder/
└── README.md

Format Finder-experimental/  # Experimental features worktree
├── FormatFinder.xcodeproj
├── FormatFinder/
└── README.md
```

## Using Worktrees Effectively

### 1. Switch Between Worktrees
```bash
# Simply navigate to different directories
cd ../feature-dev    # Work on features
cd ../bugfix         # Fix bugs
cd ../main           # Stable code
```

### 2. Each Worktree is Independent
- Different branches checked out simultaneously
- Separate build artifacts
- Independent git status
- Can run multiple versions of your app

### 3. Common Workflow Example

```bash
# In main worktree - stable code
cd "/Users/connormurphy/Desktop/Format Finder"
git pull origin main

# Start a new feature in feature-dev worktree
cd "../Format Finder-feature"
git checkout -b feature/tournament-brackets
# Make changes, test, commit

# Urgent bug reported! Switch to bugfix worktree
cd "../Format Finder-bugfix"
git checkout -b bugfix/score-calculation
# Fix bug, test, commit, push

# Continue with feature - no stashing needed!
cd "../Format Finder-feature"
# Your feature work is exactly where you left it
```

### 4. Worktree Management Commands

```bash
# List all worktrees
git worktree list

# Add a new worktree
git worktree add <path> <branch>

# Remove a worktree
git worktree remove <path>

# Clean up deleted worktrees
git worktree prune

# Lock a worktree (prevent deletion)
git worktree lock <path>

# Unlock a worktree
git worktree unlock <path>
```

## Best Practices

1. **Naming Convention**: Use descriptive paths that match branch purposes
   - `../feature-dev` for feature branches
   - `../bugfix` for bug fixes
   - `../hotfix` for urgent production fixes
   - `../experimental` for trying new ideas

2. **Keep Main Clean**: Always keep your main worktree on the stable branch

3. **Regular Cleanup**: Use `git worktree prune` to clean up deleted worktrees

4. **Xcode Projects**: Each worktree has its own derived data, so builds won't conflict

5. **Branch Switching**: You can change branches within a worktree using normal git commands:
   ```bash
   cd ../feature-dev
   git checkout feature/another-feature
   ```

## Practical Examples for Format Finder

### Example 1: Adding a New Game Format
```bash
cd "../Format Finder-feature"
git checkout -b feature/add-vegas-format
# Edit FormatFinder/Resources/formats.json
# Add new SVG images
# Test in Xcode
git add .
git commit -m "feat: Add Vegas format with betting rules"
git push origin feature/add-vegas-format
```

### Example 2: Fixing Score Tracking Bug
```bash
cd "../Format Finder-bugfix"
git checkout -b bugfix/stableford-points
# Fix the calculation in ScoreTracking.swift
# Run tests
git add .
git commit -m "fix: Correct Stableford points calculation"
git push origin bugfix/stableford-points
```

### Example 3: Experimenting with AI Features
```bash
cd "../Format Finder-experimental"
git checkout -b experimental/ai-recommendations
# Add AI-powered format recommendations
# This might break things - that's OK in experimental!
# If it works, cherry-pick to feature branch
```

## Troubleshooting

### Issue: "fatal: '<branch>' is already checked out"
**Solution**: You can't have the same branch in multiple worktrees. Use different branches or create a new branch.

### Issue: Worktree directory already exists
**Solution**: Remove the directory first or use a different path:
```bash
rm -rf ../feature-dev
git worktree add ../feature-dev feature/branch
```

### Issue: Can't delete a worktree
**Solution**: Make sure you're not currently in that worktree directory:
```bash
cd ../main
git worktree remove ../feature-dev
```

## Quick Setup Script

Save this as `setup-worktrees.sh` and run it:

```bash
#!/bin/bash
cd "/Users/connormurphy/Desktop/Format Finder"

# Create feature development worktree
if [ ! -d "../Format Finder-feature" ]; then
    git worktree add -b feature/development "../Format Finder-feature"
    echo "Created Format Finder-feature worktree"
fi

# Create bugfix worktree
if [ ! -d "../Format Finder-bugfix" ]; then
    git worktree add -b bugfix/fixes "../Format Finder-bugfix"
    echo "Created Format Finder-bugfix worktree"
fi

# Create experimental worktree
if [ ! -d "../Format Finder-experimental" ]; then
    git worktree add -b experimental/features "../Format Finder-experimental"
    echo "Created Format Finder-experimental worktree"
fi

echo "Worktrees setup complete!"
git worktree list
```

## Summary

Git worktrees are perfect for:
- 🚀 Parallel development without stashing
- 🐛 Quick bug fixes without disrupting features
- 🔬 Experimenting without affecting stable code
- 👀 Comparing implementations side-by-side
- 🏗️ Building different versions simultaneously

Now you can work on multiple aspects of Format Finder without the constant context switching of stashing and checking out different branches!