export async function generateCommitment(recipient: string, amount: number): Promise<string> {
  const data = new TextEncoder().encode(`${recipient}:${amount}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return Buffer.from(new Uint8Array(digest)).toString('hex');
}
