import pytest
from brownie import Wei, config



@pytest.fixture
def whale(accounts,dai):
    #compounddai
    acc = accounts.at('0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643', force=True)

    assert dai.balanceOf(acc) > 0

    yield acc



@pytest.fixture
def gov(accounts):
    #ychad.eth
    acc = accounts.at('0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52', force=True)

    yield acc


@pytest.fixture
def dai(interface):
    yield interface.ERC20('0x6b175474e89094c44da98b954eedeac495271d0f')

@pytest.fixture
def yfi(interface):
    yield interface.ERC20('0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e')

