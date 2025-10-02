import nacl from 'tweetnacl';
// Simulated oracle quorum of ed25519 keys
const N = 3;
const keypairs = Array.from({ length: N }, () => nacl.sign.keyPair());
export function getOraclePubs() {
    return keypairs.map(k => Buffer.from(k.publicKey).toString('hex'));
}
export function attest(topic, proofHash, session) {
    const msg = Buffer.concat([Buffer.from(topic), ...(session ? [Buffer.from(session)] : []), Buffer.from(proofHash)]);
    const sigs = keypairs.map(kp => Buffer.from(nacl.sign.detached(msg, kp.secretKey)).toString('base64'));
    const addrs = keypairs.map((_, i) => `0x${(i + 1).toString(16)}`);
    return { attesters: addrs, sigs };
}
export function hash(bytes) {
    // simple blake2b placeholder; use a production hash
    const { createHash } = require('crypto');
    return createHash('sha256').update(bytes).digest();
}
