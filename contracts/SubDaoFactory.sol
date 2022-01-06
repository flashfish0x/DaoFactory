// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GovernanceToken.sol";

interface VeYFI {
    function add_reward(address reward, address distributor) external;
}



//create all the steps for a subdao
contract SubDaoFactory is AccessControl{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    VeYFI public veYfi;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function newSubDao(string memory name, string memory symbol, address initialMultisig, uint256 amount, uint256 toYfi, toLockedTreasury, toOpenTreasury, toTeam) external returns (address){

        GovernanceToken gt = new GovernanceToken(name, symbol);
        uint256 total = toYfi.add(toTreasury).add(toOpenTreasury).add(toTeam);

        
    }

    //we give governance to simple. it waits until vote is set.

    function setVeYfi(address _veYfi) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin Only");

        veYfi = VeYFI(_veYfi);
    }



}