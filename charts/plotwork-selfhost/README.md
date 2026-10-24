# plotwork-selfhost

The Helm chart of the self-hosted Plotwork engine: MCP over Streamable HTTP at `/mcp`, the REST drawing routes under `/v1`, and `/healthz`, in non-root, read-only pods that make no outbound request. The [self-hosting guide](https://docs.plotwork.dev/mcp/self-hosting) covers the server, its settings and how agents connect.

## TL;DR

| Question | Answer |
|---|---|
| Where is it? | `oci://ghcr.io/plotwork-official/charts/plotwork-selfhost`, one chart version per engine version, signed with Sigstore |
| What does it install? | A Deployment, a Service, a ServiceAccount with no API token, a NetworkPolicy with no egress, a PodDisruptionBudget, and optionally an Ingress, a HorizontalPodAutoscaler and the token's Secret |
| What must I set? | The token: `auth.existingSecret`, the name of a Secret you made. The chart refuses to render without a token unless `auth.allowOpen` is true |
| Which Kubernetes? | 1.25 or newer |
| Licence | The chart is MIT. The image it runs is under the Plotwork Self-Hosted Licence; see the guide |

## Install

Make the token as a Secret, never in a values file:

```sh
kubectl create namespace plotwork
kubectl -n plotwork create secret generic plotwork --from-literal=token="$(openssl rand -hex 32)"
```

Install a fixed version, the same as the image's:

```sh
helm install plotwork oci://ghcr.io/plotwork-official/charts/plotwork-selfhost \
  --version <version> --namespace plotwork \
  --set auth.existingSecret=plotwork
helm test plotwork -n plotwork
```

Agents in the cluster reach it at `http://plotwork.plotwork.svc:3106/mcp` with `Authorization: Bearer <token>`. A release named `plotwork`, or one whose name holds `plotwork-selfhost`, names its resources after the release; any other release is `<release>-plotwork-selfhost`.

Check the chart before you trust it. It is signed by the public repository's publish workflow:

```sh
cosign verify ghcr.io/plotwork-official/charts/plotwork-selfhost:<version> \
  --certificate-identity-regexp '^https://github.com/plotwork-official/plotwork-selfhost/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

In a network with no internet access, `helm pull` the chart and push it and the image into your own registries, then set `image.repository` to your copy. Set `image.digest` to the digest you verified so every pod runs exactly that image.

## Security defaults

| Setting | Default |
|---|---|
| User | 65532, `runAsNonRoot` |
| Root filesystem | Read-only; the server writes nothing |
| Capabilities | All dropped, no privilege escalation, not privileged |
| Seccomp | `RuntimeDefault` |
| API token | Not mounted; the ServiceAccount and the pod both set `automountServiceAccountToken: false` |
| Service links | Off (`enableServiceLinks: false`), so Kubernetes never overwrites `PLOTWORK_PORT` |
| Egress | None, not even DNS, where the network plugin enforces NetworkPolicy |
| Ingress | The server's port only, from the release's namespace and the namespaces you list |
| Token | From a Secret by reference; the chart refuses a literal shorter than 32 characters |
| Values | Checked by `values.schema.json`; an unknown key stops the install |

Pods in the release's namespace labelled `<full name>-client: "true"` may always call, even with `networkPolicy.ingress.fromReleaseNamespace` false. The `helm test` pod carries that label. An ingress controller in another namespace needs its namespace in `networkPolicy.ingress.namespaces`.

## Values

| Key | Default | Meaning |
|---|---|---|
| `nameOverride` | `""` | Replaces the chart name in resource names and labels. |
| `fullnameOverride` | `""` | Replaces the full resource name. |
| `image.repository` | `plotwork/selfhost` | The image. Point it at your registry's copy. |
| `image.tag` | `""` | The tag; empty means the chart's appVersion. |
| `image.digest` | `""` | A `sha256:` digest, used instead of the tag when set. |
| `image.pullPolicy` | `IfNotPresent` | The pull policy. |
| `imagePullSecrets` | `[]` | Secrets for a private registry, as `[{name: regcred}]`. |
| `replicaCount` | `2` | Pods to run when autoscaling is off. |
| `auth.existingSecret` | `""` | The Secret that holds the token (`PLOTWORK_TOKEN`). Recommended. |
| `auth.existingSecretKey` | `token` | The token's key in that Secret. |
| `auth.token` | `""` | The token itself, put in a Secret the chart makes. It lands in the release history; prefer `existingSecret`. |
| `auth.allowOpen` | `false` | Serves without a token (`PLOTWORK_ALLOW_OPEN=1`). Only where the network is the control. |
| `license.existingSecret` | `""` | The Secret that holds your licence key (`PLOTWORK_LICENSE`). |
| `license.existingSecretKey` | `license` | The licence's key in that Secret. |
| `config.workers` | `2` | Worker threads (`PLOTWORK_WORKERS`). Keep it at or under the pod's CPU. |
| `config.queue` | `32` | Jobs that may wait before more get 503 (`PLOTWORK_QUEUE`). |
| `config.timeoutMs` | `30000` | Deadline of one job, waiting included (`PLOTWORK_TIMEOUT_MS`). |
| `config.workerMemoryMb` | `512` | Heap limit of each worker (`PLOTWORK_WORKER_MEMORY_MB`). |
| `config.maxBodyBytes` | `null` | Largest request body (`PLOTWORK_MAX_BODY_BYTES`); null keeps 4 MiB. |
| `config.mcpResultLimit` | `null` | Characters of an MCP drawing answer before pictures are left out (`PLOTWORK_MCP_RESULT_LIMIT`). |
| `config.tools` | `full` | `full` or `core` (`PLOTWORK_TOOLS`). |
| `config.allowedOrigins` | `[]` | Browser origins allowed to call (`PLOTWORK_ALLOWED_ORIGINS`). |
| `extraEnv` | `[]` | More `env` entries. The host, port, token and open switch belong to the chart and are refused here. |
| `containerPort` | `3106` | The port inside the pod (`PLOTWORK_PORT`). |
| `serviceAccount.create` | `true` | Makes a ServiceAccount. |
| `serviceAccount.name` | `""` | Its name; empty means the full name. |
| `serviceAccount.annotations` | `{}` | Its annotations. |
| `serviceAccount.automountServiceAccountToken` | `false` | Mounts its API token. The server never uses one. |
| `podAnnotations` | `{}` | Annotations on each pod. |
| `podLabels` | `{}` | Labels on each pod. |
| `podSecurityContext` | non-root 65532, `RuntimeDefault` | The pod's security context. |
| `securityContext` | read-only, no capabilities, non-root | The container's security context. |
| `resources` | requests 250m and 256Mi, limit 1Gi | About 250 MB at rest with two workers. |
| `startupProbe` | `/healthz` every 2 s, 30 tries | Startup probe. |
| `livenessProbe` | `/healthz` every 30 s | Liveness probe. |
| `readinessProbe` | `/healthz` every 10 s | Readiness probe. |
| `service.type` | `ClusterIP` | The Service type. |
| `service.port` | `3106` | The Service port. |
| `service.annotations` | `{}` | The Service's annotations. |
| `ingress.enabled` | `false` | Makes an Ingress. Terminate TLS there or in a mesh. |
| `ingress.className` | `""` | The ingress class. |
| `ingress.annotations` | `{}` | The Ingress's annotations. |
| `ingress.hosts` | `plotwork.example.internal`, `/` | Hosts and paths. |
| `ingress.tls` | `[]` | TLS entries, as `[{secretName, hosts}]`. |
| `networkPolicy.enabled` | `true` | Makes the NetworkPolicy: no egress, ingress from the peers below. |
| `networkPolicy.ingress.fromReleaseNamespace` | `true` | Lets every pod in the release's namespace call. |
| `networkPolicy.ingress.namespaces` | `[]` | Namespaces, by name, whose pods may call. |
| `networkPolicy.ingress.namespaceSelectors` | `[]` | Namespace label selectors whose pods may call. |
| `networkPolicy.ingress.extraFrom` | `[]` | More NetworkPolicy peers. |
| `autoscaling.enabled` | `false` | Makes a HorizontalPodAutoscaler. |
| `autoscaling.minReplicas` | `2` | Fewest pods. |
| `autoscaling.maxReplicas` | `6` | Most pods. |
| `autoscaling.targetCPUUtilizationPercentage` | `70` | CPU target. |
| `autoscaling.targetMemoryUtilizationPercentage` | `null` | Memory target, or none. |
| `podDisruptionBudget.enabled` | `true` | Makes a PodDisruptionBudget. |
| `podDisruptionBudget.maxUnavailable` | `1` | Pods a disruption may take at once. |
| `podDisruptionBudget.minAvailable` | `null` | Pods that must stay; used instead when set. |
| `topologySpreadConstraints` | by host and by zone, `ScheduleAnyway` | Spreading; the chart fills in each label selector. `[]` turns it off. |
| `strategy` | rolling, `maxUnavailable` 0, `maxSurge` 1 | How a new version replaces the old. |
| `terminationGracePeriodSeconds` | `40` | Time a stopping pod has to finish its jobs. Keep it above `config.timeoutMs`. |
| `revisionHistoryLimit` | `5` | Old ReplicaSets kept. |
| `priorityClassName` | `""` | The pods' priority class. |
| `nodeSelector` | `{}` | Node selector. |
| `tolerations` | `[]` | Tolerations. |
| `affinity` | `{}` | Affinity. |
| `tests.image` | `curlimages/curl:8.17.0`, by digest | The image `helm test` runs. Point it at your registry's copy in a closed network. |

## Develop

| Command | Use |
|---|---|
| `pnpm --filter @buun/selfhost exec vitest run chart` | Lints and renders the chart across `ci/*-values.yaml` with `helm`, checks the security fields, and runs `kubeconform` when it is on the PATH. Without `helm` the render tests skip, unless `PLOTWORK_REQUIRE_HELM=1`. |
| `helm template plotwork apps/selfhost/chart/plotwork-selfhost -f apps/selfhost/chart/plotwork-selfhost/ci/everything-values.yaml` | Shows what an install with every option would apply. |

The chart's `version` and `appVersion` are the version in `apps/selfhost/package.json`. release-please moves them, and the public repository's publish workflow packages, pushes and signs the chart after the image.
