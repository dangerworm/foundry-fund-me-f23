-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_DEV_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(FUND_ME_ETHERSCAN_API_KEY) -vvvv