# Security policy

How to report a vulnerability in the Plotwork self-hosted engine image, and what to expect. It is for anyone who finds a security problem in an image published from this repository.

## TL;DR

| Question | Answer |
|---|---|
| Where do I report? | Use "Report a vulnerability" on the Security tab of this repository. That report is private. |
| Is there an email address? | No. The private report above is the only channel, so every report stays private until a fix is out. |
| Which versions get fixes? | The latest published version. |
| Should I open a public issue? | No. Public issues are for bugs that are not security problems. |

## What the image does

The image runs the diagram engine as one Node process, as user 65532, with a read-only filesystem. It serves MCP at `/mcp` and the REST drawing routes under `/v1`, behind a bearer token, and `/healthz`. It makes no outbound request, sends no telemetry, stores nothing, and logs no diagram text. A report is most useful when it shows one of the following:

- the server reaching the network, writing to disk, or starting another process
- a request that gets past the token, or past the origin check from a browser
- a tool argument or request body that makes the server misbehave, or exhaust memory or CPU past its limits
- diagram text in a log line
- a secret or a path of a build machine inside the image
- an image whose files do not match `checksums.txt`, or whose signature or attestation does not verify

## What to include

Give the image version and digest (`docker inspect --format '{{index .RepoDigests 0}}' <image>`), how you run it, the smallest request that shows the problem, and what you expected instead.

## What happens next

The maintainers acknowledge a report, confirm the problem, and publish a fixed version. A published image is never changed or removed. A fix is a new version, and the release notes of an affected version point to it.

## See also

| Link | Why |
|---|---|
| [README](./README.md) | What the image is, how to run it, and how to verify it |
| [Self-hosting guide](https://docs.plotwork.dev/mcp/self-hosting) | Every setting, Compose, Kubernetes, and connecting agents |
