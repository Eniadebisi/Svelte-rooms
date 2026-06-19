import { collectDefaultMetrics, register } from 'prom-client';

collectDefaultMetrics({ prefix: 'svelte_rooms_' });

export async function GET() {
  return new Response(await register.metrics(), {
    headers: { 'Content-Type': register.contentType }
  });
}
