# Installation Guide for Home Assistant

## Important Files Created

These files are required for Home Assistant to detect your addon:

1. ✅ **repository.yaml** - Created in root directory
2. ✅ **repository.json** - Created in root directory (backup)
3. ✅ **nut/README.md** - Created (was missing, only had .README.j2)
4. ✅ **nut/config.yaml** - Fixed (removed comments from options section)
5. ✅ **nut/Dockerfile** - Fixed (added symlink for powerman-pdu driver)

## Installation Methods

### Method 1: Direct Copy to Home Assistant (Recommended for Testing)

1. **SSH into your Home Assistant instance**

2. **Navigate to the addons directory:**
   ```bash
   cd /config/addons
   ```
   
3. **Clone or copy your repository:**
   ```bash
   # If you have git available:
   git clone https://github.com/yourusername/addon-nut.git nut
   
   # Or copy from your development machine:
   # On your Mac:
   cd ~/Dev/addon-nut
   scp -r . homeassistant.local:/config/addons/nut/
   ```

4. **In Home Assistant Web UI:**
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the **⋮** (three dots) menu in the top right
   - Click **Check for updates**
   - Click the **⋮** menu again
   - Click **Reload**
   - Look for "Network UPS Tools" under **Local add-ons**

### Method 2: Add as Repository

1. **Push your changes to GitHub:**
   ```bash
   cd ~/Dev/addon-nut
   git add .
   git commit -m "Fixed addon detection issues"
   git push origin main
   ```

2. **In Home Assistant:**
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the **⋮** (three dots) menu
   - Click **Repositories**
   - Add your repository URL: `https://github.com/yourusername/addon-nut`
   - Click **Add**
   - The addon should appear in the store

### Method 3: Using File Editor Addon

If you have the File Editor addon installed:

1. **In File Editor:**
   - Navigate to `/config/addons/`
   - Create a new folder called `nut`
   - Upload all files from your addon

2. **Reload the addon store** as in Method 1

## Troubleshooting Checklist

Run this command to verify your addon structure:

```bash
cd ~/Dev/addon-nut
chmod +x check_addon.sh
./check_addon.sh
```

### Required Files Checklist:
- [ ] `/repository.yaml` or `/repository.json` exists
- [ ] `/nut/config.yaml` exists and is valid YAML
- [ ] `/nut/Dockerfile` exists
- [ ] `/nut/README.md` exists
- [ ] No comments in the `options:` section of config.yaml
- [ ] Valid YAML syntax in all .yaml files

### If Still Not Detected:

1. **Check Home Assistant logs:**
   ```bash
   docker logs homeassistant 2>&1 | grep -i "addon\|repository"
   ```

2. **Clear browser cache** and reload the page

3. **Restart Home Assistant:**
   - Settings → System → Restart

4. **Check file permissions:**
   ```bash
   chmod -R 755 /config/addons/nut
   ```

5. **Validate YAML manually:**
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('nut/config.yaml'))"
   ```

## Test Configuration

Once installed, use this configuration to test with your APC PDU:

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_rack_pdu

powerman:
  enabled: true
  devices:
    - name: apc_rack_pdu
      type: apc
      host: 192.168.51.124
      username: apc
      password: apc
      nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: debug
```

## Common Issues and Fixes

1. **"Repository structure incorrect" error**
   - Missing `repository.yaml` - ✅ Fixed
   - Invalid directory structure - ✅ Verified correct

2. **"Invalid addon configuration"**
   - Comments in options section - ✅ Fixed
   - Invalid YAML syntax - ✅ Validated

3. **"Addon not found in repository"**
   - Missing README.md - ✅ Fixed (was .README.j2)
   - Missing config.yaml - ✅ Present

4. **Driver not found errors**
   - powerman-pdu path issue - ✅ Fixed with symlink

## Next Steps

1. Copy the addon to Home Assistant using Method 1
2. Reload the addon store
3. Install the addon
4. Configure it with your PDU settings
5. Start the addon and check logs
