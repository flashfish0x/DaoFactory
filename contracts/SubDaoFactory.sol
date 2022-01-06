// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GovernanceToken.sol";
import "./Voter.sol";

interface VeYFI {
    function add_reward(address reward, address distributor) external;
    function deposit_reward_token(address reward, uint256 amount) external;
}



//create all the steps for a subdao
contract SubDaoFactory is AccessControl{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event NewSubDao(address govToken, address voter, uint256 voteStart, uint256 voteEnd);


    address public tokenImplementation;
    address public voterImplementation;
    mapping(address => DaoInfo) daos;

    // Info of each subDao.
    struct DaoInfo {
        address voter;
        uint256 launchBlock;
        uint256 voteStart; 
        uint256 voteEnd;
        address originalGov;
    }

    address public veYfi;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function newSubDao(string memory _name, string memory _symbol, address initialMultisig, uint256 toYfi, uint256 toLockedTreasury, uint256 toOpenTreasury, uint256 toTeam, uint256 launchPhase, uint256 votePeriod) external{
        require(veYfi != address(0), "veYFI not set");

        uint256 totalSupply = toYfi.add(toLockedTreasury).add(toOpenTreasury).add(toTeam); 

        //create governance token
        GovernanceToken gt;

        if(tokenImplementation == address(0)){
            gt = new GovernanceToken();
        }else{
            gt = GovernanceToken(clone(tokenImplementation));
            
        }
        gt.initialise(_name, _symbol, totalSupply);

        Voter vt;
        if(voterImplementation == address(0)){
            vt = new Voter();
        }else{
            vt = Voter(clone(voterImplementation));
        }
        (uint256 launchBlock, uint256 voteStart, uint256 voteEnd) = vt.initialise(launchPhase, votePeriod, address(gt));

        daos[address(gt)] = DaoInfo({
            voter: address(vt),
            launchBlock: launchBlock,
            voteStart: voteStart,
            voteEnd: voteEnd,
            originalGov: initialMultisig
        });

        //we are using the outthebox liquidity guage. which means 1 week liquidity mining. havent bothered changing as this isnt the true veYFI
        VeYFI(veYfi).add_reward(address(gt), address(this));
        gt.approve(veYfi, toYfi);
        VeYFI(veYfi).deposit_reward_token(address(gt), toYfi);

        
        gt.transfer(address(vt), toLockedTreasury);
        gt.transfer(initialMultisig, toTeam);

        emit NewSubDao(address(gt), address(vt), voteStart, voteEnd);
        
    }

    //we give governance to simple. it waits until vote is set.

    function setVeYfi(address _veYfi) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin Only");

        veYfi = _veYfi;
    }


    //simple cloner for minimal proxy by openzeppelin
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }



}