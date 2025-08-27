# Format Finder Scripts

This directory contains all utility scripts for the Format Finder project.

## Directory Structure

```
scripts/
├── deployment/       # Scripts for building and deploying the app
├── xcode/           # Scripts for managing Xcode project files
└── utilities/       # General utility scripts
```

## Deployment Scripts (`deployment/`)

### deploy_to_phone.sh
Deploys the Format Finder app directly to a connected iPhone.
```bash
./scripts/deployment/deploy_to_phone.sh
```

### update_app.sh
Updates the app with new changes and rebuilds.
```bash
./scripts/deployment/update_app.sh
```

### run.sh
Quick script to run the app in development mode.
```bash
./scripts/deployment/run.sh
```

## Xcode Scripts (`xcode/`)

### fix_xcode_references.sh
Fixes file references when Xcode gets out of sync with the filesystem.
```bash
./scripts/xcode/fix_xcode_references.sh
```

### add_to_xcode.rb
Ruby script to programmatically add files to the Xcode project.
```bash
ruby scripts/xcode/add_to_xcode.rb
```

### add_theme_files.rb
Adds theme-related files to the Xcode project.
```bash
ruby scripts/xcode/add_theme_files.rb
```

### add_files_to_xcode.py
Python script for batch adding files to Xcode project.
```bash
python scripts/xcode/add_files_to_xcode.py
```

## Utility Scripts (`utilities/`)

### create_app_icon.py
Generates app icons in all required sizes for iOS.
```bash
python scripts/utilities/create_app_icon.py
```

## Usage

All scripts should be run from the project root directory:
```bash
cd "/Users/connormurphy/Desktop/Format Finder"
```

Most scripts are executable, but if you encounter permission issues:
```bash
chmod +x scripts/path/to/script.sh
```