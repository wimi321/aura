# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.2.x   | Yes       |
| < 0.2   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in Aura, please report it responsibly:

1. **Do not** open a public issue.
2. Email a description of the vulnerability to the maintainers via GitHub private messaging, or open a [GitHub Security Advisory](https://github.com/wimi321/aura/security/advisories/new).
3. Include steps to reproduce, affected versions, and potential impact.

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation plan within 7 days.

## Scope

Aura runs inference entirely on-device. The primary security considerations are:

- **Model file integrity**: Downloaded models are verified with SHA256 checksums.
- **Character card parsing**: PNG steganography and JSON parsing handle untrusted input; vulnerabilities in these parsers are in scope.
- **Local data storage**: Conversation history, character cards, and preferences are stored locally on the device.
- **No network after setup**: After the initial model download, Aura does not make network requests during normal use.

## Out of Scope

- Vulnerabilities in upstream dependencies (Flutter, LiteRT-LM) should be reported to their respective maintainers.
- Jailbreaking or prompt injection against the local LLM is not a security vulnerability — it is expected behavior for a local, user-controlled model.
