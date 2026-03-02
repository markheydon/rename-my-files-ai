# ADR-0005: Rate Limiting Strategy for Azure OpenAI

## Status
Accepted

## Context

The Rename My Files project uses Azure OpenAI to generate descriptive filenames based on file content. Early in development, the deployment was provisioned with a low quota (1K TPM), which led to frequent rate limiting and slow throughput. This affected both user experience and the perceived effectiveness of our rate limiting logic.

Azure OpenAI enforces two main limits:
- **Quota**: The maximum number of tokens per minute (TPM) and requests per minute (RPM) allowed by the deployment.
- **Rate Limiting**: When requests exceed quota, the API returns HTTP 429 with a `Retry-After` header indicating when to retry.

## Decision

- **Default Throttle**: The script now defaults to a 5-second delay (`RequestThrottleSeconds`) between requests, balancing throughput and cost for typical quotas (10K TPM or higher).
- **Prompt Size**: The default prompt size is set to 900 characters (`MaxPromptCharacters`), optimised for cost and compliance with quota.
- **Automatic Handling**: The script automatically parses `Retry-After` headers and applies exponential backoff if rate limited, ensuring robust operation even if quota is temporarily exceeded.
- **User Experience**: For non-technical users, defaults are tuned for low cost and reliability. Advanced users can override throttle and prompt size via parameters.
- **Quota Awareness**: Documentation and deployment guidance now emphasise the importance of setting an appropriate quota in Azure (minimum 10K TPM recommended for reasonable throughput).

## Consequences

- The script is resilient to rate limiting and quota changes, with clear user-facing defaults.
- Throughput is now appropriate for typical quotas, and users can adjust parameters if needed.
- Early results were affected by low quota, but the final strategy is robust for higher quotas and scales with deployment.

## Alternatives Considered

- Aggressive retry/backoff: Rejected due to cost and risk of hitting hard limits.
- Static long delays (30s+): Rejected as unnecessarily slow for higher quotas.
- Manual quota checks: Rejected in favour of automatic handling and clear documentation.

## References
- Azure OpenAI documentation on rate limits and quotas
- Implementation in `scripts/Rename-MyFiles.ps1` (see error handling and throttle logic)

---

*This ADR documents the rationale and final strategy for rate limiting in Rename My Files, ensuring robust, user-friendly operation regardless of quota.*
