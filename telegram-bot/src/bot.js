import 'dotenv/config';
import { Telegraf } from 'telegraf';
const bot = new Telegraf(process.env.TELEGRAM_BOT_TOKEN || '');

bot.start((ctx) => ctx.reply('zkPrivatePay notifications enabled.'));
bot.command('ping', (ctx) => ctx.reply('pong'));

bot.launch();
