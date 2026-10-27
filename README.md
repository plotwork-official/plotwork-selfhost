# Plotwork self-hosted engine

The Plotwork diagram engine as one container, for a company whose diagram text must stay inside its own network: MCP over Streamable HTTP at `/mcp` for your agents, the REST drawing routes under `/v1` for your services, and `/healthz`. No accounts, no hosting, no telemetry, and no outbound request.

## TL;DR

| Question | Answer |
|---|---|
| Where is the image? | `plotwork/selfhost` on Docker Hub and `ghcr.io/plotwork-official/plotwork-selfhost`, the same digest in both |
| Which platforms? | `linux/amd64` and `linux/arm64` |
| Which tag do I use? | A version such as `0.5.1` in production. `latest` follows stable releases, `beta` the previews |
| What is in it? | Distroless Node 24 and the engine's bundle, nothing else: no shell, no package manager |
| How do I check it? | Every image is signed with Sigstore and carries build provenance and an SBOM. See [Verify the image](#verify-the-image) |
| Is it free? | For individuals, non-commercial use, a 30 day evaluation, and organisations under 250 people and USD 10 million a year. Larger organisations need a commercial licence. See [Licence](#licence) |
| Licence | The Plotwork Self-Hosted Licence, in [LICENSE](./LICENSE). The bundle's own components keep their licences, listed in [THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md) |

## Run it

Make a token and keep it in your secret store:

```sh
export PLOTWORK_TOKEN="$(openssl rand -hex 32)"
```

Run the container with the token in its environment:

```sh
docker run -d --name plotwork \
  --read-only --cap-drop ALL --security-opt no-new-privileges \
  -p 127.0.0.1:3106:3106 \
  -e PLOTWORK_TOKEN \
  plotwork/selfhost:0.5.1
```

Check it, then point an agent at `http://<host>:3106/mcp` with the header `Authorization: Bearer <token>`:

```sh
curl -s http://127.0.0.1:3106/healthz
```

Ready-made files for [Compose](./examples/compose.yaml) (an internal network with no route out) and [Kubernetes](./examples/kubernetes.yaml) (non-root, read-only, no egress) are in `examples/`. The [self-hosting guide](https://docs.plotwork.dev/mcp/self-hosting) covers every setting and how to connect each agent.

## Run it with Helm

The [chart](./charts/plotwork-selfhost) is released with each image, at the same version, signed the same way:

```sh
kubectl create namespace plotwork
kubectl -n plotwork create secret generic plotwork --from-literal=token="$(openssl rand -hex 32)"
helm install plotwork oci://ghcr.io/plotwork-official/charts/plotwork-selfhost \
  --version 0.5.1 --namespace plotwork --set auth.existingSecret=plotwork
helm test plotwork -n plotwork
```

It runs two non-root, read-only replicas with no API token, a NetworkPolicy with no egress, and a PodDisruptionBudget. Its [README](./charts/plotwork-selfhost/README.md) lists every value.

## Verify the image

Each image was built by [the publish workflow](./.github/workflows/publish.yml) of this repository, from the files in it, which match [checksums.txt](./checksums.txt). Check a pull before you push it into your own registry:

```sh
cosign verify plotwork/selfhost:0.5.1 \
  --certificate-identity-regexp '^https://github.com/plotwork-official/plotwork-selfhost/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

gh attestation verify oci://plotwork/selfhost:0.5.1 --repo plotwork-official/plotwork-selfhost
```

The build provenance and the SBOM are in the image index:

```sh
docker buildx imagetools inspect plotwork/selfhost:0.5.1 --format '{{ json .Provenance }}'
docker buildx imagetools inspect plotwork/selfhost:0.5.1 --format '{{ json .SBOM }}'
```

## Licence

The image is free to pull, and free to run for:

| Who | Free? |
|---|---|
| An individual, for themselves | Yes |
| A charity, non-profit, school or research institution, for non-commercial work | Yes |
| Any organisation, evaluating it for up to 30 days, not in production | Yes |
| An organisation with fewer than 250 employees and contractors and less than USD 10 million in annual revenue, counting its affiliates, for its own work | Yes |
| Any other organisation | Needs a commercial licence, the self-hosting add-on to a [Plotwork Enterprise](https://plotwork.dev/enterprise) contract |

The image works the same with or without a licence key. Set the key you are given as `PLOTWORK_LICENSE`, and `/healthz` shows its fingerprint so you can tell which licence a server runs. Offering the engine to others as a hosted service needs a written agreement. The full terms are in [LICENSE](./LICENSE); questions go to legal@buungroup.com.

## Tested on a fresh machine

[The verify workflow](./.github/workflows/verify.yml) pulls each release anonymously, from both registries, onto fresh GitHub runners for `linux/amd64` and `linux/arm64`, after every publish and every Monday. It checks the signature and the attestation, runs the image as above, and expects it to report no network and no telemetry, refuse a request without its token, answer MCP, draw a diagram with an icon from its own files, run as user 65532 on a read-only filesystem, and carry its licences. It also starts `examples/compose.yaml` and proves its network has no route out, applies `examples/kubernetes.yaml` to a fresh kind cluster, and installs the signed Helm chart on another and runs its test.

## What this repository holds

| Path | What it is |
|---|---|
| `dist/` | The engine's bundle: the server, the worker, the health check, and the icon art |
| `Dockerfile` | Copies `dist/` and the licences into distroless Node 24, pinned by digest |
| `examples/` | `compose.yaml` and `kubernetes.yaml`, as the verify workflow runs them |
| `charts/plotwork-selfhost/` | The Helm chart, MIT licensed, pushed to `oci://ghcr.io/plotwork-official/charts/plotwork-selfhost` with each release |
| `.github/workflows/` | `publish.yml` builds, signs and publishes a release and its chart; `verify.yml` tests what was published |
| `LICENSE`, `THIRD-PARTY-NOTICES.md` | The Plotwork Self-Hosted Licence, and every component in the bundle with its licence text. Both are in the image under `/licenses` |
| `checksums.txt`, `VERSION` | The SHA-256 of every file, and the version they are |

The files are built and tested in Plotwork's source repository and copied here for each release. A pull request here cannot change a release; report a problem as an issue, or privately as [SECURITY.md](./SECURITY.md) says.
