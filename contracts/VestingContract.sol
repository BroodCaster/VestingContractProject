// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
/**
 * @title _tokenVesting
 * @dev A _token holder contract that can release its _token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract VestingContract is Ownable, ReentrancyGuard {
 using SafeMath for uint256;
 using SafeERC20 for IERC20;


  event Released(uint256 amount);
  event Revoked();

  // beneficiary of _tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
   

  bool public revocable;
  uint256 public released;
  bool public revoked;

//   mapping (address => uint256) public released;
//   mapping (address => bool) public revoked;

 IERC20 immutable private _token;

 constructor(address token_){
    require(token_ != address(0x0));
    _token = IERC20(token_);
 }

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 _token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested _tokens are transferred
   * @param _cliff duration in seconds of the cliff in which _tokens will begin to vest
   * @param _duration duration in seconds of the period in which the _tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function createtokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public{
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }


  function release() public {
    uint256 unreleased = releasableAmount();

    require(unreleased > 0);

    released = unreleased;

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }


  function revoke() public onlyOwner {
    require(revocable);
    require(!revoked);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount();
    uint256 refund = balance.sub(unreleased);

    revoked = true;
    
    address contractOwner = owner();
    _token.transfer(contractOwner, refund);

    emit Revoked();
  }


  function releasableAmount() public view returns (uint256) {
    return vestedAmount().sub(released);
  }

 
  function vestedAmount() public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}