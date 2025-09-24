#!/bin/bash

source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_header() {
    echo -e "${PURPLE}[DEPLOY]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please copy .env.example to .env and configure your values."
    exit 1
fi

# Load environment variables
source .env

# Function to run deployment scripts
run_deployment_script() {
    local script_name=$1
    local description=$2
    
    print_header "Running $description..."
    
    if [ -x "$script_name" ]; then
        ./$script_name
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            print_success "$description completed successfully"
        else
            print_error "$description failed with exit code $exit_code"
            return $exit_code
        fi
    else
        print_error "Script $script_name not found or not executable"
        return 1
    fi
}

# Display banner
echo "======================================================"
echo "🚀 ETF Strategy Contracts Deployment Suite"
echo "======================================================"
echo "Available contracts:"
echo "• CLTaxStrategyHook - PancakeSwap V4 Hook"
echo "• StrategyTokenSample - ERC20 Strategy Token"  
echo "• TaxStrategy - Fee Collection Contract"
echo "• Pool Creation - ETH/Token Pool with Hook"
echo "• Liquidity Addition - Add 0.1 BNB + 100k Tokens"
echo "======================================================"

# Menu for deployment selection
echo "1) Deploy CLTaxStrategyHook (Hook Contract)"
echo "2) Deploy StrategyTokenSample (ERC20 Token)"
echo "3) Deploy TaxStrategy (Fee Collection)"
echo "4) Deploy All Contracts (Full Suite)"
echo "5) Deploy Token + TaxStrategy (Treasury Setup)"
echo "6) Exit"
echo "======================================================"

read -p "Select deployment option (1-6): " choice

case $choice in
    1)
        print_header "Deploying CLTaxStrategyHook..."
        run_deployment_script "deploy.sh" "CLTaxStrategyHook Deployment"
        ;;
    2)
        print_header "Deploying StrategyTokenSample..."
        run_deployment_script "deploy-strategy-token.sh" "StrategyTokenSample Deployment"
        ;;
    3)
        print_header "Deploying TaxStrategy..."
        run_deployment_script "deploy-tax-strategy.sh" "TaxStrategy Deployment"
        ;;
    4)
        print_header "Deploying All Contracts..."
        print_status "This will deploy all three contracts in sequence:"
        print_status "1. TaxStrategy (Treasury)"
        print_status "2. StrategyTokenSample (Token)"
        print_status "3. CLTaxStrategyHook (Hook)"
        echo ""
        read -p "Continue with full deployment? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Deploy in logical order: Treasury -> Token -> Hook
            run_deployment_script "deploy-tax-strategy.sh" "TaxStrategy Deployment" &&
            run_deployment_script "deploy-strategy-token.sh" "StrategyTokenSample Deployment" &&
            run_deployment_script "deploy.sh" "CLTaxStrategyHook Deployment"
            
            if [ $? -eq 0 ]; then
                print_success "🎉 Full deployment suite completed successfully!"
                print_warning "📝 Remember to:"
                print_warning "   • Update your .env with deployed contract addresses"
                print_warning "   • Verify all contracts on block explorers"
                print_warning "   • Test the integration between contracts"
            fi
        else
            print_status "Full deployment cancelled."
        fi
        ;;
    5)
        print_header "Deploying Treasury Setup (Token + TaxStrategy)..."
        print_status "This will deploy:"
        print_status "1. TaxStrategy (Treasury for collecting fees)"
        print_status "2. StrategyTokenSample (ERC20 token)"
        echo ""
        read -p "Continue with treasury setup? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            run_deployment_script "deploy-tax-strategy.sh" "TaxStrategy Deployment" &&
            run_deployment_script "deploy-strategy-token.sh" "StrategyTokenSample Deployment"
            
            if [ $? -eq 0 ]; then
                print_success "🏦 Treasury setup completed successfully!"
                print_warning "📝 Next steps:"
                print_warning "   • Note the TaxStrategy address for ETF_TREASURY_ADDRESS"
                print_warning "   • Use these addresses when deploying the CLTaxStrategyHook"
            fi
        else
            print_status "Treasury setup cancelled."
        fi
        ;;
    6)
        print_status "Exiting deployment suite..."
        exit 0
        ;;
    *)
        print_error "Invalid option. Please select 1-6."
        exit 1
        ;;
esac

print_status "🏁 Deployment suite session completed."