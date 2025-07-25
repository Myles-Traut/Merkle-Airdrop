// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Claimed(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            STORAGE VARS
    //////////////////////////////////////////////////////////////*/
    
    IERC20 private token;
    
    bytes32 private merkleRoot;

    mapping(address _claimer => bool _claimed) private hasClaimed;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _token, bytes32 _merkleRoot) {
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
    }

    /*//////////////////////////////////////////////////////////////
                    STATE CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (hasClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Hash twice to prevent collision
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));

        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        hasClaimed[_account] = true;

        emit Claimed(_account, _amount);

        token.safeTransfer(_account, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function getAirdropToken() external view returns (address) {
        return address(token);
    }

    function getClaimedStatus(address _account) external view returns (bool) {
        return hasClaimed[_account];
    }
}
