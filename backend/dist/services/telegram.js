import { Telegraf } from 'telegraf';
import { cfg } from '../config.js';
let bot = null;
export function startBot() {
    if (!cfg.telegram.botToken)
        return;
    bot = new Telegraf(cfg.telegram.botToken);
    bot.start((ctx) => ctx.reply('zkPrivatePay bot ready.'));
    bot.launch();
    process.once('SIGINT', () => bot?.stop('SIGINT'));
    process.once('SIGTERM', () => bot?.stop('SIGTERM'));
}
export async function notify(chatId, msg) {
    if (!bot)
        return;
    await bot.telegram.sendMessage(chatId, msg);
}
