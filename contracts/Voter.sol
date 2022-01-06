// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract Voter{
    using SafeERC20 for IERC20;

    address public winner;
    uint256 voteEnd;

    function clone() external returns (address instance) {
        instance = Clones.clone(address(this));
        Voter(instance).initialise();
    }

    function initialise() external{
        require(voteEnd == 0, "already initialised");

    }

    function vote(address candidate){
        
    }

    //after vote is over the winner can transfer tokens
    function withdraw(address token, uint256 amount){
        require(msg.sender == winner);
        IERC20(token).trasfer(winner, amount);
    }

}