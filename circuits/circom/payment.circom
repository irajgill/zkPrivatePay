pragma circom 2.2.0;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";
include "merkle.circom";

template NoteCommitment() {
    signal input pk;
    signal input amount;
    signal input blinding;
    signal output commitment;

    component h = Poseidon(3);
    h.inputs[0] <== pk;
    h.inputs[1] <== amount;
    h.inputs[2] <== blinding;
    commitment <== h.out;
}

template Nullifier() {
    signal input sk;
    signal input note_commitment;
    signal output nullifier;

    component h = Poseidon(2);
    h.inputs[0] <== sk;
    h.inputs[1] <== note_commitment;
    nullifier <== h.out;
}

template Payment(nIn, nOut, treeHeight) {
    // Public inputs
    signal input root;
    signal input fee;

    // Public outputs
    signal output out_nullifiers[nIn];
    signal output out_commitments[nOut];

    // Private inputs
    signal input in_amounts[nIn];
    signal input in_blindings[nIn];
    signal input in_pks[nIn];
    signal input in_sks[nIn];

    // Merkle proofs
    signal input merkle_path_elements[nIn][treeHeight];
    signal input merkle_path_index[nIn][treeHeight];

    // Outputs
    signal input out_amounts[nOut];
    signal input out_blindings[nOut];
    signal input out_pks[nOut];

    // Intermediate signals
    signal in_commitments[nIn];

    // Pre-declare components
    component nc[nIn];
    component nf[nIn];
    component mp[nIn];
    component oc[nOut];

    // Build input commitments, nullifiers, and inclusion proofs
    for (var i = 0; i < nIn; i++) {
        nc[i] = NoteCommitment();
        nc[i].pk <== in_pks[i];
        nc[i].amount <== in_amounts[i];
        nc[i].blinding <== in_blindings[i];
        in_commitments[i] <== nc[i].commitment;

        nf[i] = Nullifier();
        nf[i].sk <== in_sks[i];
        nf[i].note_commitment <== in_commitments[i];
        out_nullifiers[i] <== nf[i].nullifier;

        mp[i] = MerkleTreeInclusionProof(treeHeight);
        mp[i].leaf <== in_commitments[i];
        for (var j = 0; j < treeHeight; j++) {
            mp[i].pathElements[j] <== merkle_path_elements[i][j];
            mp[i].pathIndices[j] <== merkle_path_index[i][j];
        }
        root === mp[i].root;
    }

    // Build output commitments
    for (var k = 0; k < nOut; k++) {
        oc[k] = NoteCommitment();
        oc[k].pk <== out_pks[k];
        oc[k].amount <== out_amounts[k];
        oc[k].blinding <== out_blindings[k];
        out_commitments[k] <== oc[k].commitment;
    }

    // Accumulator pattern for summing (single-assignment semantics)
    signal sumInAcc[nIn + 1];
    signal sumOutAcc[nOut + 1];
    
    sumInAcc[0] <== 0;
    for (var a = 0; a < nIn; a++) {
        sumInAcc[a + 1] <== sumInAcc[a] + in_amounts[a];
    }
    
    sumOutAcc[0] <== 0;
    for (var b = 0; b < nOut; b++) {
        sumOutAcc[b + 1] <== sumOutAcc[b] + out_amounts[b];
    }

    // Conservation constraint: sum(inputs) === sum(outputs) + fee
    sumInAcc[nIn] === sumOutAcc[nOut] + fee;
}

component main = Payment(2, 2, 32);

