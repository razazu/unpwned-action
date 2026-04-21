<p align="center">
  <img src="https://unpwned.io/brand/master.png" alt="UNPWNED" width="180">
</p>

<p align="center">
  <strong>UNPWNED Security Scan - GitHub Action</strong><br>
  <em>8 security checks on every push. Fail the build on critical findings.</em>
</p>

<p align="center">
  <a href="https://github.com/marketplace/actions/unpwned-security-scan"><img src="https://img.shields.io/badge/marketplace-UNPWNED-green" alt="Marketplace"></a>
  <a href="https://www.npmjs.com/package/unpwned"><img src="https://img.shields.io/npm/v/unpwned?color=cb3837&label=CLI" alt="CLI version"></a>
  <a href="https://github.com/razazu/unpwned-action/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="license"></a>
</p>

---

Run the [UNPWNED](https://unpwned.io) security scanner on every push or pull request. Detects leaked secrets, missing headers, CVEs, and more. Free, zero config.

## Quick start

```yaml
name: Security scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: razazu/unpwned-action@v1
        with:
          domain: example.com
```

That's it. Every push gets a scan summary in the Actions tab.

## What gets scanned

| Check | Finds |
|:------|:------|
| Security Headers | Missing CSP, HSTS, X-Frame-Options, Referrer-Policy, Permissions-Policy |
| SSL/TLS | Expired certs, weak protocols, self-signed certs |
| DNS Security | Missing SPF, DMARC, DKIM, DNSSEC |
| Cookie Security | Missing Secure, HttpOnly, SameSite flags |
| CORS Policy | Wildcard origins, credential leaks, origin reflection |
| Sensitive Files | Exposed `.env`, `.git/config`, `package.json`, `wp-config.php` |
| Tech Stack | Detects Next.js, React, nginx, Cloudflare, WordPress, more |
| Breaches | Known data breaches on the domain |

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `domain` | yes | - | Domain or URL to scan |
| `fail-on` | no | `critical` | Fail workflow on: `critical`, `high`, `medium`, `low`, `none` |
| `comment-on-pr` | no | `false` | Post results as PR comment (needs `pull-requests: write`) |

## Outputs

| Name | Description |
|------|-------------|
| `score` | Overall security score (0-100) |
| `grade` | Security grade (A+ to F) |
| `critical` | Count of critical findings |
| `high` | Count of high findings |
| `medium` | Count of medium findings |
| `low` | Count of low findings |
| `report-path` | Path to the full JSON report |

## Examples

### Fail the build on high or critical findings

```yaml
- uses: razazu/unpwned-action@v1
  with:
    domain: example.com
    fail-on: high
```

### Comment the results on pull requests

```yaml
permissions:
  pull-requests: write

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: razazu/unpwned-action@v1
        with:
          domain: example.com
          comment-on-pr: true
```

### Use outputs in later steps

```yaml
- id: scan
  uses: razazu/unpwned-action@v1
  with:
    domain: example.com

- name: Alert on low score
  if: ${{ steps.scan.outputs.score < 70 }}
  run: echo "Security score dropped to ${{ steps.scan.outputs.score }}"
```

### Upload the full JSON report as an artifact

```yaml
- id: scan
  uses: razazu/unpwned-action@v1
  with:
    domain: example.com

- uses: actions/upload-artifact@v4
  with:
    name: unpwned-report
    path: ${{ steps.scan.outputs.report-path }}
```

## Want more?

The free action covers 8 checks. The full UNPWNED platform adds 700+ checks, AI fix prompts, continuous monitoring, PDF reports, and GitHub Issues integration.

Visit [unpwned.io](https://unpwned.io) to try it.

## Related

- [UNPWNED CLI](https://github.com/razazu/unpwned-cli) - Run the same scan from your terminal
- [UNPWNED Web](https://unpwned.io) - Full platform with 700+ checks and AI fixes

## License

MIT - [LICENSE](LICENSE)
