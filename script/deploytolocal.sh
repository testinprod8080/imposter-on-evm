# run Anvil first
# anvil -a <num of accounts>

source .env \

forge script script/SingleGameInstance.s.sol:SingleGameInstanceScript \
 --fork-url $FORK_URL \
 --private-key $PRIVATE_KEY0 --broadcast

#  Afterwards, set contract address to env
# echo CONTRACT_ADDRESS=0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
# 
# Example calls:
# cast call $CONTRACT_ADDRESS "getFunc():string"
# cast send --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "mint(uint256)" 1