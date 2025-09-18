#!/usr/bin/env python3
"""
Validate Home Assistant Addon YAML files
"""

import yaml
import json
import sys
import os

def validate_yaml(filepath):
    """Validate a YAML file"""
    try:
        with open(filepath, 'r') as f:
            data = yaml.safe_load(f)
        print(f"✓ {filepath} - Valid YAML")
        return True, data
    except FileNotFoundError:
        print(f"✗ {filepath} - File not found")
        return False, None
    except yaml.YAMLError as e:
        print(f"✗ {filepath} - YAML Error:")
        print(f"  {e}")
        return False, None
    except Exception as e:
        print(f"✗ {filepath} - Error: {e}")
        return False, None

def check_addon_structure():
    """Check if the addon structure is valid"""
    print("Home Assistant Addon Structure Validation")
    print("=" * 50)
    
    # Check repository file
    print("\n1. Repository File:")
    repo_valid = False
    if os.path.exists("repository.yaml"):
        repo_valid, repo_data = validate_yaml("repository.yaml")
        if repo_valid and repo_data:
            print(f"  - Name: {repo_data.get('name', 'Not set')}")
            print(f"  - URL: {repo_data.get('url', 'Not set')}")
    elif os.path.exists("repository.json"):
        try:
            with open("repository.json", 'r') as f:
                repo_data = json.load(f)
            print("✓ repository.json - Valid JSON")
            repo_valid = True
        except Exception as e:
            print(f"✗ repository.json - Error: {e}")
    else:
        print("✗ No repository.yaml or repository.json found")
    
    # Check addon directory
    print("\n2. Addon Directory:")
    addon_dir = "nut"
    if not os.path.isdir(addon_dir):
        print(f"✗ Addon directory '{addon_dir}' not found")
        return False
    print(f"✓ Addon directory '{addon_dir}' exists")
    
    # Check required files
    print("\n3. Required Files:")
    required_files = {
        f"{addon_dir}/config.yaml": "Addon configuration",
        f"{addon_dir}/Dockerfile": "Docker build file",
        f"{addon_dir}/README.md": "Addon documentation"
    }
    
    all_valid = True
    for filepath, description in required_files.items():
        if os.path.exists(filepath):
            if filepath.endswith('.yaml'):
                valid, data = validate_yaml(filepath)
                if valid and filepath.endswith('config.yaml'):
                    print(f"  - Name: {data.get('name', 'Not set')}")
                    print(f"  - Version: {data.get('version', 'Not set')}")
                    print(f"  - Slug: {data.get('slug', 'Not set')}")
                all_valid = all_valid and valid
            else:
                print(f"✓ {filepath} - {description}")
        else:
            print(f"✗ {filepath} - Missing {description}")
            all_valid = False
    
    # Check optional files
    print("\n4. Optional Files:")
    optional_files = {
        f"{addon_dir}/DOCS.md": "Extended documentation",
        f"{addon_dir}/icon.png": "Addon icon",
        f"{addon_dir}/logo.png": "Addon logo",
        f"{addon_dir}/build.yaml": "Build configuration"
    }
    
    for filepath, description in optional_files.items():
        if os.path.exists(filepath):
            print(f"✓ {filepath} - {description}")
        else:
            print(f"- {filepath} - {description} (optional)")
    
    # Check config.yaml structure
    print("\n5. Config.yaml Structure:")
    config_path = f"{addon_dir}/config.yaml"
    if os.path.exists(config_path):
        valid, config_data = validate_yaml(config_path)
        if valid and config_data:
            # Check for required fields
            required_fields = ['name', 'version', 'slug', 'description', 'arch']
            for field in required_fields:
                if field in config_data:
                    print(f"  ✓ {field}: {config_data[field]}")
                else:
                    print(f"  ✗ Missing required field: {field}")
                    all_valid = False
            
            # Check options for comments (which would make it invalid)
            if 'options' in config_data:
                options_str = str(config_data['options'])
                if '#' in options_str:
                    print("  ⚠ Warning: Options may contain comments")
    
    # Final result
    print("\n" + "=" * 50)
    if all_valid and repo_valid:
        print("✅ Addon structure appears valid!")
        print("\nNext steps:")
        print("1. Copy to Home Assistant: /config/addons/")
        print("2. Reload addon store in Home Assistant")
        print("3. Look for addon under 'Local add-ons'")
    else:
        print("❌ Addon structure has issues - see above")
    
    return all_valid and repo_valid

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)) or '.')
    success = check_addon_structure()
    sys.exit(0 if success else 1)
