pragma circom 2.2.0;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";
include "merkle.circom";

template KYC(height) {
    // Public
    signal input id_root;
    signal input country_set_root;
    signal input min_age;

    // Public outputs
    signal output nullifier; // bind to session

    // Private identity leaf & path
    signal input id_leaf;
    signal input id_path_elements[height];
    signal input id_path_index[height];

    // Private attributes
    signal input age;
    signal input country_leaf; // membership in allowed set
    signal input country_path_elements[height];
    signal input country_path_index[height];

    // Session binding
    signal input session_salt;

    // Nullifier = Poseidon(leaf, salt)
    component h = Poseidon(2);
    h.inputs[0] <== id_leaf;
    h.inputs[1] <== session_salt;
    nullifier <== h.out;

    // Prove membership of identity
    component idw = MerkleTreeInclusionProof(height);
    idw.leaf <== id_leaf;
    for (var i = 0; i < height; i++) {
        idw.pathElements[i] <== id_path_elements[i];
        idw.pathIndices[i] <== id_path_index[i];
    }
    id_root === idw.root;

    // Country allowlist membership
    component cw = MerkleTreeInclusionProof(height);
    cw.leaf <== country_leaf;
    for (var j = 0; j < height; j++) {
        cw.pathElements[j] <== country_path_elements[j];
        cw.pathIndices[j] <== country_path_index[j];
    }
    country_set_root === cw.root;

    // Age predicate (choose a bit width >= max age range)
    component gte = GreaterEqThan(16);
    gte.in[0] <== age;
    gte.in[1] <== min_age;
    gte.out === 1;
}

component main = KYC(32);

