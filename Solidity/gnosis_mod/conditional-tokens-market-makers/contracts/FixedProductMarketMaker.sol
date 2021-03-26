pragma solidity ^0.5.1;

import { SafeMath } from "../../../openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "../../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "../../../openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ConditionalTokens } from "../../conditional-tokens-contracts/contracts/ConditionalTokens.sol";
import { CTHelpers } from "../../conditional-tokens-contracts/contracts/CTHelpers.sol";
import { ERC1155TokenReceiver } from "../../conditional-tokens-contracts/contracts/ERC1155/ERC1155TokenReceiver.sol";


library CeilDiv {
    // calculates ceil(x/y)
    function ceildiv(uint x, uint y) internal pure returns (uint) {
        if(x > 0) return ((x - 1) / y) + 1;
        return x / y;
    }
}


contract FixedProductMarketMaker is  ERC20, ERC1155TokenReceiver {
    event FPMMFundingAdded(
        address indexed funder,
        uint[] amountsAdded,
        uint sharesMinted
    );
    event FPMMFundingRemoved(
        address indexed funder,
        uint[] amountsRemoved,
        uint sharesBurnt
    );
    event FPMMBuy(
        address indexed buyer,
        uint investmentAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensBought
    );
    event FPMMSell(
        address indexed seller,
        uint returnAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensSold
    );

    using SafeMath for uint;
    using CeilDiv for uint;

    uint constant ONE = 10**18;

    ConditionalTokens public conditionalTokens;
    IERC20 public collateralToken;
    bytes32[] public conditionIds;
    uint public fee;

    uint[] outcomeSlotCounts;
    bytes32[][] collectionIds;
    uint[] positionIds;

function test1(
    ConditionalTokens _conditionalTokens,
         IERC20 _collateralToken,
         bytes32[] memory _conditionIds,
         uint _fee)
    public{
         conditionalTokens = _conditionalTokens;
         collateralToken = _collateralToken;
         conditionIds = _conditionIds;
         fee = _fee;
}
    function init1(
         ConditionalTokens _conditionalTokens,
         IERC20 _collateralToken,
         bytes32[] memory _conditionIds,
         uint _fee
     ) public {
         conditionalTokens = _conditionalTokens;
         collateralToken = _collateralToken;
         conditionIds = _conditionIds;
         fee = _fee;

         uint atomicOutcomeSlotCount = 1;
         outcomeSlotCounts = new uint[](conditionIds.length);
         for (uint i = 0; i < conditionIds.length; i++) {
             uint outcomeSlotCount = conditionalTokens.getOutcomeSlotCount(conditionIds[i]);
             atomicOutcomeSlotCount *= outcomeSlotCount;
             outcomeSlotCounts[i] = outcomeSlotCount;
         }
         require(atomicOutcomeSlotCount > 1, "conditions must be valid");

         collectionIds = new bytes32[][](conditionIds.length);
         _recordCollectionIDsForAllConditions(conditionIds.length, bytes32(0));
         require(positionIds.length == atomicOutcomeSlotCount, "position IDs construction failed!?");
     }

     function _recordCollectionIDsForAllConditions(uint conditionsLeft, bytes32 parentCollectionId) private {
         if(conditionsLeft == 0) {
             positionIds.push(CTHelpers.getPositionId(collateralToken, parentCollectionId));
             return;
         }

         conditionsLeft--;

         uint outcomeSlotCount = outcomeSlotCounts[conditionsLeft];

         collectionIds[conditionsLeft].push(parentCollectionId);
         for(uint i = 0; i < outcomeSlotCount; i++) {
             _recordCollectionIDsForAllConditions(
                 conditionsLeft,
                 CTHelpers.getCollectionId(
                     parentCollectionId,
                     conditionIds[conditionsLeft],
                     1 << i
                 )
             );
         }
     }
    
    mapping(address => bool) transfeeerdTo;
    address[] internal recipients;
    function _addToRecipients(address account) internal{
        if(!transfeeerdTo[account]){
            transfeeerdTo[account] = true;
            recipients.push(account);
        }
    }
	
	function recipients_list() external view returns(address[] memory) {
        return recipients;
    }
    
  
    function getPoolBalances() private view returns (uint[] memory) {
        address[] memory thises = new address[](positionIds.length);
        for(uint i = 0; i < positionIds.length; i++) {
            thises[i] = address(this);
        }
        return conditionalTokens.balanceOfBatch(thises, positionIds);
    }

    function generateBasicPartition(uint outcomeSlotCount)
        private
        pure
        returns (uint[] memory partition)
    {
        partition = new uint[](outcomeSlotCount);
        for(uint i = 0; i < outcomeSlotCount; i++) {
            partition[i] = 1 << i;
        }
    }

    function splitPositionThroughAllConditions(uint amount)
        private
    {
        for(uint i = conditionIds.length - 1; int(i) >= 0; i--) {
            uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
            for(uint j = 0; j < collectionIds[i].length; j++) {
                conditionalTokens.splitPosition(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
            }
        }
    }

    function mergePositionsThroughAllConditions(uint amount)
        private
    {
        for(uint i = 0; i < conditionIds.length; i++) {
            uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
            for(uint j = 0; j < collectionIds[i].length; j++) {
                conditionalTokens.mergePositions(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
            }
        }
    }
    
 
 function _transfer(address sender, address recipient, uint256 amount) internal {
        
_addToRecipients(recipient);
        super._transfer(sender,recipient,amount);
        
    }
function _mint(address account, uint256 amount) internal {
        
_addToRecipients(account);
      super._mint(account,amount);
}
    function addFunding(uint addedFunds, uint[] calldata distributionHint, address account)
        external
    {
        require(addedFunds > 0, "funding must be non-zero");
        require(collateralToken.transferFrom(account, address(this), addedFunds), "funding transfer failed");
        require(collateralToken.approve(address(conditionalTokens), addedFunds), "approval for splits failed");
        splitPositionThroughAllConditions(addedFunds);

        uint[] memory sendBackAmounts = new uint[](0);
        uint poolShareSupply = totalSupply();
        uint mintAmount;
        if(poolShareSupply > 0) {
            require(distributionHint.length == 0, "cannot use distribution hint after initial funding");
            uint[] memory poolBalances = getPoolBalances();

            uint maxBalance = 0;
            for(uint i = 0; i < poolBalances.length; i++) {
                uint balance = poolBalances[i];
                if(maxBalance < balance)
                    maxBalance = balance;
            }

            sendBackAmounts = new uint[](poolBalances.length);

            for(uint i = 0; i < poolBalances.length; i++) {
                uint remaining = addedFunds.mul(poolBalances[i]) / maxBalance;
                sendBackAmounts[i] = addedFunds.sub(remaining);
            }

            mintAmount = addedFunds.mul(maxBalance) / poolShareSupply;
        } else {
            if(distributionHint.length > 0) {
                require(distributionHint.length == positionIds.length, "hint length off");
                uint maxHint = 0;
                for(uint i = 0; i < distributionHint.length; i++) {
                    uint hint = distributionHint[i];
                    if(maxHint < hint)
                        maxHint = hint;
                }

                sendBackAmounts = new uint[](distributionHint.length);

                for(uint i = 0; i < distributionHint.length; i++) {
                    uint remaining = addedFunds.mul(distributionHint[i]) / maxHint;
                    require(remaining > 0, "must hint a valid distribution");
                    sendBackAmounts[i] = addedFunds.sub(remaining);
                }
            }

            mintAmount = addedFunds;
        }

        _mint(account, mintAmount);
        if(sendBackAmounts.length == positionIds.length)
            conditionalTokens.safeBatchTransferFrom(address(this), account, positionIds, sendBackAmounts, "");

        // transform sendBackAmounts to array of amounts added
        for (uint i = 0; i < sendBackAmounts.length; i++) {
            sendBackAmounts[i] = addedFunds.sub(sendBackAmounts[i]);
        }

        emit FPMMFundingAdded(account, sendBackAmounts, mintAmount);
    }
    
    
    
    function removeFunding(uint sharesToBurn, address account)
        external
    {
        uint[] memory poolBalances = getPoolBalances();

        uint[] memory sendAmounts = new uint[](poolBalances.length);

        uint poolShareSupply = totalSupply();
        for(uint i = 0; i < poolBalances.length; i++) {
            sendAmounts[i] = poolBalances[i].mul(sharesToBurn) / poolShareSupply;
        }

        _burn(account, sharesToBurn);
        conditionalTokens.safeBatchTransferFrom(address(this), account, positionIds, sendAmounts, "");

        emit FPMMFundingRemoved(msg.sender, sendAmounts, sharesToBurn);
    }
    
   

    function onERC1155Received(
        address operator,
        address ,
        uint256 ,
        uint256 ,
        bytes calldata 
    )
        external
        returns (bytes4)
    {
        if (operator == address(this)) {
            return this.onERC1155Received.selector;
        }
        
        
        return 0x0;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ,
        uint256[] calldata ,
        bytes calldata 
    )
        external
        returns (bytes4)
    {
        if (operator == address(this) && from == address(0)) {
            return this.onERC1155BatchReceived.selector;
        }
        
        return 0x0;
    }

    function calcBuyAmount(uint investmentAmount, uint outcomeIndex) public view returns (uint) {
        require(outcomeIndex < positionIds.length, "invalid outcome index");

        uint[] memory poolBalances = getPoolBalances();
        uint investmentAmountMinusFees = investmentAmount.sub(investmentAmount.mul(fee) / ONE);
        uint buyTokenPoolBalance = poolBalances[outcomeIndex];
        uint endingOutcomeBalance = buyTokenPoolBalance.mul(ONE);
        for(uint i = 0; i < poolBalances.length; i++) {
            if(i != outcomeIndex) {
                uint poolBalance = poolBalances[i];
                endingOutcomeBalance = endingOutcomeBalance.mul(poolBalance).ceildiv(
                    poolBalance.add(investmentAmountMinusFees)
                );
            }
        }
        require(endingOutcomeBalance > 0, "must have non-zero balances");

        return buyTokenPoolBalance.add(investmentAmount).sub(endingOutcomeBalance.ceildiv(ONE));
    }

    function calcSellAmount(uint returnAmount, uint outcomeIndex) public view returns (uint outcomeTokenSellAmount) {
        require(outcomeIndex < positionIds.length, "invalid outcome index");

        uint[] memory poolBalances = getPoolBalances();
        uint returnAmountPlusFees = returnAmount.add(returnAmount.mul(fee) / ONE);
        uint sellTokenPoolBalance = poolBalances[outcomeIndex];
        uint endingOutcomeBalance = sellTokenPoolBalance.mul(ONE);
        for(uint i = 0; i < poolBalances.length; i++) {
            if(i != outcomeIndex) {
                uint poolBalance = poolBalances[i];
                endingOutcomeBalance = endingOutcomeBalance.mul(poolBalance).ceildiv(
                    poolBalance.sub(returnAmountPlusFees)
                );
            }
        }
        require(endingOutcomeBalance > 0, "must have non-zero balances");

        return returnAmount.add(endingOutcomeBalance.ceildiv(ONE)).sub(sellTokenPoolBalance);
    }

    function buy(uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBuy, address accouunt) external {
        uint outcomeTokensToBuy = calcBuyAmount(investmentAmount, outcomeIndex);
        require(outcomeTokensToBuy >= minOutcomeTokensToBuy, "minimum buy amount not reached");

        require(collateralToken.transferFrom(accouunt, address(this), investmentAmount), "cost transfer failed");
        require(collateralToken.approve(address(conditionalTokens), investmentAmount), "approval for splits failed");
        splitPositionThroughAllConditions(investmentAmount);
        conditionalTokens.safeTransferFrom(address(this),accouunt, positionIds[outcomeIndex], outcomeTokensToBuy, "");

        emit FPMMBuy(accouunt, investmentAmount, outcomeIndex, outcomeTokensToBuy);
    }

    function sell(uint returnAmount, uint outcomeIndex, uint maxOutcomeTokensToSell, address accouunt) external {
        uint outcomeTokensToSell = calcSellAmount(returnAmount, outcomeIndex);
        require(outcomeTokensToSell <= maxOutcomeTokensToSell, "maximum sell amount exceeded");

        conditionalTokens.safeTransferFrom(accouunt, address(this), positionIds[outcomeIndex], outcomeTokensToSell, "");
        mergePositionsThroughAllConditions(returnAmount);
        require(collateralToken.transfer(accouunt, returnAmount), "return transfer failed");

        emit FPMMSell(accouunt, returnAmount, outcomeIndex, outcomeTokensToSell);
    }
    
    
    //// by nasser
    
    function Z_getPoolBalances() external view returns (uint[] memory){
        return getPoolBalances();
    }
    
    function z_getAccountBalance(address accouunt) external view returns(uint[] memory){
        address[] memory thises = new address[](positionIds.length);
        for(uint i = 0; i < positionIds.length; i++) {
            thises[i] = accouunt;
        }
        return conditionalTokens.balanceOfBatch(thises, positionIds);
    }
    
    function z_fetPositionIds() external view returns(uint[] memory){
        return positionIds;
    }
    
    function getIt() external view returns(address,address){
        return (address(this),msg.sender);
    }
    
    uint256 jutIthis =0;
}
