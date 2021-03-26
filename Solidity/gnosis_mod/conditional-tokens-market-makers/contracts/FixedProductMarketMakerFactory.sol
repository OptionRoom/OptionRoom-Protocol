pragma solidity ^0.5.1;

import { IERC20 } from "../../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ConditionalTokens } from "../../conditional-tokens-contracts/contracts/ConditionalTokens.sol";
import { CTHelpers } from "../../conditional-tokens-contracts/contracts/CTHelpers.sol";
//import { ConstructedCloneFactory } from "../../util-contracts/contracts/ConstructedCloneFactory.sol";
import { FixedProductMarketMaker } from "./FixedProductMarketMaker.sol";
import { ERC1155TokenReceiver } from "../../conditional-tokens-contracts/contracts/ERC1155/ERC1155TokenReceiver.sol";
import { CloneFactory } from "../../util-contracts/contracts/CloneFactoryNew.sol";
contract FixedProductMarketMakerData {
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 internal _totalSupply;


    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) internal _supportedInterfaces;


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
    ConditionalTokens internal conditionalTokens;
    IERC20 internal collateralToken;
    bytes32[] internal conditionIds;
    uint internal fee;

    uint[] internal outcomeSlotCounts;
    bytes32[][] internal collectionIds;
    uint[] internal positionIds;
}

contract FixedProductMarketMakerFactory is CloneFactory, FixedProductMarketMakerData {
    event FixedProductMarketMakerCreation(
        address indexed creator,
        FixedProductMarketMaker fixedProductMarketMaker,
        ConditionalTokens indexed conditionalTokens,
        IERC20 indexed collateralToken,
        bytes32[] conditionIds,
        uint fee
    );

    FixedProductMarketMaker public implementationMaster;

    constructor() public {
        implementationMaster = new FixedProductMarketMaker();
    }


    function createFixedProductMarketMaker(
        ConditionalTokens conditionalTokens,
        IERC20 collateralToken,
        bytes32[] calldata conditionIds,
        uint fee
    )
        external
        returns (FixedProductMarketMaker)
    {
        FixedProductMarketMaker fixedProductMarketMaker = FixedProductMarketMaker(createClone(address(implementationMaster)));
        //fixedProductMarketMaker.init1(conditionalTokens,collateralToken,conditionIds,fee);
        fixedProductMarketMaker.init1(conditionalTokens,collateralToken,conditionIds,fee);
        emit FixedProductMarketMakerCreation(
            msg.sender,
            fixedProductMarketMaker,
            conditionalTokens,
            collateralToken,
            conditionIds,
            fee
        );
        
        mmmm.push(address(fixedProductMarketMaker));
        return fixedProductMarketMaker;
    }
   
    address[] mmmm;
    
    function getMM(uint dumy) public view returns(address[] memory){
        dumy =0;
        return mmmm;
    }
    
    function resetMM() public {
        while(mmmm.length > 0){
            mmmm.pop();
        }
    }
    
    function getIt() external view returns(address,address){
        return (address(this),msg.sender);
    }
}
