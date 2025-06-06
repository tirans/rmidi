# R2MIDI Apple Store Setup - Quick Start Guide

## 🚀 Two-Phase Setup System

This project now includes an improved two-phase setup system for Apple Store signed app releases that separates manual tasks from automated processing.

### Why Two Phases?

- **Phase 1**: Manual setup (download certificates, create API keys)
- **Phase 2**: Automated processing (install certificates, create GitHub secrets)

This approach keeps sensitive files local and automates the complex parts.

## 📋 Prerequisites

- macOS machine with Xcode Command Line Tools
- Active Apple Developer Program membership ($99/year)
- GitHub repository admin access
- Python 3.10+

## 🏁 Quick Start

### Step 1: Install Dependencies
```bash
cd /Users/tirane/Desktop/r2midi
pip install -r scripts/requirements.txt
```

### Step 2: Run Phase 1 (Setup Structure)
```bash
python scripts/setup_apple_store.py phase1
```

This creates:
- Local `apple_credentials/` folder (git-ignored)
- Configuration template
- Detailed setup instructions
- Opens folder in Finder

### Step 3: Complete Manual Tasks

Follow the instructions in `apple_credentials/README.md`:

1. **Apple Developer Account**
   - Join Apple Developer Program
   - Get your Team ID
   - Create app-specific password

2. **Download Certificates**
   - Developer ID Application certificate
   - 3rd Party Mac Developer Application certificate
   - 3rd Party Mac Developer Installer certificate
   - Place all .cer files in `apple_credentials/certificates/`

3. **App Store Connect API Key**
   - Create API key with "Developer" role
   - Download .p8 file (can't download again!)
   - Place in `apple_credentials/app_store_connect/`

4. **GitHub Personal Access Token**
   - Create token with `repo` scope
   - Copy the token

5. **Update Configuration**
   - Edit `apple_credentials/config/app_config.json`
   - Fill in all your information

### Step 4: Run Phase 2 (Automated Processing)
```bash
python scripts/setup_apple_store.py phase2
```

This automatically:
- ✅ Installs certificates to Keychain
- ✅ Exports and encodes certificates
- ✅ Processes App Store Connect API key
- ✅ Creates all GitHub secrets via API
- ✅ Cleans up temporary files

### Step 5: Test the Workflow
```bash
git add .
git commit -m "Enable Apple Store signed releases"
git push origin master
```

## 📁 Local File Structure

After phase 1, you'll have:
```
apple_credentials/          # Git-ignored, local only
├── certificates/          # Place .cer files here
├── app_store_connect/     # Place .p8 files here
├── config/
│   └── app_config.json   # Your configuration
├── temp/                 # Temporary processing files
├── .gitignore           # Protects sensitive files
└── README.md            # Detailed instructions
```

## 🔒 Security Features

- ✅ **Local-only credentials**: Never committed to git
- ✅ **Encrypted GitHub secrets**: Properly encrypted via API
- ✅ **Automatic cleanup**: Temporary files removed
- ✅ **Standard passwords**: Consistent for automation

## 🎯 What You Get

After setup, every push to master automatically creates:
- **Signed macOS apps**: No security warnings
- **Notarized macOS apps**: Apple-approved
- **App Store packages**: Ready for submission
- **Professional releases**: For all platforms

## 🐛 Troubleshooting

### "PyNaCl not installed"
```bash
pip install PyNaCl requests
```

### "Configuration file not found"
```bash
python scripts/setup_apple_store.py phase1
```

### "GitHub API failed"
- Check token has `repo` scope
- Verify repository name in config
- Ensure token is not expired

## 📚 More Information

- **Detailed Guide**: See the complete deployment guide artifacts
- **Original Script**: `scripts/setup_github_secrets.py` (backup)
- **Certificate Manager**: `scripts/certificate_manager.py` (helper)

## 🎉 Success!

Once setup is complete, you'll have fully automated Apple Store signed app releases with professional code signing across all platforms!
