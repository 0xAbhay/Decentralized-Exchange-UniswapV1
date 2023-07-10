// SPDX-License-Identifier: SEE LICENSE IN UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiniToken is ERC20 {

    constructor () ERC20("Mini", "MT"){
        _mint(msg.sender , 100000 * 10 ** decimals());
    }
}