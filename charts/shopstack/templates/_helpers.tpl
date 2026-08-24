3. _helpers.tpl

charts/shopstack/templates/_helpers.tpl

{{/*
Expand the name of the chart.
*/}}
{{- define "shopstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "shopstack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "shopstack.name" . }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "shopstack.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "shopstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Frontend name.
*/}}
{{- define "shopstack.frontendName" -}}
{{ include "shopstack.fullname" . }}-frontend
{{- end }}

{{/*
Backend name.
*/}}
{{- define "shopstack.backendName" -}}
{{ include "shopstack.fullname" . }}-backend
{{- end }}

{{/*
Service account name.
*/}}
{{- define "shopstack.serviceAccountName" -}}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- include "shopstack.fullname" . }}
{{- end }}
{{- end }}