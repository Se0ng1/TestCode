// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address dst, uint256 amount) external;

    function transferFrom(address src, address dst, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool success);

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function delegate(address delegatee) external;

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    /////
}


