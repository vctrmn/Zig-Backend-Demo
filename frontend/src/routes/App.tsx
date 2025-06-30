import { useState } from 'react'
import { Button } from '@/components/ui/button'

function App() {
  const [summary, setSummary] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const fetchSummary = async () => {
    setLoading(true)
    setError('')

    try {
      const response = await fetch('/api/summary')
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const data = await response.json()
      setSummary(data.summary || JSON.stringify(data))
    } catch (err) {
      if (err instanceof Error) {
        setError(err.message)
      } else {
        setError(String(err))
      }
    } finally {
      setLoading(false)
    }
  }

  const formatSummary = (summaryData) => {
    try {
      const parsed = JSON.parse(summaryData)

      if (parsed.total_expenses !== undefined && parsed.expense_count !== undefined) {
        return (
          <div className="space-y-2">
            <div>Total Expenses: ${parsed.total_expenses}</div>
            <div>Expense Count: {parsed.expense_count}</div>
            <div>Average Expense: ${parsed.average_expense.toFixed(2)}</div>
          </div>
        )
      }

      return <pre className="text-sm">{JSON.stringify(parsed, null, 2)}</pre>
    } catch (e) {
      return <div>{summaryData}</div>
    }
  }

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
  )
}

export default App