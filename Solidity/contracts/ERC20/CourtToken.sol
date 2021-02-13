pragma solidity ^0.5.16;

import "./ERC20Detailed.sol";


contract CourtToken is ERC20Detailed {

    uint256 public capital = 500000*1e18;
    address public governance;
    mapping(address=>bool) public minters;
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CapitalChanged(uint256 previousCapital, uint256 newCapital);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
  
    constructor () public ERC20Detailed("OptionRoom Token", "ROOM", 18) {
        governance = _msgSender();
        _mint(_msgSender(),1e18 ); // minting 1 token with 18 decimals
    }
  
    function mint(address account, uint256 amount) public{
        require(minters[_msgSender()] == true,"Caller is not minter");
        require(totalSupply().add(amount)<= capital,"Court: capital exceeded");
        
        _mint(account,amount);
      
    }
    
    function transferOwnership(address newOwner) public  onlyGovernance{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        emit OwnershipTransferred(governance, newOwner);
        governance = newOwner;
    }
    
    function changeCapital(uint256 newCapital) public onlyGovernance{
        require(newCapital>totalSupply(),"total supplay excedd capital");
        
        emit CapitalChanged(capital, newCapital);
        capital = newCapital;
    }
    
    function addMinter(address minter) public onlyGovernance{
        
        emit MinterAdded(minter);
        minters[minter] = true;
    }
    
    function removeMinter(address minter) public onlyGovernance{
        
        emit MinterRemoved(minter);
        minters[minter] = false;
    }
    
    modifier onlyGovernance() {
        require(governance == _msgSender(), "Ownable: caller is not the Governanc");
        _;
      
    }

}
