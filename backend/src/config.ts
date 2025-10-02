import 'dotenv/config';

export const cfg = {
  port: Number(process.env.PORT || 8080),
  dbUrl: process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/zkpp',
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
  aptos: {
    network: process.env.APTOS_NETWORK || 'testnet',
    moduleAddress: process.env.MODULE_ADDRESS || '0x42'
  },
  verifier: {
    threshold: Number(process.env.VERIFIER_THRESHOLD || 2)
  },
  telegram: {
    botToken: process.env.TELEGRAM_BOT_TOKEN || ''
  }
};
