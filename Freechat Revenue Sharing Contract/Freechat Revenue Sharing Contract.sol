pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDistributor is Ownable {
    IERC20 public token;
    mapping(address => bool) public recipients;
    uint256 private _distributedAmount;
    uint256 private _withdrawnAmount;

    event TokenUpdated(address indexed newToken);
    event Distribution(address indexed to, uint256 amount);
    event RecipientAdded(address indexed recipient);
    event RecipientRemoved(address indexed recipient);

    constructor(IERC20 _token) {
        token = _token;
    }

    function updateToken(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0), "TokenDistributor: Invalid token address");
        token = _token;
        emit TokenUpdated(address(_token));
    }

    function addRecipient(address _recipient) public onlyOwner {
        require(!recipients[_recipient], "TokenDistributor: Recipient already added");
        recipients[_recipient] = true;
        emit RecipientAdded(_recipient);
    }

    function removeRecipient(address _recipient) public onlyOwner {
        require(recipients[_recipient], "TokenDistributor: Recipient not found");
        recipients[_recipient] = false;
        emit RecipientRemoved(_recipient);
    }

    function distribute() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        uint256 amount = balance / getRecipientsCount();

        require(amount > 0, "TokenDistributor: Insufficient balance");

        for (uint256 i = 0; i < 256; i++) {
            address recipient = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, i)))));
            if (recipients[recipient]) {
                token.transfer(recipient, amount);
                _distributedAmount += amount;
                emit Distribution(recipient, amount);
            }
        }
    }

    function getRecipientsCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < 256; i++) {
            address recipient = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, i)))));
            if (recipients[recipient]) {
                count++;
            }
        }
        return count;
    }

    function distributedAmount() public view returns (uint256) {
        return _distributedAmount;
    }

    function withdrawnAmount() public view returns (uint256) {
        return _withdrawnAmount;
    }

    function withdraw() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "TokenDistributor: Insufficient balance");
        token.transfer(owner(), balance);
        _withdrawnAmount += balance;
    }
}
