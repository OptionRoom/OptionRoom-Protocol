pragma solidity ^0.5.0;

import "./ICourtStake.sol";
import "../ERC20/IMERC20.sol";
import "../../openzeppelin/contracts/math/SafeMath.sol";
import "../../openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// This contract will have three deployments with different configurations.
// Reward "COURT" farming; from staking of the ROOM token.
// Reward "COURT" farming; from staking of ROOM liquidity pool token (Liquidity pool for ROOM/ETH).
// Reward "COURT" farming; from staking of COURT liquidity pool token (Liquidity pool for COURT/ETH).
contract CourtFarming {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // TODO: set the correct lpToken address
    IERC20 public lpToken = IERC20(0x71623C84fE967a7D41843c56D7D3D89F11D71faa);

    //TODO: set the correct Court Token address
    IMERC20 public courtToken = IMERC20(0xD09534141358B39AC0A3d2A5c48603eb110f3d1f);

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


    // incentive rewards
    uint256 private _incvRewardPerBlock; // incentive reward per block
    uint256 private _incvAccRewardPerToken; // accumulative reward per token
    mapping(address => uint256) private _incvRewards; // reward balances
    mapping(address => uint256) private _incvPrevAccRewardPerToken;// previous accumulative reward per token (for a user)
    uint256 public _incvFinishBlock; //  finish incentive rewarding block number
    uint256 _incvLockTime;
    bool incvLocked = true;

    address private _owner;

    // To minimize the actions required to stake COURT, you just put the address
    // of the contract that holds the governance COURT staking.
    // TODO: Tareq Doufish, testing is required for the function
    // that sets the address and do the actual transfer.
    address public courtStakeAddress;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event ClaimIncentiveReward(address indexed user, uint256 reward);
    event StakeRewards(address indexed user, uint256 amount, uint256 lockTime);
    event CourtStakeChanged(address oldAddress, address newAddress);
    event FarmingParametersChanged(uint256 rewardPerBlock, uint256 rewardBlockCount, uint256 incvRewardPerBlock, uint256 incvRewardBlockCount, uint256 incvLockTime);

    constructor (uint256 rewardPerBlock, uint256 rewardBlockCount, uint256 incvRewardPerBlock, uint256 incvRewardBlockCount, uint256 incvLockTime) public {

        _owner = msg.sender;

        _rewardPerBlock = rewardPerBlock.mul(1e18);
        // for math precision
        _finishBlock = blockNumber().add(rewardBlockCount);

        _incvRewardPerBlock = incvRewardPerBlock.mul(1e18);
        _incvFinishBlock = blockNumber().add(incvRewardBlockCount);

        _incvLockTime = incvLockTime;
        _lastUpdateBlock = blockNumber();
    }

    function changeFarmingParameters(uint256 rewardPerBlock, uint256 rewardBlockCount, uint256 incvRewardPerBlock, uint256 incvRewardBlockCount, uint256 incvLockTime) public {

        require(msg.sender == _owner, "can be called by owner only");
        updateReward(address(0));
        _rewardPerBlock = rewardPerBlock.mul(1e18);
        // for math precision
        _finishBlock = blockNumber().add(rewardBlockCount);

        _incvRewardPerBlock = incvRewardPerBlock.mul(1e18);
        _incvFinishBlock = blockNumber().add(incvRewardBlockCount);

        _incvLockTime = incvLockTime;

        emit FarmingParametersChanged(_rewardPerBlock, rewardBlockCount, _incvRewardPerBlock, incvRewardBlockCount, incvLockTime);
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

            uint256 incvlastRewardBlock = cnBlock < _incvFinishBlock ? cnBlock : _incvFinishBlock;
            if (incvlastRewardBlock > _lastUpdateBlock) {
                _incvAccRewardPerToken = incvlastRewardBlock.sub(_lastUpdateBlock)
                .mul(_incvRewardPerBlock).div(totalSupply())
                .add(_incvAccRewardPerToken);
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

            uint256 incAccRewardPerTokenForUser = _incvAccRewardPerToken.sub(_incvPrevAccRewardPerToken[account]);

            if (incAccRewardPerTokenForUser > 0) {
                _incvRewards[account] =
                _balances[account]
                .mul(incAccRewardPerTokenForUser)
                .div(1e18)
                .add(_incvRewards[account]);

                _incvPrevAccRewardPerToken[account] = _incvAccRewardPerToken;
            }
        }
    }

    function stake(uint256 amount) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalSupply = _totalSupply.add(amount);
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            lpToken.safeTransferFrom(msg.sender, address(this), amount);
            emit Staked(msg.sender, amount);
        }
    }

    function unstake(uint256 amount, bool claim) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            lpToken.safeTransfer(msg.sender, amount);
            emit Unstaked(msg.sender, amount);
        }

        if (claim) {
            uint256 reward = _rewards[msg.sender];
            if (reward > 0) {
                _rewards[msg.sender] = 0;
                courtToken.mint(msg.sender, reward);
                emit ClaimReward(msg.sender, reward);
            }
        }
    }

    function claimReward() public returns (uint256){
        updateReward(msg.sender);

        uint256 reward = _rewards[msg.sender];
        // TODO: chose if or require
        if (reward > 0) {
            _rewards[msg.sender] = 0;
            courtToken.mint(msg.sender, reward);
            emit ClaimReward(msg.sender, reward);
        }
        return reward;
    }

    function claimIncvReward() public returns (uint256){
        // TODO: chose if or require
        if (incvLocked && block.timestamp < _incvLockTime) {
            return 0;
        }

        updateReward(msg.sender);

        uint256 incvReward = _incvRewards[msg.sender];
        // TODO: chose if or require
        if (incvReward > 0) {
            _incvRewards[msg.sender] = 0;
            courtToken.mint(msg.sender, incvReward);
            emit ClaimIncentiveReward(msg.sender, incvReward);
        }

        return incvReward;
    }


    function stakeRewards(uint256 amount) public returns (bool) {
        updateReward(msg.sender);
        uint256 reward = _rewards[msg.sender];

        // TODO: chose if or require
        if (amount > reward || courtStakeAddress == address(0)) {
            return false;
        }

        _rewards[msg.sender] -= amount;
        // no need to use safe math sub, since there is check for amount > reward
        courtToken.mint(address(this), amount);

        ICourtStake courtStake = ICourtStake(courtStakeAddress);
        courtStake.lockedStake(amount, 0, msg.sender);
        emit StakeRewards(msg.sender, amount, 0);

    }

    function stakeIncRewards(uint256 amount) public returns (bool) {
        updateReward(msg.sender);
        uint256 incvReward = _incvRewards[msg.sender];

        // TODO: chose if or require
        if (amount > incvReward || courtStakeAddress == address(0)) {
            return false;
        }

        _incvRewards[msg.sender] -= amount;
        // no need to use safe math sub, since there is check for amount > reward
        courtToken.mint(address(this), amount);

        ICourtStake courtStake = ICourtStake(courtStakeAddress);
        courtStake.lockedStake(amount, _incvLockTime, msg.sender);
        emit StakeRewards(msg.sender, amount, _incvLockTime);
    }

    function setCourtStake(address courtStakeAdd) public {
        require(msg.sender == _owner, "only contract owner can change");
        address oldAddress = courtStakeAddress;
        courtStakeAddress = courtStakeAdd;

        IERC20 courtTokenERC20 = IERC20(address(courtToken));

        courtTokenERC20.approve(courtStakeAdd, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        emit CourtStakeChanged(oldAddress, courtStakeAdd);
    }

    function rewards(address account) external view returns (uint256 reward, uint256 incvReward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken;
        uint256 incvAccRewardPerToken = _incvAccRewardPerToken;

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (totalSupply() > 0) {
            uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
            if (lastRewardBlock > _lastUpdateBlock) {
                accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
                .mul(_rewardPerBlock).div(totalSupply())
                .add(accRewardPerToken);
            }

            uint256 incvLastRewardBlock = cnBlock < _incvFinishBlock ? cnBlock : _incvFinishBlock;
            if (incvLastRewardBlock > _lastUpdateBlock) {
                incvAccRewardPerToken = incvLastRewardBlock.sub(_lastUpdateBlock)
                .mul(_incvRewardPerBlock).div(totalSupply())
                .add(incvAccRewardPerToken);
            }
        }

        reward = _balances[account]
        .mul(accRewardPerToken.sub(_prevAccRewardPerToken[account]))
        .div(1e18)
        .add(_rewards[account]);

        incvReward = _balances[account]
        .mul(incvAccRewardPerToken.sub(_incvPrevAccRewardPerToken[account]))
        .div(1e18)
        .add(_incvRewards[account]);
    }

    function info() external view returns (uint256 cblockNumber, uint256 rewardPerBlock, uint256 rewardFinshBlock, uint256 incvRewardfinishBlock, uint256 incvRewardPerBlock) {
        cblockNumber = blockNumber();
        rewardFinshBlock = _finishBlock;
        incvRewardfinishBlock = _incvFinishBlock;
        rewardPerBlock = _rewardPerBlock.div(1e18);
        incvRewardPerBlock = _incvRewardPerBlock.div(1e18);
    }


    // expected reward,
    // please note this is only expectation, because total balance may changed during the day
    function expectedRewardsToday(uint256 amount) external view returns (uint256 reward, uint256 incvReward) {
        // read version of update

        uint256 cnBlock = blockNumber();
        uint256 prevAccRewardPerToken = _accRewardPerToken;
        uint256 prevIncvAccRewardPerToken = _incvAccRewardPerToken;

        uint256 accRewardPerToken = _accRewardPerToken;
        uint256 incvAccRewardPerToken = _incvAccRewardPerToken;
        // update accRewardPerToken, in case totalSupply is zero do; not increment accRewardPerToken

        uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
        if (lastRewardBlock > _lastUpdateBlock) {
            accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
            .mul(_rewardPerBlock).div(totalSupply().add(amount))
            .add(accRewardPerToken);
        }

        uint256 incvLastRewardBlock = cnBlock < _incvFinishBlock ? cnBlock : _incvFinishBlock;
        if (incvLastRewardBlock > _lastUpdateBlock) {
            incvAccRewardPerToken = incvLastRewardBlock.sub(_lastUpdateBlock)
            .mul(_incvRewardPerBlock).div(totalSupply().add(amount))
            .add(incvAccRewardPerToken);
        }


        uint256 rewardsPerBlock = amount
        .mul(accRewardPerToken.sub(prevAccRewardPerToken))
        .div(1e18);

        uint256 incvRewardsPerBlock = amount
        .mul(incvAccRewardPerToken.sub(prevIncvAccRewardPerToken))
        .div(1e18);

        // 5760 blocks per day
        reward = rewardsPerBlock.mul(5760);
        incvReward = incvRewardsPerBlock.mul(5760);
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
