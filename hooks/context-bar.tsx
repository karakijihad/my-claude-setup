import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { BarSegment } from '../types'

// The context window as one stacked bar above the prompt, one colour per /context category.
// Fetched after each turn rather than while drawing: render fires often, a breakdown is not free.
const segments = atom({ plugin: 'my-claude-setup', key: 'contextBar' } as const, null)

async function refresh($: EngineInterface) {
  const { context } = await $.session.usage({ breakdown: 'summary' })
  const rows = (context.breakdown?.categories ?? []).filter(c => c.kind !== 'deferred' && c.tokens > 0)
  const bar: BarSegment[] = rows.map(c => ({ color: c.color, tokens: c.tokens, isFree: c.kind !== 'used' }))
  await update($, segments, () => (bar.length ? bar : null))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  on('session.compact', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const bar = await read($, segments)
    if (e.props.hasSurvey || bar === null) {
      return next(e)
    }

    const total = bar.reduce((sum, s) => sum + s.tokens, 0)
    const used = bar.filter(s => !s.isFree).reduce((sum, s) => sum + s.tokens, 0)
    const label = ` ${Math.round((used / total) * 100)}%`
    const width = Math.max(10, e.props.bodyColumns - label.length)

    // Cumulative rounding, so the cells always sum to the width exactly.
    let cum = 0
    let drawn = 0
    const cells = bar.map(s => {
      cum += s.tokens
      const end = Math.round((cum / total) * width)
      const n = end - drawn
      drawn = end
      return { ...s, n }
    })

    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box>
        {cells.map((c, i) => (
          <Text key={String(i)} color={c.color} dimColor={c.isFree}>
            {(c.isFree ? '░' : '█').repeat(c.n)}
          </Text>
        ))}
        <Text dimColor>{label}</Text>
      </Box>
    )
  })
}
