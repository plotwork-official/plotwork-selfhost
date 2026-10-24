{{/*
The chart name, cut to the 63 characters a label value allows.
*/}}
{{- define "plotwork.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The full name of every resource. A release named `plotwork`, or one whose name holds the chart name, is used as it is, so
`helm install plotwork` makes a Service named `plotwork`, not `plotwork-plotwork-selfhost`.
*/}}
{{- define "plotwork.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if or (contains $name .Release.Name) (hasPrefix (printf "%s-" .Release.Name) $name) }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "plotwork.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "plotwork.selectorLabels" -}}
app.kubernetes.io/name: {{ include "plotwork.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "plotwork.labels" -}}
helm.sh/chart: {{ include "plotwork.chart" . }}
{{ include "plotwork.selectorLabels" . }}
app.kubernetes.io/version: {{ include "plotwork.imageTag" . | quote }}
app.kubernetes.io/component: engine
app.kubernetes.io/part-of: plotwork
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
The label a pod in the release's namespace carries to be let through the NetworkPolicy, whatever else it allows.
*/}}
{{- define "plotwork.clientLabel" -}}
{{- printf "%s-client" (include "plotwork.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "plotwork.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "plotwork.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "plotwork.imageTag" -}}
{{- default .Chart.AppVersion .Values.image.tag }}
{{- end }}

{{/*
The image reference: by digest when one is given, so the pod runs exactly the image that was verified, by tag otherwise.
*/}}
{{- define "plotwork.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (include "plotwork.imageTag" .) }}
{{- end }}
{{- end }}

{{/*
The Secret that holds the token, and its key. Empty when the server runs open.
*/}}
{{- define "plotwork.tokenSecretName" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecret }}
{{- else if .Values.auth.token }}
{{- include "plotwork.fullname" . }}
{{- end }}
{{- end }}

{{- define "plotwork.tokenSecretKey" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecretKey }}
{{- else }}
{{- print "token" }}
{{- end }}
{{- end }}

{{/*
Stops the render with a sentence that names the fix when the values cannot make a working server. The server would stop at
start for the same reasons; failing here says so before anything reaches the cluster.
*/}}
{{- define "plotwork.validate" -}}
{{- if and (not .Values.auth.existingSecret) (not .Values.auth.token) (not .Values.auth.allowOpen) }}
{{- fail "plotwork-selfhost needs a token. Create a Secret (kubectl create secret generic plotwork --from-literal=token=\"$(openssl rand -hex 32)\") and set auth.existingSecret=plotwork, or set auth.allowOpen=true where the network is the control." }}
{{- end }}
{{- if and (not .Values.auth.existingSecret) .Values.auth.token (lt (len .Values.auth.token) 32) }}
{{- fail "auth.token must be at least 32 characters. Make one with: openssl rand -hex 32" }}
{{- end }}
{{- if and (not .Values.autoscaling.enabled) .Values.podDisruptionBudget.enabled (le (int .Values.replicaCount) 1) (not .Values.podDisruptionBudget.minAvailable) (eq (int .Values.podDisruptionBudget.maxUnavailable) 0) }}
{{- fail "podDisruptionBudget.maxUnavailable is 0 with one replica, so no node could ever be drained. Raise replicaCount or maxUnavailable." }}
{{- end }}
{{- end }}
