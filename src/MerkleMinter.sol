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
        require(_unlockTime != 0);
        require(_unlocker != address(0));
        require(_rootSetter != address(0));

        unlockTime = _unlockTime;
        unlocker = _unlocker;
        rootSetter = _rootSetter;
    }

    /**
     * Set the token and the merkle root, once successfully done RootSetter should be renounced
     * @param _root Merkleroot to the airdrop receivers merkle tree
     * @param _katToken Address of the KatToken to be airdropped
     */
    function init(bytes32 _root, address _katToken) external {
        require(msg.sender == rootSetter, "Not rootSetter.");
        root = _root;
        katToken = KatToken(_katToken);
    }

    /**
     * Renounces the RootSetter, so neither KatToken address nor the merkle root can be changed anymore
     */
    function renounceRootSetter() external {
        require(msg.sender == rootSetter, "Not rootSetter.");
        rootSetter = address(0);
    }

    /**
     * Unlocks the claim function early, afterwards contract can't be locked again
     */
    function unlockAndRenounceUnlocker() external {
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
    function claimKatToken(bytes32[] memory proof, uint256 index, uint256 amount, address receiver) external {
        // do a fail fast check on time first, then storage slot, this makes claim cheap again after the time unlock
        require(((block.timestamp > unlockTime) || !locked), "Minter locked.");
        require(!isClaimed.get(index), "Already claimed.");

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, receiver, amount))));
        require(MerkleProof.verify(proof, root, leaf), "Proof failed");

        isClaimed.set(index);
        katToken.mintTo(receiver, amount);
    }
}
