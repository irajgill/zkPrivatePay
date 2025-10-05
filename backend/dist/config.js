import dotenv from 'dotenv';
import { z } from 'zod';
dotenv.config();
const ConfigSchema = z.object({
    // Database
    databaseUrl: z.string().min(1),
    redisUrl: z.string().min(1),
    // Aptos
    aptosNodeUrl: z.string().url(),
    aptosPrivateKey: z.string().min(1),
    contractAddress: z.string().min(1),
    // Circuits
    circuitsPath: z.string().min(1),
    // API
    port: z.coerce.number().default(3001),
    nodeEnv: z.enum(['development', 'production', 'test']).default('development'),
    // Security
    jwtSecret: z.string().min(32),
    apiRateLimit: z.coerce.number().default(100),
    // Verifier Network
    verifierQuorum: z.coerce.number().min(1),
    verifierKeys: z.array(z.string()),
    // Optional Telegram
    telegramBotToken: z.string().optional(),
    telegramChatId: z.string().optional(),
});
export const cfg = ConfigSchema.parse({
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,
    aptosNodeUrl: process.env.APTOS_NODE_URL,
    aptosPrivateKey: process.env.APTOS_PRIVATE_KEY,
    contractAddress: process.env.CONTRACT_ADDRESS,
    circuitsPath: process.env.CIRCUITS_PATH || '../circuits/circom/build',
    port: process.env.PORT,
    nodeEnv: process.env.NODE_ENV,
    jwtSecret: process.env.JWT_SECRET || 'your_super_secret_jwt_key_at_least_32_characters_long_for_development',
    apiRateLimit: process.env.API_RATE_LIMIT,
    verifierQuorum: process.env.VERIFIER_QUORUM,
    verifierKeys: process.env.VERIFIER_KEYS ? JSON.parse(process.env.VERIFIER_KEYS) : ['verifier1_pubkey', 'verifier2_pubkey'],
    telegramBotToken: process.env.TELEGRAM_BOT_TOKEN,
    telegramChatId: process.env.TELEGRAM_CHAT_ID,
});
// Add configuration logging
console.log('🔧 Configuration loaded:');
console.log(`- Database: ${cfg.databaseUrl.split('@')[1] || 'localhost'}`);
console.log(`- Redis: ${cfg.redisUrl}`);
console.log(`- Aptos Network: ${cfg.aptosNodeUrl}`);
console.log(`- Contract: ${cfg.contractAddress}`);
console.log(`- Circuits: ${cfg.circuitsPath}`);
console.log(`- Port: ${cfg.port}`);
console.log(`- Environment: ${cfg.nodeEnv}`);
console.log('');
