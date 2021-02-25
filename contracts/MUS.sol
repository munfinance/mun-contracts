pragma solidity =0.6.8;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import './ERC20UpgradeSafe.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

contract MUS is Initializable, OwnableUpgradeSafe, ERC20UpgradeSafe {
    using SafeMath for uint256;
    mapping (address => bool) public isFrozen;
    address public nftManager;

    modifier onlyManager {
        require(msg.sender == nftManager || msg.sender == owner(), 'MUS: Only executable by the NFTManager contract or owner');
        _;
    }
    
    function initialize(address _nftManager) public initializer {
        __Ownable_init();
        __ERC20_init('MUS', 'MUS');
        // Decimals are set to 18 by default
        nftManager = _nftManager;
    }

    function setManager(address _nftManager) public onlyOwner {
        nftManager = _nftManager;
    }

    function mint(address _to, uint256 _amount) public onlyManager {
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyManager {
        _burn(_account, _amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isFrozen[msg.sender], 'MUS: Your transfers are frozen');
        require(sender != address(0), "MUS: ERC20: transfer from the zero address");
        require(recipient != address(0), "MUS: ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "MUS: ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function extractETHIfStuck() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractTokenIfStuck(address _token, uint256 _amount) public onlyOwner {
        ERC20UpgradeSafe(_token).transfer(owner(), _amount);
    }

    function freezeTokens(address _of) public onlyOwner {
        isFrozen[_of] = true;
    }
    
    function unFreezeTokens(address _of) public onlyOwner {
        isFrozen[_of] = false;
    }
}