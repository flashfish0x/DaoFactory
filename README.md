# SUBDAO Factory

The subDAO factory is a one click factory to create all the parts needed for a Yearn SubDAO.

**After the first use it is very cheap to use as it creates all contracts via minimal proxies**

## It creates three contracts:
### Governance Token
The governance token is based on COMP token. It has snapshots and delegation built in to make it useful as a governance token. It is used to vote in the voting contract but could also be used for more complex voting situations.

![initial supply split four ways](https://github.com/flashfish0x/DaoFactory/blob/main/images/subdao%20factory.png?raw=true)


### Team Vesting Contract
The original team allocation is locked and vested over a period of time.

### Voter
The voter is a simplified version of the compound governorBravo. There is only one vote that happens and that is what address to set as owner of the contract. It automatically starts a voting period after some amount of time. Users can vote based on the tokens they hold or are delegated to them at a snapshot at block voteStart. At block voteEnd the winning address gets control over the contract.

The remaining supply of the governance token is locked in this contract. Meaning it can only be accessed after the vote is over.

The winner can use executeTransaction to execute any transaction. This means that contracts can have admin set to the Voter contract, and be locked until the vote is over. This allows decentralisation to happen by locking powers until full decentralisation has been achieved. 

For instance the time period could be set for 6 months with a vote period of 1 week. This gives the team six months to run the project before the community has a week to vote on how to continue governance. Ideally the initital team or an activist team will put a good proposal together and get votes.

By locking most of the treasury until this point the community can be confident that the team won't rug.

## And locks some governance tokens in veYFI
The tokens locked in veYFI are streamed out over a period of time. Any veYFI holder can claim all the subDAO tokens they have accumulated. The UI will look a bit like below. The user can see what their apy is in each of the tokens. The longer they lock up YFI for the more subDAO tokens they will earn.

![initial supply split four ways](https://github.com/flashfish0x/DaoFactory/blob/main/images/spookswap.png?raw=true)

## How to Run
Run function newSubDao.
```
function newSubDao(
        string memory _name, 
        string memory _symbol, 
        address initialMultisig, 
        uint256[4] memory initialSupplyBreakdown,
        uint256 launchPhase, 
        uint256 votePeriod,
        uint256 vestCliff,
        uint256 vestDuration) external{
```

_name and _symbol of the new governance token.
initialMultisig is the address of the multisig used by the originating team.
initialSupplyBreakdown is the breakdown of how to split up the total supply. See below
launchPhase how long in blocks the initial team has before voting starts on how the dao should be run
votePeriod how long in blocks before the vote ends
vestCliff how long the cliff is before original team get start receiving their share
vestDuration how long in total the vest of the initial teams' tokens last for




