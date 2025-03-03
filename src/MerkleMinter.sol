// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {KatToken} from "./KatToken.sol";
import {MerkleProof} from "dependencies/@openzeppelin-contracts-5.1.0/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "dependencies/@openzeppelin-contracts-5.1.0/utils/structs/BitMaps.sol";

contract MerkleMinter {
    using BitMaps for BitMaps.BitMap;

    bytes32 public root;
    BitMaps.BitMap isClaimed;

    KatToken public katToken;

    uint256 public immutable unlockTime;
    bool public locked = true;
    address public unlocker;
    address public rootSetter;

    constructor(uint256 _unlockTime, address _unlocker, address _rootSetter) {
        unlockTime = _unlockTime;
        unlocker = _unlocker;
        rootSetter = _rootSetter;
    }

    /**
     * Set the token and the merkle root once
     * @param _root Merkleroot to the airdrop receivers merkle tree
     * @param _katToken Address of the KatToken to be airdropped
     */
    function init(bytes32 _root, address _katToken) public {
        require(msg.sender == rootSetter, "Not rootSetter.");
        root = _root;
        katToken = KatToken(_katToken);
        rootSetter = address(0);
    }

    /**
     * Unlocks the claim function early
     */
    function unlock() public {
        require(msg.sender == unlocker, "Not unlocker.");
        locked = false;
        unlocker = address(0);
    }

    /**
     * Claim function that checks if a leaf is inside the root using a proof and mints the expected token amount to the receiver
     * @param proof MerkleProof from the leaf to be claimed to the root
     * @param index Index of the claim
     * @param amount Token amount for this leaf
     * @param receiver Address of the token receiver for this leaf
     */
    function claimKatToken(bytes32[] memory proof, uint256 index, uint256 amount, address receiver) public {
        // do a fail fast check on time first, then storage slot, this keeps claim cheap after the time unlock
        require(((block.timestamp > unlockTime) || !locked), "Minter locked.");
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, receiver, amount))));
        require(!isClaimed.get(index), "Already claimed.");
        require(MerkleProof.verify(proof, root, leaf), "Proof failed");
        isClaimed.set(index);
        katToken.mintTo(receiver, amount);
    }
}
