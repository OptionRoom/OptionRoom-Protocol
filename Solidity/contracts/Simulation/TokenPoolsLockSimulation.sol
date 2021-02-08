pragma solidity ^0.5.16;

import "../RoomLock/TokenVestingPools.sol";

contract TokenPoolsLockSimulation is TokenVestingPools{
    uint256 public CurrentTime;

    constructor () internal {
	   CurrentTime = block.timestamp;
    }

    function getCurrentTime() public view returns(uint256){
        return CurrentTime;
    }

    function setCurrentTime(uint256 time) public{
        require(time>CurrentTime,"time only can be increased");
        CurrentTime = time;
    }
}


contract TokenPoolsLockSimulationDummyAddress is TokenVestingPools{
    uint256 public CurrentTime;

    constructor () public TokenVestingPools(0x088441249d9D92e9592AcbfbB6DD1Ce9DF01723A){
	   CurrentTime = block.timestamp;
	   uint8 pool_0 = _addVestingPool("test0pool", 1614556800, 150, 1 days);
	   uint8 pool_1 = _addVestingPool("test0pool", 1614556800, 300, 1 days);

	   // pool_0
       _addBeneficiary(pool_0, 0xc06A06CeCB585Bb5247e1CC2a96263f59fC34613,5000000); //5,000,000 Token
	   _addBeneficiary(pool_0, 0x0eD7Fb82aeb731ed4660fB705132bbf67EE7960C,1000000); //1,000,000 Token

	   // pool_1
	   _addBeneficiary(pool_1, 0x0eD7Fb82aeb731ed4660fB705132bbf67EE7960C,1000000); //1,000,000 Token
    }

}
