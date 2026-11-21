import { createServer } from 'node:http'
import type { IncomingMessage, ServerResponse } from 'node:http'

const HOST = '127.0.0.1'

const SECURITY_HEADERS = {
  'content-security-policy': "default-src 'self'",
  'strict-transport-security': 'max-age=63072000; includeSubDomains',
  'x-frame-options': 'DENY',
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'no-referrer',
  'permissions-policy': 'camera=(), microphone=()',
}

type Handler = (req: IncomingMessage, res: ServerResponse) => void

function listen(port: number, handler: Handler): void {
  createServer(handler).listen(port, HOST)
}

listen(4601, (req, res) => {
  if (req.url === '/') {
    res.writeHead(200, { ...SECURITY_HEADERS, 'content-type': 'text/html' })
    res.end('<html><body>Healthy target</body></html>')
    return
  }
  res.writeHead(404, SECURITY_HEADERS)
  res.end('not found')
})

listen(4602, (_req, res) => {
  res.writeHead(403, { 'cf-mitigated': 'challenge', server: 'cloudflare', 'content-type': 'text/html' })
  res.end('<title>Just a moment...</title>')
})

listen(4603, (req, res) => {
  if (req.url === '/') {
    res.writeHead(200, { 'content-type': 'text/html' })
    res.end('<html><body>Target without security headers</body></html>')
    return
  }
  res.writeHead(404)
  res.end('not found')
})

setTimeout(() => process.exit(0), 10 * 60 * 1000).unref()
