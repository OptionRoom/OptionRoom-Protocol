pragma solidity ^0.5.16;

import "./TokenVestingPools.sol";

contract TeamRoomLock is TokenVestingPools{


    constructor () public TokenVestingPools(0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64){

        // check https://www.epochconverter.com/ for timestamp

        // Team tokens (10M) locked till Jan 01, 2022
        // and will be relesed each 3 months by 25%
        // 1640995200= January 1, 2022 12:00:00 AM GMT
        // team tokens: 10,000,000 Token
        uint8 teamLockPool = _addVestingPool("Team Lock" , 1640995200, 4, 90 days);

        _addBeneficiary(teamLockPool, 0x4608f8245258e93aF27A15f9fBA17515149f4435,4000000); // 4,000,000 Tokens
        _addBeneficiary(teamLockPool, 0x5a4D85F03d9C45907617bABcDc7f4C5599c4cE19,2000000); // 2,000,000 Tokens
        _addBeneficiary(teamLockPool, 0x28eFeB6bf726bc9b1b2b989Cada5D9C95CfBb38C,1333334); // 1,333,334 Tokens
        _addBeneficiary(teamLockPool, 0x971945b040B126dCe5aD2982FBD2a72d4Ba3966c,1333333); // 1,333,333 Tokens
        _addBeneficiary(teamLockPool, 0xd558D2A872185C64DE4BF2a63Ad0Bc307f861997,1333333); // 1,333,333 Tokens
    }
}
