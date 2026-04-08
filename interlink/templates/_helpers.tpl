{{/*
Expand the name of the chart.
*/}}
{{- define "interlink.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "interlink.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "interlink.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "interlink.labels" -}}
helm.sh/chart: {{ include "interlink.chart" . }}
{{ include "interlink.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "interlink.selectorLabels" -}}
app.kubernetes.io/name: {{ include "interlink.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "interlink.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "interlink.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Render container resource requests and limits from the CPU/memory sub-key format:
  resources:
    CPU:
      request: "100m"
      limit: "500m"
    memory:
      request: "128Mi"
      limit: "512Mi"
*/}}
{{- define "interlink.containerResources" -}}
{{- $cpu := .CPU -}}
{{- $mem := .memory -}}
{{- if or $cpu $mem -}}
resources:
  {{- if or (and $cpu $cpu.request) (and $mem $mem.request) }}
  requests:
    {{- if and $cpu $cpu.request }}
    cpu: {{ $cpu.request | quote }}
    {{- end }}
    {{- if and $mem $mem.request }}
    memory: {{ $mem.request | quote }}
    {{- end }}
  {{- end }}
  {{- if or (and $cpu $cpu.limit) (and $mem $mem.limit) }}
  limits:
    {{- if and $cpu $cpu.limit }}
    cpu: {{ $cpu.limit | quote }}
    {{- end }}
    {{- if and $mem $mem.limit }}
    memory: {{ $mem.limit | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

