pragma solidity ^0.5.16;

import "../../contracts/ERC20/CourtToken.sol";

contract CourtTokenMock is CourtToken {

    function setGovernanace(address account) public {
        governance = account;
    }

}
