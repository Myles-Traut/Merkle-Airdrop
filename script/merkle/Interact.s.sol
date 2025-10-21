// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {

    address public CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public AMOUNT_TO_CLAIM = 25 ether;
    bytes32[] public proof = [
        bytes32(0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad),
        bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
    ];

    bytes private signature = hex"96c37a9d3dd3ed1e8939ba709577c436903a0d0870fcc1d73993948d023225d175b611ed4cceecade600cc45a41052118eda85990367650ede8de160b88bc2101b";

    function claimAirdrop(address _merkleAirdrop) public {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        MerkleAirdrop(_merkleAirdrop).claim(CLAIMING_ADDRESS, AMOUNT_TO_CLAIM, proof, v, r, s);
    }

    function splitSignature(bytes memory _signature) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(_signature.length == 65, "Invalid signature length"); // s = 32 bytes, r = 32 bytes, v = 1 byte. v+r+s = 65 bytes.
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        return (v, r, s);
    }
    function run() public {
        vm.startBroadcast();
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}