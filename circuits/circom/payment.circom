pragma circom 2.1.6;

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

    // PRE-DECLARE ALL COMPONENTS IN INITIAL SCOPE (Circom 2.2+ requirement)
    component nc[nIn];
    component nf[nIn];
    component merkle[nIn];
    component oc[nOut];

    // Build input commitments and nullifiers
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

        // Merkle inclusion proof
        merkle[i] = MerkleTreeInclusionProof(treeHeight);
        merkle[i].leaf <== in_commitments[i];
        for (var j = 0; j < treeHeight; j++) {
            merkle[i].pathElements[j] <== merkle_path_elements[i][j];
            merkle[i].pathIndices[j] <== merkle_path_index[i][j];
        }
        root === merkle[i].root;
    }

    // Build output commitments
    for (var i = 0; i < nOut; i++) {
        oc[i] = NoteCommitment();
        oc[i].pk <== out_pks[i];
        oc[i].amount <== out_amounts[i];
        oc[i].blinding <== out_blindings[i];
        out_commitments[i] <== oc[i].commitment;
    }

    // Value conservation constraint
    signal sumIn;
    signal sumOut;
    
    sumIn <== in_amounts[0] + in_amounts[1];
    sumOut <== out_amounts[0] + out_amounts[1];
    
    sumIn === sumOut + fee;
}

component main = Payment(2, 2, 32);
