pragma solidity ^0.5.0;

import "../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../openzeppelin/contracts/math/SafeMath.sol";
import "../../openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract RoomStaking {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // TODO: Please assign the wallet address to this contract.
    // TODO: Please do not forget to call the approve for this contract from the wallet.
    address public roomTokenRewardsReservoirAddress;
    address public owner;

    // This is ROOM/ETH liquidity pool address.
    IERC20 public roomLPToken = IERC20(0xBE55c87dFf2a9f5c95cB5C07572C51fd91fe0732);

    // This is the correct address of the ROOM token
    // https://etherscan.io/token/0xad4f86a25bbc20ffb751f2fac312a0b4d8f88c64?a=0xbe55c87dff2a9f5c95cb5c07572c51fd91fe0732
    IERC20 public roomToken = IERC20(0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64);

    uint256 private _totalStaked;

    // last updated block number
    uint256 public lastUpdateBlock;

    // normal rewards
    uint256 private  _rewardPerBlock;   // reward per block
    uint256 private  _accRewardPerToken; // accumulative reward per token
    uint256 public  finishBlock; // finish rewarding block number
    uint256 public  endTime;

    mapping(address => uint256) private _rewards; // rewards balances
    mapping(address => uint256) private _prevAccRewardPerToken; // previous accumulative reward per token (for a user)
    mapping(address => uint256) private _balances;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event StakeRewards(address indexed user, uint256 amount, uint256 lockTime);
    event CourtStakeChanged(address oldAddress, address newAddress);
    event FarmingParametersChanged(uint256 rewardPerBlock, uint256 rewardBlockCount, address indexed roomTokenRewardsReservoirAdd);
    event RewardTransferFailed(TransferRewardState failure);

    enum TransferRewardState {
        Succeeded,
        RewardWalletEmpty
    }

    constructor (uint256 rewardPerBlock, uint256 rewardBlockCount, address walletAddress) public {

        owner = msg.sender;

        roomTokenRewardsReservoirAddress = walletAddress;

        _rewardPerBlock = rewardPerBlock.mul(1e18); // for math precisio

        finishBlock = blockNumber().add(rewardBlockCount);
        endTime = finishBlock.sub(blockNumber()).mul(15).add(block.timestamp);
        lastUpdateBlock = blockNumber();
    }

    function changeFarmingParameters(uint256 rewardPerBlock, uint256 rewardBlockCount, address roomTokenRewardsReservoirAdd) external {

        require(msg.sender == owner, "can be called by owner only");
        updateReward(address(0));
        _rewardPerBlock = rewardPerBlock.mul(1e18); // for math precision

        finishBlock = blockNumber().add(rewardBlockCount);
        endTime = finishBlock.sub(blockNumber()).mul(15).add(block.timestamp);
        roomTokenRewardsReservoirAddress = roomTokenRewardsReservoirAdd;

        emit FarmingParametersChanged(_rewardPerBlock, rewardBlockCount, roomTokenRewardsReservoirAddress);
    }

    function updateReward(address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalStaked is zero; do not increment accRewardPerToken
        if (totalStaked() > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > lastUpdateBlock) {
                _accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock)
                .mul(_rewardPerBlock)
                .div(totalStaked())
                .add(_accRewardPerToken);
            }
        }

        lastUpdateBlock = cnBlock;

        if (account != address(0)) {

            uint256 accRewardPerTokenForUser = _accRewardPerToken.sub(_prevAccRewardPerToken[account]);

            if (accRewardPerTokenForUser > 0) {
                _rewards[account] =
                _balances[account]
                .mul(accRewardPerTokenForUser)
                .div(1e18)
                .add(_rewards[account]);

                _prevAccRewardPerToken[account] = _accRewardPerToken;
            }
        }
    }

    function stake(uint256 amount) external {
        updateReward(msg.sender);

        _totalStaked = _totalStaked.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // Transfer from owner of Room Token to this address.
        roomLPToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount, bool claim) external returns(uint256 reward, TransferRewardState reason) {
        updateReward(msg.sender);


        _totalStaked = _totalStaked.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        // Send Room token staked to the original owner.
        roomLPToken.safeTransfer(msg.sender, amount);


        if (claim) {
            (reward, reason) = _executeRewardTransfer(msg.sender);
        }

        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external returns (uint256 reward, TransferRewardState reason) {
        updateReward(msg.sender);

        return _executeRewardTransfer(msg.sender);
    }

    function _executeRewardTransfer(address account) internal returns(uint256 reward, TransferRewardState reason) {

        reward = _rewards[account];
        if (reward > 0) {
            uint256 walletBalanace = roomToken.balanceOf(roomTokenRewardsReservoirAddress);
            if (walletBalanace < reward) {
                // This fails, and we send reason 1 for the UI
                // to display a meaningful message for the user.
                // 1 means the wallet is empty.
                reason = TransferRewardState.RewardWalletEmpty;
                emit RewardTransferFailed(reason);

            } else {

                // We will transfer and then empty the rewards
                // for the sender.
                _rewards[msg.sender] = 0;
                roomToken.transferFrom(roomTokenRewardsReservoirAddress, msg.sender, reward);
                emit ClaimReward(msg.sender, reward);
            }
        }
    }

    function rewards(address account) external view returns (uint256 reward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken;

        // update accRewardPerToken, in case totalStaked is zero; do not increment accRewardPerToken
        if (totalStaked() > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > lastUpdateBlock) {
                accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock)
                .mul(_rewardPerBlock).div(totalStaked())
                .add(accRewardPerToken);
            }
        }

        reward = _balances[account]
        .mul(accRewardPerToken.sub(_prevAccRewardPerToken[account]))
        .div(1e18)
        .add(_rewards[account]);
    }

    function info() external view returns (
            uint256 cBlockNumber,
            uint256 rewardPerBlock,
            uint256 rewardFinishBlock,
            uint256 rewardEndTime,
            uint256 walletBalance) {
        cBlockNumber = blockNumber();
        rewardFinishBlock = finishBlock;
        rewardPerBlock = _rewardPerBlock.div(1e18);
        rewardEndTime = endTime;
        walletBalance = roomToken.balanceOf(roomTokenRewardsReservoirAddress);
    }

    // expected reward,
    // please note this is only an estimation, because total balance may change during the program
    function expectedRewardsToday(uint256 amount) external view returns (uint256 reward) {

        uint256 cnBlock = blockNumber();
        uint256 prevAccRewardPerToken = _accRewardPerToken;

        uint256 accRewardPerToken = _accRewardPerToken;
        // update accRewardPerToken, in case totalStaked is zero do; not increment accRewardPerToken

        uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
        if (lastRewardBlock > lastUpdateBlock) {
            accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock)
            .mul(_rewardPerBlock).div(totalStaked().add(amount))
            .add(accRewardPerToken);
        }

        uint256 rewardsPerBlock = amount
        .mul(accRewardPerToken.sub(prevAccRewardPerToken))
        .div(1e18);


        reward = rewardsPerBlock.mul(5760); // 5760 blocks per day
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function blockNumber() public view returns (uint256) {
        return block.number;
    }
}
