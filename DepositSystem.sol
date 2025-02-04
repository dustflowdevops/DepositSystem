// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.17;

import "WalletContract.sol";
import "CollateralToken.sol";
import "Percent.sol";  // Import the Percent library

contract TokenCreation is WalletContract {
    // Struct to hold the token creation request details
    struct TokenCreateRequest {
        address rootToken; // The address of the original token (e.g., NET-20 token or adress(0) for main)
        address[] recipients; // The list of addresses to receive the tokens
        uint256[] percentages; // The percentage distribution for each recipient
        bool isCreated; // Flag to indicate if the token has been created
    }

    struct CollateralTokenInfo{
        CollateralToken token; 
        address[] recipients; // The list of addresses to receive the tokens
        uint256[] percentages; // The percentage distribution for each recipient
    }

    // Mapping of request IDs to TokenCreateRequest details
    mapping(uint256 => TokenCreateRequest) public createRequests;
    uint256 public requestCounter;

    // Mapping to store the pairs of old and new tokens
    mapping(address => CollateralTokenInfo) public tokenPairs;

    address public owner;
    address public mainnetTokenName;
    address public mainnetTokenSymbol;

    event TokenCreationRequested(
        uint256 indexed requestId,
        address indexed rootToken,
        address sender,
        address[] recipients,
        uint256[] percentages
    );

    event TokenCreated(uint256 indexed requestId, address indexed token, address indexed rootToken);
    event TokenMinted(address indexed token, address indexed rootToken, address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "L2");
        _;
    }

    // Constructor: Set the initial owner of the contract
    constructor(address _mainnetTokenName, address _mainnetTokenSymbol) WalletContract() {
        owner = msg.sender;
        mainnetTokenName = _mainnetTokenName;
        mainnetTokenSymbol = _mainnetTokenSymbol;
    }

    // Function to request the creation of a new token based on the original token
    function requestTokenCreation(
        address rootToken,
        address[] memory recipients,
        uint256[] memory percentages
    ) public {
        require(recipients.length == percentages.length, "C4");
        require(recipients.length > 0, "C1");
        require(verifyPercentages(percentages), "C4");
        require(address(tokenPairs[rootToken].token) == address(0), "C2");

        requestCounter++;
        createRequests[requestCounter] = TokenCreateRequest({
            rootToken: rootToken,
            recipients: recipients,
            percentages: percentages,
            isCreated: false
        });

        emit TokenCreationRequested(requestCounter, rootToken, msg.sender, recipients, percentages);
    }

    // Function to approve the token creation request (only callable by the owner)
    function approveTokenCreation(uint256 requestId) public onlyOwner {
        TokenCreateRequest storage request = createRequests[requestId];
        require(!request.isCreated, "CT1");
        require(address(tokenPairs[request.rootToken].token) == address(0), "C2");

        request.isCreated = true;

        // Generate the new token name and symbol based on the root token
        string memory newTokenName;
        string memory newTokenSymbol;

        if (request.rootToken == address(0)) {
            newTokenName = string(abi.encodePacked(mainnetTokenName, "_Deposit_DustT"));
            newTokenSymbol = string(abi.encodePacked(mainnetTokenSymbol,"_DEP_DUSTT"));
        } else {
            try NET20(request.rootToken).name() returns (string memory tokenName) {
                newTokenName = string(abi.encodePacked(tokenName, "_Deposit_DustT"));
            } catch {
                newTokenName = string(abi.encodePacked("Token_", address(request.rootToken), "_Deposit_DustT"));
            }

            try NET20(request.rootToken).symbol() returns (string memory tokenSymbol) {
                newTokenSymbol = string(abi.encodePacked(tokenSymbol, "_DEP_DUSTT"));
            } catch {
                newTokenSymbol = string(abi.encodePacked("Token_", address(request.rootToken), "_DEP_DUSTT"));
            }
        }

        CollateralToken newToken = new CollateralToken(request.rootToken, newTokenName, newTokenSymbol);

        tokenPairs[request.rootToken] = CollateralTokenInfo({
            token: newToken,
            recipients: request.recipients,
            percentages: request.percentages
        });

        emit TokenCreated(requestId,  address(newToken),request.rootToken);
    }

    // Function to verify if the total percentages sum to 100%
    function verifyPercentages(uint256[] memory percentages) internal pure returns (bool) {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }
        return totalPercentage == Percent.MAXVALUE;
    }

    // Function to transfer ownership to a new address
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "C1");
        owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    // Function to mint new deposit tokens for the user based on the root token transfer
    function mint(address rootToken, uint256 amount) public returns (bool){
        require(amount > 0, "C4");
        CollateralTokenInfo memory tokenInfo = tokenPairs[rootToken];
        require(address(tokenInfo.token) != address(0), "C1");
    
        require(balanceOf(msg.sender) >= amount, "T1");

        for (uint256 i = 0; i < tokenInfo.recipients.length; i++) {
            uint256 recipientAmount = (amount * tokenInfo.percentages[i]) / Percent.MAXVALUE;
            addBalanceTo(tokenInfo.recipients[i], rootToken, recipientAmount);
        }

        tokenInfo.token.mint(msg.sender, amount);

        return true;
    }

    function payUpMint(address rootToken, uint256 amount) public payable  returns(bool){
        require(amount > 0, "C4");
        CollateralTokenInfo memory tokenInfo = tokenPairs[rootToken];
        require(address(tokenInfo.token) != address(0), "C1");
    
        uint balance = balanceOf(msg.sender);

        if(balance < amount)
        {
            deposit(rootToken, amount -balance);
        }

        removeBalanceFrom(msg.sender, rootToken, amount);

        for (uint256 i = 0; i < tokenInfo.recipients.length; i++) {
            uint256 recipientAmount = (amount * tokenInfo.percentages[i]) / Percent.MAXVALUE;
            addBalanceTo(tokenInfo.recipients[i], rootToken, recipientAmount);
        }

        tokenInfo.token.mint(msg.sender, amount);

        return true;
    }


    // Function to get the deposit of a user for a specific token
    function depositOf(address user, address newToken) public view returns (uint256) {
        CollateralToken token = CollateralToken(newToken);
        return token.balanceOf(user); 
    }

    // Function to get the deposit of a user for a specific root token (original token)
    function depositRootOf(address user, address rootToken) public view returns (uint256) {
        CollateralTokenInfo memory tokenInfo = tokenPairs[rootToken];
        require(address(tokenInfo.token) != address(0), "C1");
        return tokenInfo.token.balanceOf(user); 
    }

    function getRequestTokenCreation(uint id) public view returns(TokenCreateRequest memory){
        return createRequests[id];
    }
}
