// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract  DEX is ERC20 {

    address public tokenAddress;

 // Exchange is inheriting ERC20, because our exchange itself is an ERC-20 contract
// as it is responsible for minting and issuing LP Tokens

    constructor(address token) ERC20("ETH token LP token", "lpETHtoken")
     {
      require(token != address(0), "token address passed is a null Address");
      tokenAddress = token;
    }

    // getReserve returns the balance of `token` held by `this` contract
    function getReserve() public view returns (uint256){
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    // addLiquidity allows users to add liquidity to the exchange
    function addliquidity(
        uint256 amountOfToken
    ) public payable returns(uint256){
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);



        // If the reserve is empty, take any user supplied value for initial liquidity
        if (tokenReserveBalance == 0) {
            // transfer the token from the user to the exchange
            token.transferFrom(msg.sender , address(this), amountOfToken);

            //lp tokens To mint  = ethreserveBalance = msg.value
            lpTokensToMint = ethReserveBalance;

            // mint Lp token to the user
            _mint(msg.sender, lpTokensToMint);
            return lpTokensToMint;
        }

        //  if the reserve is not empty , calculate the amount of Lp tokens to be minted
        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance) /
        ethReservePriorToFunctionCall;

        require(amountOfToken >= minTokenAmountRequired, "Insufficient amount of tokens provided");

        // calculate the amount of Lp token to be minted
        lpTokensToMint = (totalSupply() * msg.value/ethReservePriorToFunctionCall);

        // mint Lp token 
        _mint(msg.sender, lpTokensToMint);
        return lpTokensToMint;
    }

    function removeLiquidity(uint256 amountofLpTOkens) public returns(uint256, uint256){

        require(amountofLpTOkens > 0 ,"You are not the liquidity provider");


        uint256 ethReserveBalance = address(this).balance;
        uint256 lptokenTotalSupply = totalSupply();

        //calculate the amount of Eth and tokens to returns  to the user 
        uint256 ethToreturn = (ethReserveBalance * amountofLpTOkens)/lptokenTotalSupply;

        uint256 tokentoReturn = (getReserve() * amountofLpTOkens) / lptokenTotalSupply;

        // burn the Lp token from the user and transfer the eth and tokens to the user
        _burn(msg.sender, amountofLpTOkens);
        payable(msg.sender).transfer(ethToreturn);
        ERC20(tokenAddress).transfer(msg.sender, tokentoReturn);
        return (ethToreturn , tokentoReturn);

    }

    // getOutputAmountFromSwap calculates the amount of output tokens to be received based on xy = (x + dx)(y - dy)
    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    )public pure returns (uint256){
        require(
            inputReserve > 0 && outputReserve > 0, "reserve must be greater than 0"
        );
        uint256 inputAmountWithFEE = inputAmount * 99 ; 
        uint256 numerator = inputAmountWithFEE * outputReserve;
        uint256  denominator = (inputReserve * 100) + inputAmountWithFEE;
        return numerator / denominator ;
    }

    // now the swaping function 
    // ethToTokenSwap allows users to swap ETH for tokens
    function ethToTokenSwap(uint256 minTokenToReceive) public payable{
        uint256 tokenReserveBalance = getReserve();
        uint256 tokensToReceive = getOutputAmountFromSwap(
            msg.value,
            address(this).balance - msg.value,
            tokenReserveBalance
        );
        require(tokensToReceive >= minTokenToReceive,"Token received are less than minimum tokens expected");
        ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
    }

// tokenToEthSwap allows users to swap tokens for ETH
function tokenToEthSwap(
    uint256 tokensToSwap,
    uint256 minEthToReceive
) public {
    uint256 tokenReserveBalance = getReserve();
    uint256 ethToReceive = getOutputAmountFromSwap(
        tokensToSwap,
        tokenReserveBalance,
        address(this).balance
    );

    require(
        ethToReceive >= minEthToReceive,
        "ETH received is less than minimum ETH expected"
    );

    ERC20(tokenAddress).transferFrom(
        msg.sender,
        address(this),
        tokensToSwap
    );

    payable(msg.sender).transfer(ethToReceive);
}

}