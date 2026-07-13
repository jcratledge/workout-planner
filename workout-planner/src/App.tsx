import { BrowserRouter, Routes, Route } from 'react-router-dom'
import TvDisplay from './pages/TvDisplay'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/display/:token" element={<TvDisplay />} />
        <Route
          path="*"
          element={
            <div className="min-h-screen flex items-center justify-center">
              <p style={{ color: 'var(--color-ink-muted)' }}>
                Workout Planner — trainer login and builder coming next.
              </p>
            </div>
          }
        />
      </Routes>
    </BrowserRouter>
  )
}
