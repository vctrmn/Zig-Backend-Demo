import { useState } from "react";

import { Button } from "@/components/ui/button";

type SummaryResponse = {
  total_expenses: number;
  expense_count: number;
  average_expense: number;
};

function App() {
  const [summary, setSummary] = useState<SummaryResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const fetchSummary = async () => {
    setLoading(true);
    setError("");

    try {
      const response = await fetch("/api/summary");
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setSummary(data || null);
    } catch (err) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError(String(err));
      }
    } finally {
      setLoading(false);
    }
  };

  const formatSummary = (summaryData: SummaryResponse | null) => {
    if (!summaryData) return null;

    return (
      <div className="space-y-2">
        <div>Total Expenses: ${summaryData.total_expenses}</div>
        <div>Expense Count: {summaryData.expense_count}</div>
        <div>Average Expense: ${summaryData.average_expense.toFixed(2)}</div>
      </div>
    );
  };

  return (
    <div className="p-4">
      <Button onClick={fetchSummary} disabled={loading}>
        Fetch Summary
      </Button>

      {error && <div className="mt-4 text-red-500">Error: {error}</div>}

      {summary && (
        <div className="mt-4">
          {formatSummary(summary)}
        </div>
      )}
    </div>
  );
}

export default App;
