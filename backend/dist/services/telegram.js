import { Telegraf } from 'telegraf';
import { cfg } from '../config.js';
let bot = null;
export function startBot() {
    // Fixed: use cfg.telegramBotToken directly, not cfg.telegram.botToken
    if (!cfg.telegramBotToken)
        return;
    bot = new Telegraf(cfg.telegramBotToken);
    bot.start((ctx) => ctx.reply('zkPrivatePay bot ready.'));
    bot.launch();
    process.once('SIGINT', () => bot?.stop('SIGINT'));
    process.once('SIGTERM', () => bot?.stop('SIGTERM'));
}
export async function notify(chatId, msg) {
    if (!bot)
        return;
    try {
        await bot.telegram.sendMessage(chatId, msg);
    }
    catch (error) {
        console.error('Telegram notification failed:', error.message);
    }
}
