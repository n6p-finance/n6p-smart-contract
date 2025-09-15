// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IERC4626 {
    // return underlying token used for the vault for accounting, depositing, withrawing
    function assset() public view returns (address assetTokenAddress)
    //
    function totalAssets() public view returns (uint256)
    //
    function convertToShares(uint256 assets) public view returns (uint256 shares)
    // 
    function convertToAssets(uint256 shares) public view returns (uint256 assets)
    //
    function maxDeposit(address reciver) public view returns (uint256 maxAssets)
    //
    function previewDeposit(uint256 assets) public view returns (uint256 shares)
    //
    function deposit(uint256 assets, address reciever) public returns (uint256)
    //
    function maxMint(address reciever) public view returns (uint256 maxShares)
    //
    function previewMint(uint256 shares) public view returns (uint256 assets)
    // get back total shares to user
    function mint(uint256 shares, address reciever) public returns (uint256 assets)
    //
    function maxWithdraw(address owner) public view returns (uint256 maxAssets)
    //
    function previewWithdraw(uint256 assets) public view returns (uint256 shares)
    //
    function withdraw(uint256 assets, address reciever, address owner) public returns (uint256 shares)
    //
    function maxRedeem(address owner) public view returns (uint256 maxShares)
    // why if theres already mint should have redeem? so owner own shares
    function previewRedeem(uint256 shares) public view returns (uint256 assets)
    // get back specific ammount of shares from owner and send underlying assets/toekn back to reciver
    function redeem(uint256 shares, address reciever, address owner) public returns (uint256 assets)
    //
    function totalSupply() public view returns (uint256)
    // owner of contract? or overall vault?
    function balancecOf(address owner) public view returns (uint256)



}