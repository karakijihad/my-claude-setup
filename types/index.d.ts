export type BarSegment = { color: string; tokens: number; isFree: boolean }

declare module 'claude-code' {
  interface PluginState {
    'my-claude-setup': { contextBar: BarSegment[] | null }
  }
}
