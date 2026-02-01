import type { APIRoute } from 'astro';

export const prerender = false;

const SUPABASE_URL = import.meta.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.SUPABASE_ANON_KEY;

export const POST: APIRoute = async ({ request }) => {
    try {
        const data = await request.json();

        const { symbol, action, price, reasoning, confidence, metadata } = data;

        if (!symbol || !action || !price || !reasoning) {
            return new Response(
                JSON.stringify({
                    error: 'Missing required fields: symbol, action, price, reasoning'
                }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            );
        }

        if (!['buy', 'sell', 'hold'].includes(action)) {
            return new Response(
                JSON.stringify({
                    error: 'Invalid action. Must be: buy, sell, or hold'
                }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            );
        }

        const response = await fetch(`${SUPABASE_URL}/rest/v1/trade_insights`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                apikey: SUPABASE_ANON_KEY,
                Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
                Prefer: 'return=representation'
            },
            body: JSON.stringify({
                symbol: symbol.toUpperCase(),
                action,
                price: parseFloat(price),
                reasoning,
                confidence: confidence || 'medium',
                metadata: metadata || {}
            })
        });

        if (!response.ok) {
            const error = await response.text();
            return new Response(
                JSON.stringify({
                    error: 'Failed to store trade insight',
                    details: error
                }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            );
        }

        const result = await response.json();

        return new Response(
            JSON.stringify({
                success: true,
                data: result[0]
            }),
            { status: 201, headers: { 'Content-Type': 'application/json' } }
        );
    } catch (error) {
        return new Response(
            JSON.stringify({
                error: 'Internal server error',
                message: error.message
            }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
    }
};

export const GET: APIRoute = async ({ url }) => {
    try {
        const limit = url.searchParams.get('limit') || '10';

        const response = await fetch(
            `${SUPABASE_URL}/rest/v1/trade_insights?select=*&order=created_at.desc&limit=${limit}`,
            {
                headers: {
                    apikey: SUPABASE_ANON_KEY,
                    Authorization: `Bearer ${SUPABASE_ANON_KEY}`
                }
            }
        );

        if (!response.ok) {
            const error = await response.text();
            return new Response(
                JSON.stringify({
                    error: 'Failed to fetch trade insights',
                    details: error
                }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            );
        }

        const insights = await response.json();

        return new Response(JSON.stringify({ insights }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });
    } catch (error) {
        return new Response(
            JSON.stringify({
                error: 'Internal server error',
                message: error.message
            }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
    }
};
