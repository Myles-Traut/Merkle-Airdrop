// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";

import {AirdropToken} from "../src/AirdropToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public merkleAirdrop;
    AirdropToken public airdropToken;

    bytes32 public merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    address user;
    uint256 privKey;

    uint256 public AMOUNT = 25 ether;

    bytes32 public proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 public proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proof1, proof2];

    function setUp() public {
        airdropToken = new AirdropToken();
        merkleAirdrop = new MerkleAirdrop(address(airdropToken), merkleRoot);

        (user, privKey) = makeAddrAndKey("user");

        airdropToken.mint(address(merkleAirdrop), AMOUNT);
    }

    function test_Claim() public {
        uint256 balanceBefore = airdropToken.balanceOf(user);
        assertEq(balanceBefore, 0);

        vm.prank(user);
        merkleAirdrop.claim(user, AMOUNT, PROOF);

        uint256 balanceAfter = airdropToken.balanceOf(user);
        assertEq(balanceAfter, balanceBefore + AMOUNT);
    }

}