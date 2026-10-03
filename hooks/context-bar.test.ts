import { expect, test } from 'claude-code/testing'

const BREAKDOWN = {
  categories: [
    { name: 'System prompt', tokens: 20, color: 'promptBorder', isDeferred: false, kind: 'used' },
    { name: 'Messages', tokens: 30, color: 'permission', isDeferred: false, kind: 'used' },
    { name: 'MCP tools', tokens: 999, color: 'warning', isDeferred: true, kind: 'deferred' },
    { name: 'Free space', tokens: 50, color: 'inactive', isDeferred: false, kind: 'free' },
  ],
}

for (const surface of ['terminal', 'desktop'] as const) {
  test(`draws one segment per used category, sized to the band, on ${surface}`, async ($, on) => {
    on('session.usage', () => ({ value: { context: { window: 100, breakdown: BREAKDOWN } } }) as never)
    on('turn.complete', () => ({ text: '' }) as never)
    await $.turn.complete({ answer: '', text: '' } as never)

    const ui = await $.ui.mount({
      plugin: 'my-claude-setup',
      surface,
      component: 'AbovePrompt',
      props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 44 } as never,
    })

    const texts = await ui.findAll({ type: 'Text' })
    const shown = texts.map(t => t.text)
    // 44 cells less the " 50%" label leaves 40: 20/100, 30/100, 50/100 of it; the deferred row is left out.
    expect(shown).toEqual(['█'.repeat(8), '█'.repeat(12), '░'.repeat(20), ' 50%'])
  })
}

test('passes the band through before the first usage reading', async ($, on) => {
  on('ui.render', () => h('Box', { key: 'engine' }) as never)
  const ui = await $.ui.mount({
    plugin: 'my-claude-setup',
    surface: 'terminal',
    component: 'AbovePrompt',
    props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 44 } as never,
  })
  expect(await ui.find({ key: 'engine' })).toBeDefined()
})
