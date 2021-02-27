pragma solidity 0.6.8;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

contract CrowdsaleV2 is Initializable, OwnableUpgradeSafe {
    using SafeMath for uint256;

    address public mun;
    uint256 public rate;
    uint256 public startDate;
    uint256 public duration;
    uint256 public tokensPurchased;

    function initialize(address _mun) external initializer {
        __Ownable_init();
        mun = _mun;
        rate = 125e17; // 12.5 MUN per 1 BNB
        startDate = now;
        duration = 30 days;
    }

    receive() external payable {
        buy();
    }

    function buy() public payable {
        uint256 thisBalance = IERC20(mun).balanceOf(address(this));
        uint256 tokensToReceive = msg.value.mul(rate).div(1e18);
        require(thisBalance >= tokensToReceive, 'Not enough tokens to purchase');
        require(now < duration + startDate, 'The crowdsale has ended');
        payable(owner()).transfer(msg.value);
        IERC20(mun).transfer(msg.sender, tokensToReceive);
        tokensPurchased = tokensPurchased.add(tokensToReceive);
    }

    function setMun(address _mun) external onlyOwner {
        mun = _mun;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function extractTokensIfStuck(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() external onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }
}