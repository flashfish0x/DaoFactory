from itertools import count
from brownie import Wei, reverts
import brownie



def test_subdaos(web3,LiquidityGuageV4, SimpleVesting, Voter, chain, GovernanceToken, SubDaoFactory, gov, yfi_whale, yfi):

    factory = gov.deploy(SubDaoFactory)
    ve_yfi = gov.deploy(LiquidityGuageV4, yfi, factory)
    factory.setVeYfi(ve_yfi)

    yfi.approve(ve_yfi, 2**256-1, {'from': yfi_whale})
    #lockup some yfi in the veYFI
    ve_yfi.deposit(100*1e18, {'from': yfi_whale})

    to_yfi = 50*1e18
    to_locked_treasury = 50*1e18
    to_open_treasury = 25*1e18
    to_team = 25*1e18

    vestingLength = 1000 # seconds
    cliffLength = 500

    share = [to_yfi, to_locked_treasury, to_open_treasury, to_team]

    launchPhase = 10 # 10 blocks (real life will be more like 6 months)
    votePeriod = 10 # 10 blocks (real life will be more like 7 days)

   
    tx = factory.newSubDao("poolpiDAO", "POO", gov, share, launchPhase, votePeriod, cliffLength, vestingLength)
    
    token = GovernanceToken.at(tx.events["NewSubDao"]["govToken"])
    voter = Voter.at(tx.events["NewSubDao"]["voter"])
    vester = SimpleVesting.at(tx.events["NewSubDao"]["teamVester"])

    assert token.totalSupply() == to_yfi + to_locked_treasury + to_open_treasury + to_team
    assert token.balanceOf(voter) == to_locked_treasury
    assert token.balanceOf(ve_yfi) == to_yfi
    assert token.balanceOf(gov) == to_team

    chain.mine(1)
    assert ve_yfi.claimable_reward(yfi_whale, token) > 0

    tx2 = factory.newSubDao("poolpiDAO2", "POO2", gov, share, launchPhase, votePeriod, cliffLength, vestingLength)
    
    token2 = GovernanceToken.at(tx.events["NewSubDao"]["govToken"])
    voter2 = Voter.at(tx.events["NewSubDao"]["voter"])
    chain.mine(1)
    assert ve_yfi.claimable_reward(yfi_whale, token2) > 0
    token.delegate(yfi_whale, {'from': yfi_whale})

    tx = ve_yfi.claim_rewards({'from': yfi_whale})
    print(tx.events)
    assert token.balanceOf(yfi_whale) > 0

    with brownie.reverts():
        voter.castVote(yfi_whale, {"from": yfi_whale})

    chain.mine(10)
    tx = voter.castVote(yfi_whale, {"from": yfi_whale})
    print(tx.events)
    print(token.getPriorVotes(yfi_whale, voter.voteStart()))
    assert voter.currentLeader() == yfi_whale

    #vote hasnt ended yet
    with brownie.reverts():
        voter.endVote({"from": yfi_whale})

    chain.mine(10)

    voter.endVote({"from": yfi_whale})
    assert voter.winner() == yfi_whale

    assert vester.totalVested() == 0
    chain.sleep(600)
    chain.mine(1)
    toWithdraw = vester.totalVested()
    print(toWithdraw/1e18)
    assert toWithdraw > 0

    vester.claim(gov, {'from': gov} )
    toWithdraw = vester.withdrawableAmount()
    assert toWithdraw == 0



