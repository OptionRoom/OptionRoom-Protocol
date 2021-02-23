// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";


contract NFTStake is IERC1155Receiver,ReentrancyGuard {

    using SafeMath for uint256;

    IERC20  roomToken = IERC20(0xdDF0667c0694d1AEbED930E30ea06b69BB0D868E);  // correct 0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64

    // todo: set the correct ROOm NFT
    IERC1155 NFTToken = IERC1155(0x40c45a58aeFF1c55Bd268e1c0b3fdaFD1E33CDf0);

    uint256 _finishBlock;
    address private _roomTokenRewardsReservoirAddress;
    address private _owner;

    mapping(uint256 => mapping(address => bool)) nftLockedToStakeRoom;

    mapping(uint256 => uint256) private _totalStaked;
    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(uint256 => uint256) _lastUpdateBlock;
    mapping(uint256 => uint256) _accRewardPerToken;
    mapping(uint256 => uint256) _rewardPerBlock;

    mapping(uint256 => mapping(address => uint256)) private _prevAccRewardPerToken; // previous accumulative reward per token (for a user)
    mapping(uint256 => mapping(address => uint256)) private _rewards; // rewards balances

    event Staked(uint256 poolId, address indexed user, uint256 amount);
    event Unstaked(uint256 poolId, address indexed user, uint256 amount);
    event ClaimReward(uint256 poolId, address indexed user, uint256 reward);
    event RoomTokenWalletEmpty();

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4) external override view returns (bool) {
        return true;
    }

    constructor (address rewardWallet) public {
        _owner = msg.sender;
        
        _roomTokenRewardsReservoirAddress = rewardWallet;

        uint256 rewardBlockCount = 1036800;  // 5760 * 30 * 6; six months = 1,036,800 blocks
        
        uint256 totalRewards0 = 24937e18; // 24,937 room Token total rewards for pool0 (Tier1)
        uint256 totalRewards1 = 30922e18; // 30,922 room Token total rewards for pool1 (Tier2)
        uint256 totalRewards2 = 36907e18; // 36,907 room Token total rewards for pool2 (Tier3)
        uint256 totalRewards3 = 44887e18; // 44,887 room Token total rewards for pool3 (Tier4)
        uint256 totalRewards4 = 62344e18; // 62,344 room Token total rewards for pool4 (Tier5)
        
        _finishBlock = blockNumber().add(rewardBlockCount);
       
        _rewardPerBlock[0] = totalRewards0.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[1] = totalRewards1.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[2] = totalRewards2.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[3] = totalRewards3.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[4] = totalRewards4.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision

        _lastUpdateBlock[0] = blockNumber();
        _lastUpdateBlock[1] = blockNumber();
        _lastUpdateBlock[2] = blockNumber();
        _lastUpdateBlock[3] = blockNumber();
        _lastUpdateBlock[4] = blockNumber();
    }

    function stake(uint256 poolId, uint256 amount) public {
        updateReward(poolId, msg.sender);

        if (amount > 0) {
            if (nftLockedToStakeRoom[poolId][msg.sender] == false) {
                nftLockedToStakeRoom[poolId][msg.sender] = true;
                NFTToken.safeTransferFrom(msg.sender, address(this), poolId, 1, "");
            }

            _totalStaked[poolId] = _totalStaked[poolId].add(amount);
            _balances[poolId][msg.sender] = _balances[poolId][msg.sender].add(amount);

            roomToken.transferFrom(msg.sender, address(this), amount);

            emit Staked(poolId, msg.sender, amount);
        }
    }

    function unstake(uint256 poolId, uint256 amount, bool claim) public {
        updateReward(poolId, msg.sender);

        if (amount > 0) {
            _totalStaked[poolId] = _totalStaked[poolId].sub(amount);
            _balances[poolId][msg.sender] = _balances[poolId][msg.sender].sub(amount);
            // Send Room token staked to the original owner.
            roomToken.transfer(msg.sender, amount);
            emit Unstaked(poolId, msg.sender, amount);
        }

        if (claim) {
            uint256 reward = _rewards[poolId][msg.sender];

            uint256 walletBalanace = roomToken.balanceOf(_roomTokenRewardsReservoirAddress);

            if (reward > 0 && walletBalanace > reward) {
                _rewards[poolId][msg.sender] = 0;
                // Instead of minting we transfer from this contract address to the message sender.
                roomToken.transferFrom(_roomTokenRewardsReservoirAddress, msg.sender, reward);
                emit ClaimReward(poolId, msg.sender, reward);
            }
        }
    }

    function exit(uint256 poolId) public nonReentrant{
        unstake(poolId, _balances[poolId][msg.sender], true);
        if (nftLockedToStakeRoom[poolId][msg.sender]) {
            nftLockedToStakeRoom[poolId][msg.sender] = false;
            NFTToken.safeTransferFrom(address(this), msg.sender, poolId, 1, "");
        }
    }

    function claimReward(uint256 poolId) public returns (uint256 reward, uint8 reason) {
        updateReward(poolId, msg.sender);
        // 0 means successful operation for transferring tokens.
        reason = 0;
        reward = _rewards[poolId][msg.sender];

        // TODO: chose if or require
        if (reward > 0) {

            uint256 walletBalanace = roomToken.balanceOf(_roomTokenRewardsReservoirAddress);
            if (walletBalanace < reward) {
                // 1 means the wallet is empty.
                reason = 1;
                emit RoomTokenWalletEmpty();
            } else {
                _rewards[poolId][msg.sender] = 0;
                roomToken.transferFrom(_roomTokenRewardsReservoirAddress, msg.sender, reward);
                emit ClaimReward(poolId, msg.sender, reward);
            }
        }
        return (reward, reason);
    }

    function updateReward(uint256 poolId, address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked[poolId] > 0) {

            uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
            if (lastRewardBlock > _lastUpdateBlock[poolId]) {
                _accRewardPerToken[poolId] = lastRewardBlock.sub(_lastUpdateBlock[poolId])
                .mul(_rewardPerBlock[poolId]).div(_totalStaked[poolId])
                .add(_accRewardPerToken[poolId]);
            }
        }

        _lastUpdateBlock[poolId] = cnBlock;

        if (account != address(0)) {

            uint256 accRewardPerTokenForUser = _accRewardPerToken[poolId].sub(_prevAccRewardPerToken[poolId][account]);

            if (accRewardPerTokenForUser > 0) {
                _rewards[poolId][account] =
                _balances[poolId][account]
                .mul(accRewardPerTokenForUser)
                .div(1e18)
                .add(_rewards[poolId][account]);

                _prevAccRewardPerToken[poolId][account] = _accRewardPerToken[poolId];
            }
        }
    }

    function rewards(uint256 poolId, address account) external view returns (uint256 reward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken[poolId];

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked[poolId] > 0) {
            uint256 lastRewardBlock = cnBlock < _finishBlock ? cnBlock : _finishBlock;
            if (lastRewardBlock > _lastUpdateBlock[poolId]) {
                accRewardPerToken = lastRewardBlock.sub(_lastUpdateBlock[poolId])
                .mul(_rewardPerBlock[poolId]).div(_totalStaked[poolId])
                .add(accRewardPerToken);
            }
        }

        reward = _balances[poolId][account]
        .mul(accRewardPerToken.sub(_prevAccRewardPerToken[poolId][account]))
        .div(1e18)
        .add(_rewards[poolId][account]);
    }

    function totalStaked(uint256 poolId) public view returns (uint256){
        return _totalStaked[poolId];
    }

    function balanceOf(uint256 poolId, address account) public view returns (uint256) {
        return _balances[poolId][account];
    }


    function blockNumber() public view returns (uint256) {
        return block.number;
    }


}
