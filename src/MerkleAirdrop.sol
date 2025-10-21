// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__SignatureNotValid();

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

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _token, bytes32 _merkleRoot) EIP712("MerkleAirdrop", "1") {
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
    }

    /*//////////////////////////////////////////////////////////////
                    STATE CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function claim(
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (hasClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(_account, getMessageHash(_account, _amount), _v, _r, _s)) {
            revert MerkleAirdrop__SignatureNotValid();
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

    function getMessageHash(address _account, uint256 _amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: _account, amount: _amount})))
            );
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function getAirdropToken() external view returns (address) {
        return address(token);
    }

    function getClaimedStatus(address _account) external view returns (bool) {
        return hasClaimed[_account];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _isValidSignature(address _account, bytes32 _digest, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(_digest, _v, _r, _s);
        return actualSigner == _account;
    }
}
