// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20
{
    constructor(uint256 _initialAmount ) ERC20("MyToken","MTK")
    {
        _mint(msg.sender, _initialAmount );
    }
}
