pragma circom 2.2.2;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";
include "merkle.circom";

template KYCSelectiveDisclosure(height) {
    // Public inputs
    signal input id_root;
    signal input country_set_root;
    signal input min_age;

    // Public outputs
    signal output nullifier;

    // Private identity leaf & path
    signal input id_leaf;
    signal input id_path_elements[height];
    signal input id_path_index[height];

    // Private attributes
    signal input age;
    signal input country_leaf;
    signal input country_path_elements[height];
    signal input country_path_index[height];

    // Session binding
    signal input session_salt;

    // PRE-DECLARE ALL COMPONENTS (Circom 2.2+ requirement)
    component h;
    component idMerkle;
    component countryMerkle;
    component gte;

    // Generate nullifier = Poseidon(id_leaf, session_salt)
    h = Poseidon(2);
    h.inputs[0] <== id_leaf;
    h.inputs[1] <== session_salt;
    nullifier <== h.out;

    // Prove identity membership
    idMerkle = MerkleTreeInclusionProof(height);
    idMerkle.leaf <== id_leaf;
    for (var i = 0; i < height; i++) {
        idMerkle.pathElements[i] <== id_path_elements[i];
        idMerkle.pathIndices[i] <== id_path_index[i];
    }
    id_root === idMerkle.root;

    // Prove country membership
    countryMerkle = MerkleTreeInclusionProof(height);
    countryMerkle.leaf <== country_leaf;
    for (var j = 0; j < height; j++) {
        countryMerkle.pathElements[j] <== country_path_elements[j];
        countryMerkle.pathIndices[j] <== country_path_index[j];
    }
    country_set_root === countryMerkle.root;

    // Age verification
    gte = GreaterEqThan(8);
    gte.in[0] <== age;
    gte.in[1] <== min_age;
    gte.out === 1;
}

component main = KYCSelectiveDisclosure(32);
