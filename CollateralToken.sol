// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.17;

contract CollateralToken {
    string public name;
    string public symbol;
    address public rootToken;
    uint public totalSupply;

    mapping(address => uint256) private balances;
    
    event TokenMinted(address indexed account, uint256 amount);
    event TokenBurned(address indexed account, uint256 amount);
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can mint tokens");
        _;
    }
    
    constructor(address _rootToken, string memory _name, string memory _symbol) {
        owner = msg.sender; 
        rootToken = _rootToken; 
        name = _name;       
        symbol = _symbol;   
    }
    
    // Function to mint new Collateral Tokens
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        balances[to] += amount; // Increase the balance of the recipient
        totalSupply+= amount;
        emit TokenMinted(to, amount); // Emit mint event
    }
    
    // Function to burn Collateral Tokens (user can burn their own tokens)
    function burn(uint256 amount) public {
        totalSupply-= amount;
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        balances[msg.sender] -= amount; // Decrease the balance of the sender
        totalSupply-= amount;
        emit TokenBurned(msg.sender, amount); // Emit burn event
    }
    
    // Function to view the balance of Collateral Tokens
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
