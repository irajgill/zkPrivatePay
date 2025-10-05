-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    aptos_address VARCHAR(66) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    last_active TIMESTAMP DEFAULT NOW()
);

-- ZK Proof jobs
CREATE TABLE proof_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES users(id),
    circuit_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    input_data JSONB NOT NULL,
    proof_data JSONB,
    public_signals JSONB,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Payment transactions
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES users(id),
    tx_hash VARCHAR(66),
    nullifiers JSONB NOT NULL,
    commitments JSONB NOT NULL,
    amount BIGINT,
    fee BIGINT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

-- KYC attestations
CREATE TABLE kyc_attestations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES users(id),
    session_nullifier VARCHAR(66) UNIQUE NOT NULL,
    proof_hash VARCHAR(66) NOT NULL,
    attester_sigs JSONB NOT NULL,
    verified_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

-- CLOB orders
CREATE TABLE clob_orders (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    order_commitment VARCHAR(66) NOT NULL,
    fill_hash VARCHAR(66),
    status VARCHAR(20) DEFAULT 'open',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_proof_jobs_status ON proof_jobs(status);
CREATE INDEX idx_proof_jobs_user ON proof_jobs(user_id);
CREATE INDEX idx_kyc_session_nullifier ON kyc_attestations(session_nullifier);
CREATE INDEX idx_clob_orders_user ON clob_orders(user_id);
CREATE INDEX idx_clob_orders_status ON clob_orders(status);

-- Insert sample data (optional)
INSERT INTO users (aptos_address) VALUES 
('0x1234567890abcdef1234567890abcdef12345678'),
('0xabcdef1234567890abcdef1234567890abcdef12');
