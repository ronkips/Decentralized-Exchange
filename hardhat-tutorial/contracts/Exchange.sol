// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    //create a contructor that will take the address of _CryptoDevToken deployed in ICO
    //checks the address if it is null
    //After the checks, it assign the value to the input param to the cryptoDevTokenAddress variable
    // It also set the symbol and name for the Crypto Dev LP token
    address public cryptoDevTokenAddress;

    //Exchange is inheriting ERC20, since our exchange will keep track of rypto Dev LP tokens

    constructor(address _CryptoDevtoken) ERC20("CryptoDev LP Token", "CDLP") {
        require(
            _CryptoDevtoken != address(0),
            "Token address passed is a null address"
        );
        cryptoDevTokenAddress = _CryptoDevtoken;
    }

    //Function to get reserves of the Eth and Crypto Dev tokens held by the contract.
    function getReserve() public view returns (uint) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    // Adds liquidity to the exchange
    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);
        /*
        If the reserve is empty, intake any user supplied value for
        `Ether` and `Crypto Dev` tokens because there is no ratio currently
    */
        if (cryptoDevTokenReserve == 0) {
            // Transfer the `cryptoDevToken`  from the user's account to the contract
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);

            // Take the current ethBalance and mint `ethBalance` amount of LP tokens to the user.
            // `liquidity` provided is equal to `ethBalance` because this is the first time user is adding `Eth` to the contract.
            // by the user in the current `addLiquidity` call
            // so whatever `Eth` contract has is equal to the one supplied
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
            // _mint is ERC20.sol smart contract function to mint ERC20 tokens
        } else {
            // EthReserve should be the current ethBalance subtracted by the value of ether sent by the user
            // in the current `addLiquidity` call
            uint ethReserve = ethBalance - msg.value;
            // Ratio should always be maintained so that there are no major price impacts when adding liquidity
            // Ratio here is -> (cryptoDevTokenAmount user can add/cryptoDevTokenReserve in the contract) = (Eth Sent by the user/Eth Reserve in the contract);
            uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) /
                (ethReserve);
            require(
                _amount >= cryptoDevTokenReserve,
                "Amount of tokens sent is less than the minimum tokens required"
            );
            // transfer only (cryptoDevTokenAmount user can add) amount of `Crypto dev tokens` from users account to the contract
            cryptoDevToken.transferFrom(
                msg.sender,
                address(this),
                cryptoDevTokenAmount
            );
            // The amount of LP that would be sent to the user should be proportianal to yhe liquidity of ether added to the user
            // Ratio here to be maintained is ->
            // (LP tokens to be sent to the user (liquidity)/ totalSupply of LP tokens in contract) = (Eth sent by the user)/(Eth reserve in the contract)
            // by some maths -> liquidity =  (totalSupply of LP tokens in contract * (Eth sent by the user))/(Eth reserve in the contract)
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    //Creating a function for removing liquidity
    //returns the amount of Eth/crypto Dev tokens that would be returned to the user
    function removeLiquidity(uint _amount) public returns (uint, uint) {
        require(_amount > 0, "_amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        //The amount of Eth that would be sent back to the user is based on the ratio
        // Ratio is -> (Eth sent back to the user) / (current Eth reserve)
        // = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        // Then by some maths -> (Eth sent back to the user)
        // = (current Eth reserve * amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        uint ethAmount = (ethReserve * _amount) / _totalSupply;
        // The amount of Crypto Dev token that would be sent back to the user is based
        // on a ratio
        // Ratio is -> (Crypto Dev sent back to the user) / (current Crypto Dev token reserve)
        // = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        // Then by some maths -> (Crypto Dev sent back to the user)
        // = (current Crypto Dev token reserve * amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        uint cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;
        //Burn the sent  LP tokens from the user's wallet because theu are already sent to remove liquidity
        _burn(msg.sender, _amount);
        //Transfer `cryptoDevTokenAmount` of crypto Dev tokens from the contract to the user's wallet
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return (ethAmount, cryptoDevTokenAmount);
    }

    //Returns the amount of Eth/Crypto dev tokens that would be returned to the user in the swap
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "sorry invalid reserves"
        );
        // We are charging a fee of `1%`
        // Input amount with fee = (input amount - (1*(input amount)/100)) = ((input amount)*99)/100
        uint256 inputAmountWithFee = inputAmount * 99;
        // Because we need to follow the concept of `XY = K` curve
        // final formula is Δy = (y * Δx) / (x + Δx)
        // Δy in our case is `tokens to be received`
        // Δx = ((input amount)*99)/100, x = inputReserve, y = outputReserve
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denomenator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denomenator;
    }

    // function to swap ETh for crypto Dev
    // Swap ETH for CryptoDev Token
    function ethToCryptoDevToken(uint _mintTokens) public payable {
        uint256 tokenReserve = getReserve();
        //call the `getAmountOfTokens` to get amount of Crypto Dev tokens that would be returned tO the user after the swap
        // Notice that the `inputReserve` we are sending is equal to
        // `address(this).balance - msg.value` instead of just `address(this).balance`
        // because `address(this).balance` already contains the `msg.value` user has sent in the given call
        // so we need to subtract it to get the actual input reserve
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought >= _mintTokens, "insufficient output amount");
        // Transfer the `crypto Dev ` to the user
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }

    // Implementing function to swap Crypto Dev tokens to Eth
    //swap CryptoDev Tokens for Eth
    function cryptoDevTokenToEth(uint _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
        // call the `getAmountOfToken` to get the amount of Eth that would be returned to the user after the swap
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "Sorry insufficient output amount");
        //Transfer `Crypto Dev` tokens from the user's address to the contract
        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        // send the `ethBought` to the user from the contracts
        payable(msg.sender).transfer(ethBought);
    }
}
