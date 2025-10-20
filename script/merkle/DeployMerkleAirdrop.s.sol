// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AirdropToken} from "../../src/AirdropToken.sol";
import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";

import {Script} from "forge-std/Script.sol";

contract DeployMerkleAirdrop is Script {
    AirdropToken public airdropToken;
    MerkleAirdrop public merkleAirdrop;

    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public amountToTransfer = 4 * 25e18;

    function deployMerkleAirdrop() public returns (AirdropToken, MerkleAirdrop) {
        airdropToken = new AirdropToken();
        merkleAirdrop = new MerkleAirdrop(address(airdropToken), MERKLE_ROOT);
        airdropToken.mint(address(merkleAirdrop), amountToTransfer);
        return (airdropToken, merkleAirdrop);
    }

    function run() public returns (AirdropToken, MerkleAirdrop) {
        vm.startBroadcast();

        (airdropToken, merkleAirdrop) = deployMerkleAirdrop();
        vm.stopBroadcast();

        return (airdropToken, merkleAirdrop);
    }
}
