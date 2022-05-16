pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

// https://github.com/appliedzkp/maci.git
// MIT License

// Copyright (c) 2020 Barry WhiteHat, Kendrick Tan, Kobi Gurkan, Chih-Cheng Liang,
// and Koh Wei Jie

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    var N = (2**n)*2 -1; // how many hashes we will do, x + x/2 + x/4 ... where x = 2**n

    component components[N];
    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    for(var i = 0; i < (2**n)/2; i+=2) {
            // apply hash to leaves
            components[i] = Poseidon(2);
            components[i].ins[0] <== leaves[i];
            components[i].ins[1] <== leaves[i + 1];
    }

	var j=0;
	for(var i = n; i < N; i++) {
            // apply hash to leaves
            components[i] = Poseidon(2);
            components[i].ins[0] <== components[j].outs[0]; 
            components[i].ins[1] <== components[j+1].outs[0]; 
	    j+=2;
        }
      root <== components[N-1].outs[0]; 
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashers[n];
    component mux[n];

    signal levelHashes[n + 1];
    levelHashes[0] <== leaf;

    for (var i = 0; i < n; i++) {
        // Should be 0 or 1
        path_index[i] * (1 - path_index[i]) === 0;

        hashers[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== levelHashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== levelHashes[i];

        mux[i].s <== path_index[i];
        hashers[i].inputs[0] <== mux[i].out[0];
        hashers[i].inputs[1] <== mux[i].out[1];

        levelHashes[i + 1] <== hashers[i].out;
    }

    root <== levelHashes[n];
}