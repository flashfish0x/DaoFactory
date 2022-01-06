pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract SimpleVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Withdrawn(uint256 amount);

    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    IERC20 public token;

    uint256 public withdrawn;

    function initialise(
        address _token,
        address _beneficiary,
        uint256 _cliff,
        uint256 _duration
    ) public {
        require(_beneficiary != address(0));
        require(beneficiary == address(0)); // only callable once
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        duration = _duration;
        start = now;
        cliff = start.add(_cliff);

        token = IERC20(_token);
    }

    function claim(address target) public {
        uint256 withdrawable = withdrawableAmount();
        claim(withdrawable, target);
    }

    function claim(uint256 amount, address target) public {
        require(msg.sender == beneficiary);
        uint256 withdrawable = withdrawableAmount();

        require(withdrawable >= amount);

        token.safeTransfer(target, amount);
        withdrawn = withdrawn.add(amount);

        emit Withdrawn(amount);
    }

    function withdrawableAmount() public view returns (uint256) {
        return totalVested().sub(withdrawn);
    }

    //including withdrawn
    function totalVested() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(withdrawn);

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }
}
