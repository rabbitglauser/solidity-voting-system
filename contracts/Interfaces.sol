// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IMultiSigWallet {
    function executeTransaction(address payable to, uint256 value, bytes calldata data) external;
}