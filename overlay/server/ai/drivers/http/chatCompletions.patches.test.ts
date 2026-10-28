import { describe, it, expect } from 'bun:test'
import { normalizeOpenAiBaseUrl, openAiEndpoint } from './chatCompletions'

describe('openAiEndpoint (patched /v1 handling)', () => {
  // Upstream-compatible cases (identical output to old behavior):
  it('appends /v1 to bare base URLs', () => {
    expect(openAiEndpoint('http://localhost:11434', 'chat/completions')).toBe('http://localhost:11434/v1/chat/completions')
    expect(openAiEndpoint('https://api.groq.com/openai', 'chat/completions')).toBe('https://api.groq.com/openai/v1/chat/completions')
  })
  it('reuses an existing version segment instead of forcing /v1', () => {
    expect(openAiEndpoint('https://api.z.ai/api/paas/v4/', 'chat/completions')).toBe('https://api.z.ai/api/paas/v4/chat/completions')
    expect(openAiEndpoint('https://api.groq.com/openai/v1', 'chat/completions')).toBe('https://api.groq.com/openai/v1/chat/completions')
    expect(openAiEndpoint('https://api.groq.com/openai/v1/', 'models')).toBe('https://api.groq.com/openai/v1/models')
  })
  it('uses a pasted full endpoint verbatim', () => {
    expect(openAiEndpoint('https://gw.example.com/custom/chat/completions', 'chat/completions')).toBe('https://gw.example.com/custom/chat/completions')
  })
  it('normalizer keeps upstream behavior', () => {
    expect(normalizeOpenAiBaseUrl('https://api.groq.com/openai/v1/')).toBe('https://api.groq.com/openai')
    expect(normalizeOpenAiBaseUrl('http://localhost:11434')).toBe('http://localhost:11434')
  })
})
