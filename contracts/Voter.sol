// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./GovernanceToken.sol";

//simplified voter with inspiration from compound governorbravo.
//automatic vote after a certain period to see who takes over the subDao
//snapshot of voters is taken at the block the voting starts
contract Voter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event ExecuteTransaction(
        address indexed target,
        uint256 value,
        string signature,
        bytes data
    );
    event VoteCast(
        address voter,
        address candidate,
        uint96 votesCast,
        string reason
    );

    address public winner;
    uint256 public launchBlock;
    uint256 public voteStart;
    uint256 public voteEnd;
    GovernanceToken public govToken;
    mapping(address => Receipt) public receipts;
    mapping(address => uint256) public votesCount;
    address public currentLeader;
    uint256 public currentHighestVotes;

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted;
        address newGovernor;
        uint96 votes;
    }

    function initialise(
        uint256 launchPhase,
        uint256 votePeriod,
        address govTokenAddress
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(voteEnd == 0, "already initialised");

        launchBlock = block.number;
        voteStart = launchBlock.add(launchPhase);
        voteEnd = voteStart.add(votePeriod);

        govToken = GovernanceToken(govTokenAddress);

        return (launchBlock, voteStart, voteEnd);
    }

    function castVote(address newGovernor) external {
        emit VoteCast(
            msg.sender,
            newGovernor,
            castVoteInternal(msg.sender, newGovernor),
            ""
        );
    }

    function castVoteWithReason(address newGovernor, string calldata reason)
        external
    {
        emit VoteCast(
            msg.sender,
            newGovernor,
            castVoteInternal(msg.sender, newGovernor),
            reason
        );
    }

    function castVoteInternal(address voter, address newGovernor)
        internal
        returns (uint96)
    {
        require(
            block.number > voteStart && block.number < voteEnd,
            "castVoteInternal: voting is closed"
        );

        Receipt storage receipt = receipts[voter];
        require(
            receipt.hasVoted == false,
            "castVoteInternal: voter already voted"
        );
        uint96 votes = govToken.getPriorVotes(voter, voteStart);

        uint256 tVotes;
        tVotes = votesCount[newGovernor] + votes; //should be no overflow risk
        votesCount[newGovernor] = tVotes;

        if (currentHighestVotes < tVotes) {
            currentHighestVotes = tVotes;
            currentLeader = newGovernor;
        }

        receipt.hasVoted = true;
        receipt.newGovernor = newGovernor;
        receipt.votes = votes;

        return votes;
    }

    function endVote() public {
        require(block.number >= voteEnd, "vote not ended");
        require(winner == address(0), "winner already declared");

        winner = currentLeader;
    }

    //after winning the winner can execute any tx. so this voter can be set as governance to any contract. also they can access the tokens stored here
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public payable returns (bytes memory) {
        require(
            msg.sender == winner,
            "executeTransaction: Call must come from governance"
        );

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, "executeTransaction: Transaction execution reverted");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}
