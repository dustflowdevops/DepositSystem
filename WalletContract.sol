// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.17;

contract WalletContract
{
    // Mapping to store user balances for each contract (token address => balance)
    mapping(address => mapping(address => uint256)) public balances;

    event Transfer(address indexed from, address indexed to,address indexed token, uint256 value);
    event Deposit(address indexed user,  address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event CommissionChanged(uint256 newCommissionPercent, address newCommissionRecipient);

    // Function to deposit funds
    function deposit(address token, uint256 amount) public payable {
        require(amount > 0, "C5");

        // If the token is the mainnet token (address(0)), it's handled separately
        if (token == address(0)) {
            // For Mainnet token, directly handle Mainnet token deposit (assume msg.value is used)
            require(msg.value == amount, "C4");

            addBalanceTo(msg.sender, token, amount);
        } else {
            require(NET20(token).transferFrom(msg.sender, address(this), amount), "T2");

            addBalanceTo(msg.sender, token, amount);
        }

        emit Deposit(msg.sender, token,amount);
    }

    // Function to withdraw funds (NET-20 token or Mainnet token)
    function withdraw(address token, uint256 amount) public returns(bool) {
        require(balanceOf(msg.sender, token) >= amount, "T1");

        removeBalanceFrom(msg.sender, token, amount);
        
        return withdrawFromContractTo(msg.sender, token, amount);
    }

    //Send tokens to other person
    function transfer(address to, address token, uint256 amount) public returns (bool)
    {
        require(balanceOf(msg.sender, token) >= amount, "T1");

        address from = msg.sender;

        balances[from][token] -= amount;
        balances[to][token] += amount;

        emit Transfer(from, to,token, amount);

        return true;
    }

   // Function to check the balance of a user for a main token
    function balanceOf(address user) public view returns (uint256) {
        return balances[user][address(0)];
    }

    // Function to check the balance of a user for a specific token
    function balanceOf(address user, address token) public view returns (uint256) {
        return balances[user][token];
    }

    // Withdraw founds to target
    function withdrawFromContractTo(address to, address token, uint amount) internal returns (bool){
        if(amount <= 0)
            return true;

        // If token is the mainnet token (address(0)), transfer mainnet token
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            // For NET-20 tokens, transfer the specified token
            require(NET20(token).transfer(to, amount), "T3");
        }

        // Emit withdrawal event
        emit Withdrawal(to, token, amount);

        return true;        
    } 

    // Add found to target
    function addBalanceTo(address to, address token, uint amount) internal returns (bool){
        if(amount <= 0)
            return true;

        balances[to][token] += amount;
        
        emit Transfer(address(0), to,token, amount);

        return true;        
    } 

    // Remove found of target
    function removeBalanceFrom(address from, address token, uint amount) internal returns (bool){
        if(amount <= 0)
            return true;

        if(balances[from][token] < amount)
            return false;

        balances[from][token] -= amount;
        
        emit Transfer(address(0), from, token, amount);

        return true;        
    } 
}


interface NET20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}