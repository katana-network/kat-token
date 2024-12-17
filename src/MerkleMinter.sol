// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {KatToken} from "./KatToken.sol";
import {MerkleProof} from "dependencies/@openzeppelin-contracts-5.1.0/utils/cryptography/MerkleProof.sol";

contract MerkleMinter {
    bytes32 public root;
    mapping(bytes32 => bool) public nullifier;

    KatToken public katToken;

    uint256 public unlockTime;
    bool public locked = true;
    address public unlocker;
    address public rootSetter;

    constructor(uint256 _unlockTime, address _unlocker, address _rootSetter) {
        unlockTime = _unlockTime;
        unlocker = _unlocker;
        rootSetter = _rootSetter;
    }

    modifier unlocked() {
        // do a fail fast check on time first, then storage slot, this keeps claim cheap after the time unlock
        require(((block.timestamp > unlockTime) || !locked), "Minter locked.");
        _;
    }

    // Set the token and the merkle root once
    function init(bytes32 _root, address _katToken) public {
        require(msg.sender == rootSetter, "Not rootSetter.");
        root = _root;
        katToken = KatToken(_katToken);
        rootSetter = address(0x00);
    }

    // unlock early
    function unlock() public {
        require(msg.sender == unlocker, "Not unlocker.");
        locked = false;
        unlocker = address(0x00);
    }

    function claimKatToken(bytes32[] memory proof, uint256 amount, address receiver) public unlocked {
        bytes32 leaf = keccak256(abi.encode(amount, receiver));
        require(!nullifier[leaf], "Already claimed.");
        require(MerkleProof.verify(proof, root, leaf), "Proof failed");
        katToken.mintTo(receiver, amount);
    }

    // using https://github.com/Uniswap/merkle-distributor
}
