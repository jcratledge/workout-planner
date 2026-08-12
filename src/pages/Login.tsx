import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../lib/auth'

export default function Login() {
  const { session, signIn } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  if (session) {
    return <Navigate to="/" replace />
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    const { error } = await signIn(email, password)
    setSubmitting(false)
    if (error) setError(error)
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-sm rounded-lg p-8"
        style={{ backgroundColor: 'var(--color-panel)', border: '1px solid var(--color-panel-line)' }}
      >
        <h1 className="text-2xl mb-1" style={{ fontFamily: 'var(--font-display)', color: 'var(--color-ink)' }}>
          WODBoard
        </h1>
        <p className="text-sm mb-6" style={{ color: 'var(--color-ink-muted)' }}>
          Sign in to build today's workout.
        </p>

        <label className="block text-sm mb-1" style={{ color: 'var(--color-ink-muted)' }}>Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoFocus
          className="w-full mb-4 px-3 py-2 rounded outline-none"
          style={{ backgroundColor: 'var(--color-graphite)', border: '1px solid var(--color-panel-line)', color: 'var(--color-ink)' }}
        />

        <label className="block text-sm mb-1" style={{ color: 'var(--color-ink-muted)' }}>Password</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          className="w-full mb-6 px-3 py-2 rounded outline-none"
          style={{ backgroundColor: 'var(--color-graphite)', border: '1px solid var(--color-panel-line)', color: 'var(--color-ink)' }}
        />

        {error && (
          <p className="text-sm mb-4" style={{ color: 'var(--color-accountability)' }}>{error}</p>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-2 rounded font-medium disabled:opacity-50"
          style={{ backgroundColor: 'var(--color-empowerment)', color: 'var(--color-graphite)' }}
        >
          {submitting ? 'Signing in...' : 'Sign in'}
        </button>
      </form>
    </div>
  )
}
