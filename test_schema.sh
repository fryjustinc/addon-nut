#!/bin/bash

echo "Testing Home Assistant Addon Schema Fix"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test YAML validity
echo "1. Testing YAML validity..."
python3 -c "
import yaml
import sys

try:
    with open('nut/config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    print('   ${GREEN}✓ config.yaml is valid YAML${NC}')
    
    # Check schema section
    if 'schema' in config:
        schema = config['schema']
        
        # Check if powerman uses flat structure
        if 'powerman_enabled' in schema:
            print('   ${GREEN}✓ PowerMan uses flat structure (GOOD)${NC}')
        elif 'powerman' in schema and isinstance(schema['powerman'], dict):
            if 'devices' in schema['powerman']:
                print('   ${RED}✗ PowerMan uses nested structure (BAD)${NC}')
                print('   ${RED}  This will cause supervisor errors!${NC}')
                sys.exit(1)
        
        # List all PowerMan fields
        powerman_fields = [k for k in schema.keys() if k.startswith('powerman_')]
        if powerman_fields:
            print(f'   Found PowerMan fields: {powerman_fields}')
    
except yaml.YAMLError as e:
    print(f'   ${RED}✗ YAML Error: {e}${NC}')
    sys.exit(1)
except Exception as e:
    print(f'   ${RED}✗ Error: {e}${NC}')
    sys.exit(1)
" | sed "s/\${GREEN}/$GREEN/g" | sed "s/\${RED}/$RED/g" | sed "s/\${NC}/$NC/g"

echo ""
echo "2. Checking required files..."
FILES=("repository.yaml" "nut/config.yaml" "nut/Dockerfile" "nut/README.md")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${GREEN}✓ $file exists${NC}"
    else
        echo -e "   ${RED}✗ $file missing${NC}"
    fi
done

echo ""
echo "3. Quick Schema Check..."
grep -q "powerman_enabled: bool?" nut/config.yaml
if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✓ Flat PowerMan schema found${NC}"
else
    echo -e "   ${YELLOW}⚠ PowerMan schema may need checking${NC}"
fi

echo ""
echo "========================================"
echo "Next steps:"
echo "1. Copy to Home Assistant: scp -r nut/* root@homeassistant.local:/config/addons/nut/"
echo "2. Reload addon store: ha addons reload"
echo "3. Check supervisor logs: docker logs hassio_supervisor 2>&1 | grep nut"
echo ""
