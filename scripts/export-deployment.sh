#!/bin/bash
# Export deployment addresses and ABIs for frontend integration
# Usage: ./scripts/export-deployment.sh

set -e

echo "=== N6P Finance Base Sepolia Deployment Export ==="
echo ""

# Configuration
CHAIN_ID="84532"  # Base Sepolia
DEPLOYMENT_JSON="deployment.json"
ABI_DIR="abis"

# Create ABI directory if it doesn't exist
mkdir -p "$ABI_DIR"

echo "Extracting ABIs from compiled contracts..."

# Extract Registry ABI
echo "Extracting Registry ABI..."
jq '.abi' out/Registry.sol/Registry.json > "$ABI_DIR/Registry.json" 2>/dev/null || echo "Registry ABI not found"

# Extract Vault ABI
echo "Extracting Vault ABI..."
jq '.abi' out/VaultDeFi.sol/Vault.json > "$ABI_DIR/Vault.json" 2>/dev/null || echo "Vault ABI not found"

# Extract CommonFeeOracle ABI
echo "Extracting CommonFeeOracle ABI..."
jq '.abi' out/CommonFeeOracle.sol/CommonFeeOracle.json > "$ABI_DIR/CommonFeeOracle.json" 2>/dev/null || echo "CommonFeeOracle ABI not found"

# Extract BaseStrategy ABI
echo "Extracting BaseStrategy ABI..."
jq '.abi' out/BaseStrategy.sol/BaseStrategy.json > "$ABI_DIR/BaseStrategy.json" 2>/dev/null || echo "BaseStrategy ABI not found"

# Extract HealthCheckOverall ABI
echo "Extracting HealthCheckOverall ABI..."
jq '.abi' out/HealthCheckOverall.sol/HealthCheckOverall.json > "$ABI_DIR/HealthCheckOverall.json" 2>/dev/null || echo "HealthCheckOverall ABI not found"

echo ""
echo "✓ ABIs exported to $ABI_DIR/"
echo ""

# Generate deployment configuration JSON template
cat > "$DEPLOYMENT_JSON" << 'EOF'
{
  "chainId": 84532,
  "chainName": "Base Sepolia",
  "network": "base-sepolia",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "addresses": {
    "registry": "0x0000000000000000000000000000000000000000",
    "vaultDeFiImplementation": "0x0000000000000000000000000000000000000000",
    "vaultRWAImplementation": "0x0000000000000000000000000000000000000000",
    "feeOracle": "0x0000000000000000000000000000000000000000",
    "healthCheck": "0x0000000000000000000000000000000000000000",
    "baseStrategy": "0x0000000000000000000000000000000000000000"
  },
  "configuration": {
    "governance": "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
    "management": "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
    "guardian": "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
    "rewards": "0x005684ac7c737bff821eccb377cc46e5a7dcb60d"
  },
  "supportedTokens": [],
  "vaults": []
}
EOF

echo "✓ Deployment configuration template created: $DEPLOYMENT_JSON"
echo ""
echo "=== Instructions for Frontend Integration ==="
echo "1. Update $DEPLOYMENT_JSON with actual deployed addresses after running deployment"
echo "2. Add supported tokens and vault proxies to the vaults array"
echo "3. Copy $ABI_DIR to your frontend project"
echo "4. Import ABIs and configuration in your frontend code"
echo ""
