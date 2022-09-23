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
        }
        // Take the current ethBalance and mint `ethBalance` amount of LP tokens to the user.
        // `liquidity` provided is equal to `ethBalance` because this is the first time user
        liquidity = ethBalance;
        _mint(msg.sender, liquidity);
        // _mint is ERC20.sol smart contract function to mint ERC20 tokens
    } else {

        // EthReserve should be the current ethBalance subtracted by the value of ether sent by the user
        // in the current `addLiquidity` call
        uint ethReserve = ethBalance - msg.value;
         // Ratio should always be maintained so that there are no major price impacts when adding liquidity
        // Ratio here is -> (cryptoDevTokenAmount user can add/cryptoDevTokenReserve in the contract) = (Eth Sent by the user/Eth Reserve in the contract);
        uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/ (ethReserve);
        require(_amount >= cryptoDevTokenReserve, "Amount of tokens sent is les then the minimum tokens required")

    }
}
