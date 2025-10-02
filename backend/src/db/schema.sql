create table if not exists verifier_keys(
  id serial primary key,
  addr text not null unique,
  pubkey bytea not null
);

create table if not exists proofs(
  id uuid primary key,
  kind text not null, -- 'payment' | 'withdraw' | 'kyc' | 'rollup' | 'clob_fill'
  proof_hash bytea not null,
  public_signals jsonb not null,
  created_at timestamptz default now()
);

create table if not exists payment_intents(
  id uuid primary key,
  sender text not null,
  recipient text not null,
  amount bigint not null,
  fee bigint not null,
  status text not null default 'pending',
  tx_id text,
  created_at timestamptz default now()
);
