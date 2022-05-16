//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol";


contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256 private treeLevel = 3;
    uint256 internal nextLeafIndex = 0; //the index we will start adding leaves

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        uint256 levelNodes = 2**treeLevel; // I should use safeMath library next time 
        // uint256 _zero = hash(0,0);
        // hashes = new uint256[](levelNodes*2);
        for (uint8 i = 0; i < levelNodes; i++) {
            // hashes[i] = 0;
            hashes.push(0);
        }
        
        uint256 current = 0;
        levelNodes = levelNodes/2;

        for (uint8 i = 1; i <= treeLevel; i++) {
            uint256 hashed = hash(current, current); // All leaves have the same value so both inputs are the same for hash and this is propagated until the root 
            for (uint8 j = 0; j < levelNodes; j++) {
                // hashes[j] = hashed; 
                hashes.push(hashed);
            }
            
            // console.log("levelNodesCount: ",levelNodes," and value", hashed);
            levelNodes = levelNodes/2;
            current = hashed;
        }
        root = current;
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        uint256 currentIndex = nextLeafIndex;
        uint256 currentHash = hashedLeaf;
        uint256 left;
        uint256 right;
        
        require(currentIndex < 2**treeLevel -1, "Max index exceeded");

        // console.log("inside insert");
        // hashes[currentIndex] = hashedLeaf;
        //     for(uint a =0; a<=14+){
        //         console.log(hashes[a]);
        // }
        //I'm sure I overcomplicated this one 
        //todo return
        uint256 sumLevelNodes = 0;
        uint256 levelNodes = 0;
        hashes[currentIndex] = hashedLeaf; 

        // console.log("currentIndex", currentIndex);
        for (uint8 i = 0; i < treeLevel; i++) {
            if (currentIndex % 2 == 0) {
                left = currentHash;
                // right = hashes[2**(treeLevel-i) - 1];
                right = hashes[currentIndex  + 1];
                // console.log("currentIndex",currentIndex);
                // console.log("$$",left,right);

            } else {
                left = hashes[currentIndex - 1];
                right = currentHash;
            }

            currentHash = hash(left, right);
            currentIndex = (currentIndex-sumLevelNodes)/2;// + sumLevelNodes;
            levelNodes =  2**(treeLevel - i);
            sumLevelNodes = sumLevelNodes + levelNodes;
            currentIndex += sumLevelNodes;
            // console.log("currentIndex", currentIndex);
            // console.log("nextIndex", currentIndex);
            // currentIndex += 2**(treeLevel-i);
            hashes[currentIndex] = currentHash;
        }

        root = currentHash;

        nextLeafIndex += 1;

        return currentIndex;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return ( root == input[0]) && verifyProof(a,b,c,input);
    }

    //helper function
    function hash(uint256 _leftNode, uint256 _rightNode)
        internal // can be used only by contract and contracts which inherit this one
        pure //it just makes a computation
        returns (uint256)
    {
        uint256[2] memory input;
        input[0] = _leftNode;
        input[1] = _rightNode;
        return PoseidonT3.poseidon(input);
    }
}
