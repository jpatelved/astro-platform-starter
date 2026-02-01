import { useState, useEffect } from 'react';

interface TradeInsight {
    id: string;
    symbol: string;
    action: 'buy' | 'sell' | 'hold';
    price: number;
    reasoning: string;
    confidence: 'high' | 'medium' | 'low';
    created_at: string;
}

export default function TradeInsights() {
    const [insights, setInsights] = useState<TradeInsight[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        fetchInsights();
        const interval = setInterval(fetchInsights, 60000);
        return () => clearInterval(interval);
    }, []);

    const fetchInsights = async () => {
        try {
            const response = await fetch('/api/trade-insights?limit=10');
            const data = await response.json();

            if (data.insights) {
                setInsights(data.insights);
                setError(null);
            }
        } catch (err) {
            setError('Failed to load trade insights');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const getActionColor = (action: string) => {
        switch (action) {
            case 'buy':
                return 'bg-green-500/20 text-green-300 border-green-500/30';
            case 'sell':
                return 'bg-red-500/20 text-red-300 border-red-500/30';
            case 'hold':
                return 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30';
            default:
                return 'bg-gray-500/20 text-gray-300 border-gray-500/30';
        }
    };

    const getConfidenceBadge = (confidence: string) => {
        const colors = {
            high: 'bg-blue-500/20 text-blue-300',
            medium: 'bg-purple-500/20 text-purple-300',
            low: 'bg-gray-500/20 text-gray-400'
        };
        return colors[confidence] || colors.medium;
    };

    const formatDate = (dateString: string) => {
        const date = new Date(dateString);
        const now = new Date();
        const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

        if (diffInHours < 24) {
            return date.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });
        }
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        });
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center py-12">
                <div className="text-lg opacity-70">Loading trade insights...</div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="p-6 rounded-lg bg-red-500/10 border border-red-500/30">
                <p className="text-red-300">{error}</p>
            </div>
        );
    }

    if (insights.length === 0) {
        return (
            <div className="p-8 text-center rounded-lg bg-gray-800/30 border border-gray-700">
                <p className="text-lg opacity-70">No trade insights available yet.</p>
                <p className="mt-2 text-sm opacity-50">Connect your Make.com workflow to start receiving insights.</p>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            {insights.map((insight) => (
                <div
                    key={insight.id}
                    className="p-6 transition-all duration-200 border rounded-lg bg-gray-800/40 border-gray-700 hover:border-primary/50 hover:bg-gray-800/60"
                >
                    <div className="flex flex-wrap items-start justify-between gap-3 mb-3">
                        <div className="flex items-center gap-3">
                            <span className="text-2xl font-bold text-white">{insight.symbol}</span>
                            <span
                                className={`px-3 py-1 text-sm font-semibold uppercase rounded border ${getActionColor(insight.action)}`}
                            >
                                {insight.action}
                            </span>
                        </div>
                        <div className="flex items-center gap-3">
                            <span className={`px-2 py-1 text-xs font-medium uppercase rounded ${getConfidenceBadge(insight.confidence)}`}>
                                {insight.confidence}
                            </span>
                            <span className="text-sm opacity-60">{formatDate(insight.created_at)}</span>
                        </div>
                    </div>

                    <div className="mb-3">
                        <span className="text-xl font-semibold text-primary">${insight.price.toFixed(2)}</span>
                    </div>

                    <p className="leading-relaxed opacity-90">{insight.reasoning}</p>
                </div>
            ))}
        </div>
    );
}
