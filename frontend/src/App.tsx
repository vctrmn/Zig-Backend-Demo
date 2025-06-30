import { useState } from 'react'
import './App.css'

function App() {
  console.log("hello world")
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

  return (
    <>
      <div className="card">
        <button onClick={fetchSummary} disabled={loading}>
          {loading ? 'Loading...' : 'Fetch Summary'}
        </button>

        {error && <p style={{ color: 'red' }}>Error: {error}</p>}
        {summary && (
          <div>
            <h3>Summary:</h3>
            <p>{summary}</p>
          </div>
        )}
      </div>
    </>
  )
}

export default App