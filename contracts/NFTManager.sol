pragma solidity =0.6.8;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

interface IMUS {
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}

contract NFTManager is Initializable, OwnableUpgradeSafe, ERC721UpgradeSafe {
    using SafeMath for uint256;
    
    // Time staked in blocks
    mapping (address => uint256) public timeStaked;
    mapping (address => uint256) public amountStaked;
    // TokenURI => blueprint
    // the array is a Blueprint with 4 elements. We use this method instead of a struct since structs are not upgradeable
    // [0] uint256 mintMax;
    // [1] uint256 currentMint; // How many tokens of this type have been minted already
    // [2] uint256 munCost;
    // [3] uint256 musCost;
    mapping (string => uint256[4]) public blueprints;
    mapping (string => bool) public blueprintExists;
    // Token ID -> tokenURI without baseURI
    mapping (uint256 => string) public myTokenURI;
    string[] public tokenURIs;
    uint256[] public mintedTokenIds;
    uint256 public lastId;
    address public mun;
    address public mus;
    uint256 public oneDayInBlocks;

    function initialize(address _mun, address _mus, string memory baseUri_) public initializer {
        __Ownable_init();
        __ERC721_init('NFTManager', 'MUNNFT');
        _setBaseURI(baseUri_);
        mun = _mun;
        mus = _mus;
        oneDayInBlocks = 6500;
    }

    function setMUN(address _mun) public onlyOwner {
        mun = _mun;
    }

    function setMUS(address _mus) public onlyOwner {
        mus = _mus;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    // Allows the owner to create a blueprint which is how many card can be minted for a particular tokenURI
    // NOTE: Remember to deploy the json file to the right URI with the baseURI
    function createBlueprint(string memory _tokenURI, uint256 _maxMint, uint256 _munCost, uint256 _musCost) public onlyOwner {
        uint256[4] memory blueprint = [_maxMint, 0, _munCost, _musCost];
        blueprints[_tokenURI] = blueprint;
        blueprintExists[_tokenURI] = true;
        tokenURIs.push(_tokenURI);
    }

    // Stacking MUN RESETS the staking time
    function stakeMUN(uint256 _amount) public {
        // Check allowance
        uint256 allowance = IERC20(mun).allowance(msg.sender, address(this));
        require(allowance >= _amount, 'NFTManager: You have to approve the required token amount to stake');
        IERC20(mun).transferFrom(msg.sender, address(this), _amount);
        // Apply 1% fee from the transfer
        _amount = _amount.mul(99).div(100);
        timeStaked[msg.sender] = block.number;
        amountStaked[msg.sender] = amountStaked[msg.sender].add(_amount);
    }

    /// @notice this is the reason we need abiencoder v2 to return the string memory
    function getTokenURIs() public view returns (string[] memory) {
        return tokenURIs;
    }

    function receiveMUS() public {
        require(amountStaked[msg.sender] > 0, 'You must have MUN staked to receive MUS');
        uint256 musGenerated = getGeneratedMUS();
        timeStaked[msg.sender] = block.number;
        IMUS(mus).mint(msg.sender, musGenerated);
    }

    /// @notice Returns the generated MUS after staking MUN but doesn't send them
    function getGeneratedMUS() public view returns(uint256) {
        uint256 blocksPassed = block.number.sub(timeStaked[msg.sender]);
        uint256 musGenerated = amountStaked[msg.sender].mul(blocksPassed).div(oneDayInBlocks);
        return musGenerated;
    }

    // Unstake MUN tokens and receive MUS tokens tradable for NFTs
    function unstakeMUNAndReceiveMUS(uint256 _amount) public {
        require(_amount <= amountStaked[msg.sender], "NFTManager: You can't unstake more than your current stake");
        receiveMUS();
        amountStaked[msg.sender] = amountStaked[msg.sender].sub(_amount);
        IERC20(mun).transfer(msg.sender, _amount);
    }

    // Mint a card for the sender
    // NOTE: remember that the tokenURI most not have the baseURI. For instance:
    // - BaseURI is https://examplenft.com/
    // - TokenURI must be "token-1" or whatever without the BaseURI
    // To create the resulting https://exampleNFT.com/token-1
    function safeMint(string memory _tokenURI) public {
        // Check that this tokenURI exists
        require(blueprintExists[_tokenURI], "NFTManager: That token URI doesn't exist");
        // Require than the amount of tokens to mint is not exceeded
        require(blueprints[_tokenURI][0] > blueprints[_tokenURI][1], 'NFTManager: The total amount of tokens for this URI have been minted already');
        uint256 allowanceMUN = IERC20(mun).allowance(msg.sender, address(this));
        uint256 allowanceMUS = IERC20(mus).allowance(msg.sender, address(this));
        require(allowanceMUN >= blueprints[_tokenURI][2], 'NFTManager: You have to approve the required token amount of MUN to stake');
        require(allowanceMUS >= blueprints[_tokenURI][3], 'NFTManager: You have to approve the required token amount of MUS to stake');
        // Payment
        IERC20(mun).transferFrom(msg.sender, address(this), blueprints[_tokenURI][2]);
        IERC20(mus).transferFrom(msg.sender, address(this), blueprints[_tokenURI][3]);

        blueprints[_tokenURI][1] = blueprints[_tokenURI][1].add(1);
        lastId = lastId.add(1);
        mintedTokenIds.push(lastId);
        myTokenURI[lastId] = _tokenURI;
        // The token URI determines which NFT this is
        _safeMint(msg.sender, lastId, "");
        _setTokenURI(lastId, _tokenURI);
    }

    /// @notice To break a card and receive the MUN inside, which is inside this contract
    /// @param _id The token id of the card to burn and extract the MUN
    function breakCard(uint256 _id) public {
        require(_exists(_id), "The token doesn't exist with that tokenId");
        address owner = ownerOf(_id);
        require(owner != address(0), "The token doesn't have an owner");
        require(owner == msg.sender, 'You must be the owner of this card to break it');
        // Don't use the function tokenURI() because it combines the baseURI too
        string memory userURI = myTokenURI[_id];
        uint256[4] storage blueprint = blueprints[userURI];
        _burn(_id);
        // Consider the 1% cost when minting the card since the contract should not have more than that inside
        IERC20(mun).transfer(msg.sender, blueprint[2].mul(99).div(100));
        // Make sure to increase the supply again
        blueprint[1] = blueprint[1].sub(1);
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }

    function getBlueprint(string memory _tokenURI) public view returns(uint256[4] memory) {
        return blueprints[_tokenURI];
    }
}