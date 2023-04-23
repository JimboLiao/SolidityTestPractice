# To load the variables in the .env file
source .env

forge test --fork-url $ETH_RPC_URL --fork-block-number 12299047 --match-contract TestFork -vvvvv