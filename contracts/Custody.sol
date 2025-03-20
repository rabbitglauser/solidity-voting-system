// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Custody is Ownable {
    IERC20 public custodyToken;

    event TokensDeposited(address indexed user, uint amount);
    event TokensWithdrawn(address indexed user, uint amount);

    constructor(address _tokenAddress) {
        custodyToken = IERC20(_tokenAddress);
    }

    // Function to deposit tokens into custody
    function depositTokens(uint _amount) external {
        require(custodyToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        emit TokensDeposited(msg.sender, _amount);
    }

    // Function to withdraw tokens from custody
    function withdrawTokens(uint _amount) external onlyOwner {
        require(custodyToken.transfer(msg.sender, _amount), "Token transfer failed");
        emit TokensWithdrawn(msg.sender, _amount);
    }
}