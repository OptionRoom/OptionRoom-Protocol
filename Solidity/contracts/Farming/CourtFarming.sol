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
    IERC20 public stakedToken = IERC20(0x71623C84fE967a7D41843c56D7D3D89F11D71faa);

    //TODO: set the correct Court Token address
    IMERC20 public courtToken = IMERC20(0xD09534141358B39AC0A3d2A5c48603eb110f3d1f);

    uint256 private _totalStaked;
    mapping(address => uint256) private _balances;

    // last updated block number
    uint256 private _lastUpdateBlock;

    // normal rewards
    uint256 public finishBlock; // finish rewarding block number
    uint256 private  _rewardPerBlock;   // reward per block
    uint256 private _accRewardPerToken; // accumulative reward per token
    mapping(address => uint256) private _rewards; // rewards balances
    mapping(address => uint256) private _prevAccRewardPerToken; // previous accumulative reward per token (for a user)



    // incentive rewards

    uint256 public incvFinishBlock; //  finish incentive rewarding block number
    uint256 private _incvRewardPerBlock; // incentive reward per block
    uint256 private _incvAccRewardPerToken; // accumulative reward per token
    mapping(address => uint256) private _incvRewards; // reward balances
    mapping(address => uint256) private _incvPrevAccRewardPerToken;// previous accumulative reward per token (for a user)

    uint256 public incvStartReleasingTime;  // incentive releasing time
    uint256 public incvBatchPeriod; // incentive batch period
    uint256 public incvBatchCount; // incentive batch count
    mapping(address => uint256) public  incvWithdrawn;

    address public owner;

    enum TransferRewardState {
        Succeeded,
        RewardsStillLocked
    }

    
    address public courtStakeAddress;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event ClaimIncentiveReward(address indexed user, uint256 reward);
    event StakeRewards(address indexed user, uint256 amount, uint256 lockTime);
    event CourtStakeChanged(address oldAddress, address newAddress);
    event StakeParametersChanged(uint256 rewardPerBlock, uint256 rewardFinishBlock, uint256 incvRewardPerBlock, uint256 incvRewardFinsishBlock, uint256 incvLockTime);

    constructor (uint256 totalRewards,uint256 rewardsPeriodInDays ,
        uint256 incvTotalRewards, uint256 incvRewardsPeriodInDays) public {

        owner = msg.sender;

         _stakeParametrsCalculation(totalRewards, rewardsPeriodInDays, incvTotalRewards, incvRewardsPeriodInDays, 0);

        _lastUpdateBlock = blockNumber();
    }

    function _stakeParametrsCalculation(uint256 totalRewards, uint256 rewardsPeriodInDays, uint256 incvTotalRewards, uint256 incvRewardsPeriodInDays, uint256 iLockTime) internal{


        uint256 rewardBlockCount = rewardsPeriodInDays * 5760;
        uint256 rewardPerBlock = ((totalRewards * 1e18 )/ rewardBlockCount) / 1e18;

        uint256 incvRewardBlockCount = incvRewardsPeriodInDays * 5760;
        uint256 incvRewardPerBlock = ((incvTotalRewards * 1e18 )/ incvRewardBlockCount) / 1e18;

        _rewardPerBlock = rewardPerBlock.mul(1e18); // for math precision
        finishBlock = blockNumber().add(rewardBlockCount);

        _incvRewardPerBlock = incvRewardPerBlock.mul(1e18);
        incvFinishBlock = blockNumber().add(incvRewardBlockCount);

        incvStartReleasingTime = iLockTime;
    }

    function changeStakeParameters(uint256 totalRewards, uint256 rewardsPeriodInDays, uint256 incvTotalRewards, uint256 incvRewardsPeriodInDays, uint256 iLockTime) public {

        require(msg.sender == owner, "can be called by owner only");
        updateReward(address(0));

        _stakeParametrsCalculation(totalRewards, rewardsPeriodInDays, incvTotalRewards, incvRewardsPeriodInDays, iLockTime);

        emit StakeParametersChanged(_rewardPerBlock, finishBlock, _incvRewardPerBlock, incvFinishBlock, incvStartReleasingTime);
    }

    function updateReward(address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > _lastUpdateBlock) {
                _accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
                .mul(_rewardPerBlock).div(_totalStaked)
                .add(_accRewardPerToken);
            }

            uint256 incvlastRewardBlock = cnBlock < incvFinishBlock ? cnBlock : incvFinishBlock;
            if (incvlastRewardBlock > _lastUpdateBlock) {
                _incvAccRewardPerToken = incvlastRewardBlock.sub(_lastUpdateBlock)
                .mul(_incvRewardPerBlock).div(_totalStaked)
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
            _totalStaked = _totalStaked.add(amount);
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            stakedToken.safeTransferFrom(msg.sender, address(this), amount);
            emit Staked(msg.sender, amount);
        }
    }

    function unstake(uint256 amount, bool claim) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalStaked = _totalStaked.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            stakedToken.safeTransfer(msg.sender, amount);
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

    function claimReward() public returns (TransferRewardState ){
        updateReward(msg.sender);

        uint256 reward = _rewards[msg.sender];

        if (reward > 0) {
            _rewards[msg.sender] = 0;
            courtToken.mint(msg.sender, reward);
            emit ClaimReward(msg.sender, reward);
        }
         return TransferRewardState.Succeeded;
    }



    function stakeRewards(uint256 amount) public returns (bool) {
        updateReward(msg.sender);
        uint256 reward = _rewards[msg.sender];


        if (amount > reward || courtStakeAddress == address(0)) {
            return false;
        }

        _rewards[msg.sender] -= amount; // no need to use safe math sub, since there is check for amount > reward

        courtToken.mint(address(this), amount);

        ICourtStake courtStake = ICourtStake(courtStakeAddress);
        courtStake.lockedStake(amount, msg.sender, 0, 1,0);
        emit StakeRewards(msg.sender, amount, 0);

    }

    function stakeIncvRewards(uint256 amount) public returns (bool) {
        updateReward(msg.sender);
        uint256 incvReward = _incvRewards[msg.sender];


        if (amount > incvReward || courtStakeAddress == address(0)) {
            return false;
        }

        _incvRewards[msg.sender] -= amount;  // no need to use safe math sub, since there is check for amount > reward

        courtToken.mint(address(this), amount);

        ICourtStake courtStake = ICourtStake(courtStakeAddress);
        courtStake.lockedStake(amount,  msg.sender, incvStartReleasingTime, incvBatchCount, incvBatchPeriod);
        emit StakeRewards(msg.sender, amount, incvStartReleasingTime);
    }

    function setCourtStake(address courtStakeAdd) public {
        require(msg.sender == owner, "only contract owner can change");

        address oldAddress = courtStakeAddress;
        courtStakeAddress = courtStakeAdd;

        IERC20 courtTokenERC20 = IERC20(address(courtToken));

        courtTokenERC20.approve(courtStakeAdd, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        emit CourtStakeChanged(oldAddress, courtStakeAdd);
    }

    function rewards(address account) public view returns (uint256 reward, uint256 incvReward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken;
        uint256 incvAccRewardPerToken = _incvAccRewardPerToken;

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > _lastUpdateBlock) {
                accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
                .mul(_rewardPerBlock).div(_totalStaked)
                .add(accRewardPerToken);
            }

            uint256 incvLastRewardBlock = cnBlock < incvFinishBlock ? cnBlock : incvFinishBlock;
            if (incvLastRewardBlock > _lastUpdateBlock) {
                incvAccRewardPerToken = incvLastRewardBlock.sub(_lastUpdateBlock)
                .mul(_incvRewardPerBlock).div(_totalStaked)
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

    function rewardInfo() external view returns (uint256 cBlockNumber, uint256 rewardPerBlock, uint256 rewardFinishBlock, uint256 rewardFinishTime, uint256 rewardLockTime) {
        cBlockNumber = blockNumber();
        rewardFinishBlock = finishBlock;
        rewardPerBlock = _rewardPerBlock.div(1e18);
        if( cBlockNumber < finishBlock){
            rewardFinishTime = block.timestamp.add(finishBlock.sub(cBlockNumber).mul(15));
        }else{
            rewardFinishTime = block.timestamp.sub(cBlockNumber.sub(finishBlock).mul(15));
        }
        rewardLockTime=0;
    }

    function incvRewardInfo() external view returns (uint256 cBlockNumber, uint256 incvRewardPerBlock, uint256 incvRewardFinishBlock, uint256 incvRewardFinishTime, uint256 incvRewardLockTime) {
        cBlockNumber = blockNumber();
        incvRewardFinishBlock = incvFinishBlock;
        incvRewardPerBlock = _incvRewardPerBlock.div(1e18);
        if( cBlockNumber < incvFinishBlock){
            incvRewardFinishTime = block.timestamp.add(incvFinishBlock.sub(cBlockNumber).mul(15));
        }else{
            incvRewardFinishTime = block.timestamp.sub(cBlockNumber.sub(incvFinishBlock).mul(15));
        }
        incvRewardLockTime=incvStartReleasingTime;
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

        uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
        if (lastRewardBlock > _lastUpdateBlock) {
            accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock)
            .mul(_rewardPerBlock).div(_totalStaked.add(amount))
            .add(accRewardPerToken);
        }

        uint256 incvLastRewardBlock = cnBlock < incvFinishBlock ? cnBlock : incvFinishBlock;
        if (incvLastRewardBlock > _lastUpdateBlock) {
            incvAccRewardPerToken = incvLastRewardBlock.sub(_lastUpdateBlock)
            .mul(_incvRewardPerBlock).div(_totalStaked.add(amount))
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

    function lastUpdateBlock() external view returns(uint256) {
        return _lastUpdateBlock;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function blockNumber() public view returns (uint256) {
        if(timeFrezed){
            return frezedBlock + blockShift;
        }
        return block.number +blockShift;
    }
    
    function getCurrentTime() public view returns(uint256){
        if(timeFrezed){
            return frezedTime  + (blockShift *15);
        }
        return block.timestamp  + (blockShift *15);
    }
    
    function getVestedAmount(uint256 lockedAmount, uint256 time) internal  view returns(uint256){
        
        // if time < StartReleasingTime: then return 0
        if(time < incvStartReleasingTime){
            return 0;
        }

        // if locked amount 0 return 0
        if (lockedAmount == 0){
            return 0;
        }

        // elapsedBatchCount = ((time - startReleasingTime) / batchPeriod) + 1
        uint256 elapsedBatchCount =
        time.sub(incvStartReleasingTime)
        .div(incvBatchPeriod)
        .add(1);

        // vestedAmount = lockedAmount  * elapsedBatchCount / batchCount
        uint256  vestedAmount =
        lockedAmount
        .mul(elapsedBatchCount)
        .div(incvBatchCount);

        if(vestedAmount > lockedAmount){
            vestedAmount = lockedAmount;
        }

        return vestedAmount;
    }
    
    
    function incvRewardClaim() public returns(uint256 amount){
        updateReward(msg.sender);
        amount = getVestedAmount(_incvRewards[msg.sender], getCurrentTime()).sub(incvWithdrawn[msg.sender]);
        
        if(amount > 0){
            incvWithdrawn[msg.sender] = incvWithdrawn[msg.sender].add(amount);

            courtToken.mint(msg.sender, amount);

            emit ClaimIncentiveReward(msg.sender, amount);
        }
    }
    
    function getBeneficiaryInfo(address ibeneficiary) external view
    returns(address beneficiary,
        uint256 totalLocked,
        uint256 withdrawn,
        uint256 releasableAmount,
        uint256 nextBatchTime,
        uint256 currentTime){

        beneficiary = ibeneficiary;
        currentTime = getCurrentTime();
        
        totalLocked = _incvRewards[ibeneficiary];
        withdrawn = incvWithdrawn[ibeneficiary];
        ( , uint256 incvReward) = rewards(ibeneficiary);
        releasableAmount = getVestedAmount(incvReward, getCurrentTime()).sub(incvWithdrawn[beneficiary]);
        nextBatchTime = getIncNextBatchTime(incvReward, ibeneficiary, currentTime);
        
    }
    
    function getIncNextBatchTime(uint256 lockedAmount, address beneficiary, uint256 time) internal view returns(uint256){

        // if total vested equal to total locked then return 0
        if(getVestedAmount(lockedAmount, time) == _incvRewards[beneficiary]){
            return 0;
        }

        // if time less than startReleasingTime: then return sartReleasingTime
        if(time <= incvStartReleasingTime){
            return incvStartReleasingTime;
        }

        // find the next batch time
        uint256 elapsedBatchCount =
        time.sub(incvStartReleasingTime)
        .div(incvBatchPeriod)
        .add(1);

        uint256 nextBatchTime =
        elapsedBatchCount
        .mul(incvBatchPeriod)
        .add(incvStartReleasingTime);

        return nextBatchTime;

    }

    ///// for demo
    bool public timeFrezed;
    uint256 frezedBlock =0;
    uint256 frezedTime = 0;
    function frezeBlock(bool flag) public{
        frezedBlock = blockNumber().sub(blockShift);
        frezedTime = getCurrentTime().sub(blockShift*15);
        timeFrezed = flag;
    }
    function isTimeFrerzed() public view returns(bool){
        return timeFrezed;
    }
    uint256 public blockShift;
    function increaseBlock(uint256 count) public{
        blockShift+=count;
    }
    
    
    function getblockShift() external view returns(uint256){
        return blockShift;
    }
    
}
