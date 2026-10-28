# Security Policy

## Supported versions

Only the latest release receives fixes while Summwatch is in `0.x`.

## Reporting a vulnerability

Please **don't** open a public issue for security problems. Use GitHub's **private vulnerability reporting** (the "Report a vulnerability" button on the repository's Security tab), or email **GDstudio.plus@gmail.com**.

Please include steps to reproduce, the affected version, and the impact you expect. You should hear back within 7 days.

## Scope notes

- Summwatch only makes HTTPS requests to `127.0.0.1:2999`, validated against Riot's published root certificate, and to Riot's public Data Dragon CDN. Anything that makes it talk to other hosts is in scope.
- Builds before notarization are ad-hoc signed. Download releases only from this repository's GitHub Releases page.
