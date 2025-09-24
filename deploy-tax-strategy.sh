#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please copy .env.example to .env and configure your values."
    exit 1
fi

# Load environment variables
source .env

# Check required environment variables
check_env_var() {
    if [ -z "$(eval echo \$$1)" ]; then
        print_error "Environment variable $1 is not set"
        exit 1
    fi
}

print_status "Checking environment variables..."
check_env_var "PRIVATE_KEY"

# Deployment function for Tax Strategy
deploy_tax_strategy_to_network() {
    local network=$1
    local network_name=$2
    
    print_status "Deploying TaxStrategy to $network_name..."
    
    # Run the deployment
    forge script script/DeployTaxStrategy.s.sol:DeployTaxStrategy \
        --rpc-url $network \
        --broadcast \
        --verify \
        -vvvv
    
    if [ $? -eq 0 ]; then
        print_success "Successfully deployed TaxStrategy to $network_name"
    else
        print_error "Failed to deploy TaxStrategy to $network_name"
        return 1
    fi
}

# Menu for network selection
echo "=============================================="
echo "Tax Strategy Deployment Script"
echo "=============================================="
echo "Contract: TaxStrategy.sol"
echo "Owner: Deployer address (from private key)"
echo "=============================================="
echo "1) Deploy to BNB Smart Chain Mainnet"
echo "2) Deploy to Base Mainnet"
echo "3) Deploy to BNB Testnet"
echo "4) Deploy to all networks"
echo "5) Exit"
echo "=============================================="

read -p "Select an option (1-5): " choice

case $choice in
    1)
        check_env_var "BNB_RPC_URL"
        deploy_tax_strategy_to_network "bnb" "BNB Smart Chain Mainnet"
        ;;
    2)
        check_env_var "BASE_RPC_URL"
        deploy_tax_strategy_to_network "base" "Base Mainnet"
        ;;
    3)
        check_env_var "BNB_TESTNET_RPC_URL"
        deploy_tax_strategy_to_network "bnb_testnet" "BNB Testnet"
        ;;
    4)
        print_status "Deploying Tax Strategy to all networks..."
        
        # Check all required variables
        check_env_var "BNB_RPC_URL"
        check_env_var "BASE_RPC_URL"
        check_env_var "BNB_TESTNET_RPC_URL"
        
        # Deploy to BNB Testnet first (safer for testing)
        deploy_tax_strategy_to_network "bnb_testnet" "BNB Testnet"
        
        # Deploy to mainnets
        deploy_tax_strategy_to_network "bnb" "BNB Smart Chain Mainnet"
        deploy_tax_strategy_to_network "base" "Base Mainnet"
        
        print_success "All Tax Strategy deployments completed!"
        ;;
    5)
        print_status "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid option. Please select 1-5."
        exit 1
        ;;
esac

print_status "Tax Strategy deployment script completed."