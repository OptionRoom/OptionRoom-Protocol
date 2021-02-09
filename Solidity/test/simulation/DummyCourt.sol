pragma solidity ^0.5.16;

import "../../contracts/ERC20/RoomToken.sol";

contract DumyCourt is ERC20Detailed {
  
  constructor () public ERC20Detailed("DumyCourt", "DumyCourt", 18) {
      _mint(msg.sender,1e18 ); // minting 100,000,000 token with 18 decimals
  }
  
  function mint(address account, uint amount) public{
    _mint(account,amount);
      
  }

}