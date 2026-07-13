/** Maps a block's label to one of the three accent colors defined in the theme.
 *  Falls back to a neutral tone for any block labeled outside the usual
 *  Connection / Empowerment / Accountability convention. */
export function blockAccentVar(label: string): string {
  const l = label.toLowerCase()
  if (l.includes('connection') || l.includes('warm')) return 'var(--color-connection)'
  if (l.includes('empower') || l.includes('work')) return 'var(--color-empowerment)'
  if (l.includes('accountab') || l.includes('finish')) return 'var(--color-accountability)'
  return 'var(--color-ink-muted)'
}
