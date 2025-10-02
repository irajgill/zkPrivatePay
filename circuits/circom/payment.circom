// Confidential payment circuit (simplified)
// - Note commitments with Pedersen (via circomlibjs compatible parameters)
// - Merkle inclusion of input notes
// - Nullifier computation to prevent double-spend
// - Conservation: sum(inputs) = sum(outputs) + fee

pragma circom 2.1.6;


include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/eddsa.circom";
include "circomlib/circuits/bits2num.circom";
include "circomlib/circuits/merkle/calcwit.circom";
include "circomlib/circuits/comparators.circom";

template NoteCommitment() {
    // Public params: poseidon hash
    signal input pk;           // recipient public key (scalar)
    signal input amount;       // value (private in practice; set as private input)
    signal input blinding;     // blinding factor
    signal output commitment;  // poseidon([pk, amount, blinding])

    component h = Poseidon(3);
    h.inputs[0] <== pk;
    h.inputs[1] <== amount;
    h.inputs[2] <== blinding;
    commitment <== h.out;
}

template Nullifier() {
    signal input sk;           // sender secret key
    signal input note_commitment;
    signal output nullifier;   // poseidon([sk, note_commitment])

    component h = Poseidon(2);
    h.inputs[0] <== sk;
    h.inputs[1] <== note_commitment;
    nullifier <== h.out;
}

template Payment(nIn, nOut, treeHeight) {
    // Public
    signal input root;                         // Merkle root of note tree
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
    signal input merkle_path_index[nIn][treeHeight]; // 0/1

    // Outputs
    signal input out_amounts[nOut];
    signal input out_blindings[nOut];
    signal input out_pks[nOut];

    // Build input commitments and nullifiers
    var i;
    var j;

    signal in_commitments[nIn];
    for (i = 0; i < nIn; i++) {
        component nc = NoteCommitment();
        nc.pk <== in_pks[i];
        nc.amount <== in_amounts[i];
        nc.blinding <== in_blindings[i];
        in_commitments[i] <== nc.commitment;

        component nf = Nullifier();
        nf.sk <== in_sks[i];
        nf.note_commitment <== in_commitments[i];
        out_nullifiers[i] <== nf.nullifier;

        // Merkle inclusion for each input commitment
        component c = CalcWit(treeHeight);
        c.leaf <== in_commitments[i];
        for (j = 0; j < treeHeight; j++) {
            c.path_elements[j] <== merkle_path_elements[i][j];
            c.path_index[j] <== merkle_path_index[i][j];
        }
        root === c.root;
    }

    // Build output commitments
    signal sumIn;
    sumIn <== 0;
    for (i = 0; i < nIn; i++) {
        sumIn <== sumIn + in_amounts[i];
    }

    signal sumOut;
    sumOut <== 0;

    for (i = 0; i < nOut; i++) {
        component oc = NoteCommitment();
        oc.pk <== out_pks[i];
        oc.amount <== out_amounts[i];
        oc.blinding <== out_blindings[i];
        out_commitments[i] <== oc.commitment;
        sumOut <== sumOut + out_amounts[i];
    }

    // Conservation
    sumIn === sumOut + fee;
}

component main = Payment(2, 2, 32);
