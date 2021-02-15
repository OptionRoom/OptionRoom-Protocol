pragma solidity ^0.5.0;

import "../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../openzeppelin/contracts/math/SafeMath.sol";

contract RoomStaking {

    using SafeMath for uint256;

    // TODO: Please assign the wallet address to this contract.
    // TODO: Please do not forget to call the approve for this contract from the wallet.
    address private _roomTokenRewardsReservoirAddress;

    //TODO: set the correct Room Token address
    IERC20 public roomToken = IERC20(0xD09534141358B39AC0A3d2A5c48603eb110f3d1f);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // last updated block number
    uint256 private _lastUpdateBlock;

    // normal rewards
    uint256 private  _rewardPerBlock;   // reward per block
    uint256 private _accRewardPerToken; // accumulative reward per token
    mapping(address => uint256) private _rewards; // rewards balances
    mapping(address => uint256) private _prevAccRewardPerToken; // previous accumulative reward per token (for a user)
    uint256 public _finishBlock; // finish rewarding block number

    address private _owner;

    event RoomTokenWalletEmpty();
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event StakeRewards(address indexed user, uint256 amount, uint256 lockTime);
    event CourtStakeChanged(address oldAddress, address newAddress);
    event StakingParametersChanged(uint256 rewardPerBlock, uint256 rewardBlockCount);

    constructor (uint256 rewardPerBlock, uint256 rewardBlockCount, address roomTokenRewardsReservoirAddress) public {

        _owner = msg.sender;

        _roomTokenRewardsReservoirAddress = roomTokenRewardsReservoirAddress;

        _rewardPerBlock = rewardPerBlock.mul(1e18);
        // for math precision
        _finishBlock = blockNumber().add(rewardBlockCount);

        _lastUpdateBlock = blockNumber();
    }

    function changeFarmingParameters(uint256 rewardPerBlock, uint256 rewardBlockCount, address roomTokenRewardsReservoirAddress) public {

        require(msg.sender == _owner, "can be called by owner only");
        updateReward(address(0));
        _rewardPerBlock = rewardPerBlock.mul(1e18);
        // for math precision
        _finishBlock = blockNumber().add(rewardBlockCount);
        _roomTokenRewardsReservoirAddress = roomTokenRewardsReservoirAddress;

        emit StakingParametersChanged(_rewardPerBlock, rewardBlockCount);
    }

    function updateReward(address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (totalSupply() > 0) {
            uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
            if (lastRewardBlock > _lastUpdateBlock) {
                _accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
                .mul(_rewardPerBlock).div(totalSupply())
                .add(_accRewardPerToken);
            }
        }

        _lastUpdateBlock = cnBlock;

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

    function stake(uint256 amount) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalSupply = _totalSupply.add(amount);
            _balances[msg.sender] = _balances[msg.sender].add(amount);

            // Transfer from owner of Room Token to this address.
            roomToken.transferFrom(msg.sender, address(this), amount);
            emit Staked(msg.sender, amount);
        }
    }

    function unstake(uint256 amount, bool claim) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            // Send Room token staked to the original owner.
            roomToken.transfer(msg.sender, amount);
            emit Unstaked(msg.sender, amount);
        }

        if (claim) {
            uint256 reward = _rewards[msg.sender];
            uint256 walletBalanace = roomToken.balanceOf(_roomTokenRewardsReservoirAddress);

            if (reward > 0 && walletBalanace > reward) {
                _rewards[msg.sender] = 0;
                // Instead of minting we transfer from this contract address to the message sender.
                roomToken.transferFrom(_roomTokenRewardsReservoirAddress, msg.sender, reward);
                emit ClaimReward(msg.sender, reward);
            }
        }
    }

    function claimReward() public returns (uint256 reward, uint8 reason) {
        updateReward(msg.sender);
        // 0 means successful operation for transferring tokens.
        reason = 0;
        reward = _rewards[msg.sender];

        // TODO: chose if or require
        if (reward > 0) {
            uint256 walletBalanace = roomToken.balanceOf(_roomTokenRewardsReservoirAddress);
            if (walletBalanace < reward) {
                // This fails, and we send reason 1 for the UI
                // to display a meaningful message for the user.
                // 1 means the wallet is empty.
                reason = 1;
                emit RoomTokenWalletEmpty();
            } else{
                // We will transfer and then empty the rewards
                // for the sender.
                _rewards[msg.sender] = 0;
                roomToken.transferFrom(_roomTokenRewardsReservoirAddress, msg.sender, reward);
                emit ClaimReward(msg.sender, reward);
            }
        }
        return (reward, reason);
    }

    function rewards(address account) external view returns (uint256 reward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken;

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (totalSupply() > 0) {
            uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
            if (lastRewardBlock > _lastUpdateBlock) {
                accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
                .mul(_rewardPerBlock).div(totalSupply())
                .add(accRewardPerToken);
            }
        }

        reward = _balances[account]
        .mul(accRewardPerToken.sub(_prevAccRewardPerToken[account]))
        .div(1e18)
        .add(_rewards[account]);
    }

    function info() external view returns (uint256 cBlockNumber, uint256 rewardPerBlock,
            uint256 rewardFinishBlock, uint256 walletBalance) {
        cBlockNumber = blockNumber();
        rewardFinishBlock = _finishBlock;
        rewardPerBlock = _rewardPerBlock.div(1e18);
        walletBalance = roomToken.balanceOf(_roomTokenRewardsReservoirAddress);
    }

    // expected reward,
    // please note this is only expectation, because total balance may changed during the day
    function expectedRewardsToday(uint256 amount) external view returns (uint256 reward) {
        // read version of update

        uint256 cnBlock = blockNumber();
        uint256 prevAccRewardPerToken = _accRewardPerToken;

        uint256 accRewardPerToken = _accRewardPerToken;
        // update accRewardPerToken, in case totalSupply is zero do; not increment accRewardPerToken

        uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
        if (lastRewardBlock > _lastUpdateBlock) {
            accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
            .mul(_rewardPerBlock).div(totalSupply().add(amount))
            .add(accRewardPerToken);
        }

        uint256 rewardsPerBlock = amount
        .mul(accRewardPerToken.sub(prevAccRewardPerToken))
        .div(1e18);

        // 5760 blocks per day
        reward = rewardsPerBlock.mul(5760);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function blockNumber() public view returns (uint256) {
        return block.number;
    }
}