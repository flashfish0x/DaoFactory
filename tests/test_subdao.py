from itertools import count
from brownie import Wei, reverts
import brownie



def test_subdaos(web3,LiquidityGuageV4, SubDaoFactory, gov, whale, yfi):

    factory = gov.deploy(SubDaoFactory)
    ve_yfi = gov.deploy(LiquidityGuageV4, yfi, factory)
    factory = gov.deploy(SubDaoFactory)