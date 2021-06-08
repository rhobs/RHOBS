local obs = import 'observatorium.libsonnet';
{
  apiVersion: 'v1',
  kind: 'Template',
  metadata: { name: 'observatorium' },
  objects:
    [
      obs.manifests[name] {
        metadata+: { namespace:: 'hidden' },
      }
      for name in std.objectFields(obs.manifests)
      if obs.manifests[name] != null &&
        !std.startsWith(name, 'thanos-') &&
        !std.startsWith(name, 'loki-')
    ],
  parameters: [
    { name: 'NAMESPACE', value: 'observatorium' },
    // Used for ServiceMonitors to discover workloads in given namespaces.
    // This variable is applied using ${{}} syntax, so make sure to provice valid YAML array.
    // See https://docs.openshift.com/container-platform/4.7/openshift_images/using-templates.html#templates-writing-parameters_using-templates
    { name: 'NAMESPACES', value: '["telemeter", "observatorium-metrics", "observatorium-mst-production"]' },
    { name: 'OBSERVATORIUM_METRICS_NAMESPACE', value: 'observatorium-metrics' },
    { name: 'OBSERVATORIUM_LOGS_NAMESPACE', value: 'observatorium-logs' },
    { name: 'AMS_URL', value: 'https://api.openshift.com' },
    { name: 'DPTP_ORGANIZATION_ID', value: '' },
    { name: 'GUBERNATOR_CPU_LIMIT', value: '200m' },
    { name: 'GUBERNATOR_CPU_REQUEST', value: '100m' },
    { name: 'GUBERNATOR_IMAGE_TAG', value: '1.0.0-rc.1' },
    { name: 'GUBERNATOR_IMAGE', value: 'quay.io/app-sre/gubernator' },
    { name: 'GUBERNATOR_MEMORY_LIMIT', value: '200Mi' },
    { name: 'GUBERNATOR_MEMORY_REQUEST', value: '100Mi' },
    { name: 'GUBERNATOR_REPLICAS', value: '2' },
    { name: 'JAEGER_AGENT_IMAGE_TAG', value: '1.22.0' },
    { name: 'JAEGER_AGENT_IMAGE', value: 'jaegertracing/jaeger-agent' },
    { name: 'JAEGER_COLLECTOR_NAMESPACE', value: '$(NAMESPACE)' },
    { name: 'MANAGEDKAFKA_ORGANIZATION_ID', value: '' },
    { name: 'MEMCACHED_CONNECTION_LIMIT', value: '3072' },
    { name: 'MEMCACHED_CPU_LIMIT', value: '3' },
    { name: 'MEMCACHED_CPU_REQUEST', value: '500m' },
    { name: 'MEMCACHED_EXPORTER_CPU_LIMIT', value: '200m' },
    { name: 'MEMCACHED_EXPORTER_CPU_REQUEST', value: '50m' },
    { name: 'MEMCACHED_EXPORTER_IMAGE_TAG', value: 'v0.6.0' },
    { name: 'MEMCACHED_EXPORTER_IMAGE', value: 'docker.io/prom/memcached-exporter' },
    { name: 'MEMCACHED_EXPORTER_MEMORY_LIMIT', value: '200Mi' },
    { name: 'MEMCACHED_EXPORTER_MEMORY_REQUEST', value: '50Mi' },
    { name: 'MEMCACHED_IMAGE_TAG', value: '1.5.20-alpine' },
    { name: 'MEMCACHED_IMAGE', value: 'docker.io/memcached' },
    { name: 'MEMCACHED_MEMORY_LIMIT_MB', value: '2048' },
    { name: 'MEMCACHED_MEMORY_LIMIT', value: '1844Mi' },
    { name: 'MEMCACHED_MEMORY_REQUEST', value: '1329Mi' },
    { name: 'OAUTH_PROXY_CPU_LIMITS', value: '200m' },
    { name: 'OAUTH_PROXY_CPU_REQUEST', value: '100m' },
    { name: 'OAUTH_PROXY_IMAGE_TAG', value: '4.7.0' },
    { name: 'OAUTH_PROXY_IMAGE', value: 'quay.io/openshift/origin-oauth-proxy' },
    { name: 'OAUTH_PROXY_MEMORY_LIMITS', value: '200Mi' },
    { name: 'OAUTH_PROXY_MEMORY_REQUEST', value: '100Mi' },
    { name: 'OBSERVATORIUM_API_CPU_LIMIT', value: '1' },
    { name: 'OBSERVATORIUM_API_CPU_REQUEST', value: '100m' },
    { name: 'OBSERVATORIUM_API_IDENTIFIER', value: 'observatorium-observatorium-api' },
    { name: 'OBSERVATORIUM_API_IMAGE_TAG', value: 'master-2021-03-26-v0.1.1-200-gea0242a' },
    { name: 'OBSERVATORIUM_API_IMAGE', value: 'quay.io/observatorium/api' },
    { name: 'OBSERVATORIUM_API_MEMORY_LIMIT', value: '1Gi' },
    { name: 'OBSERVATORIUM_API_MEMORY_REQUEST', value: '256Mi' },
    { name: 'OBSERVATORIUM_API_REPLICAS', value: '3' },
    { name: 'OBSERVATORIUM_API_PER_POD_CONCURRENT_REQUETST_LIMIT', value: '50' },
    { name: 'OPA_AMS_CPU_LIMIT', value: '200m' },
    { name: 'OPA_AMS_CPU_REQUEST', value: '100m' },
    { name: 'OPA_AMS_IMAGE_TAG', value: 'master-2021-02-17-ed50046' },
    { name: 'OPA_AMS_IMAGE', value: 'quay.io/observatorium/opa-ams' },
    { name: 'OPA_AMS_MEMCACHED_EXPIRE', value: '300' },
    { name: 'OPA_AMS_MEMORY_LIMIT', value: '200Mi' },
    { name: 'OPA_AMS_MEMORY_REQUEST', value: '100Mi' },
    { name: 'OSD_ORGANIZATION_ID', value: '' },
    { name: 'SERVICE_ACCOUNT_NAME', value: 'prometheus-telemeter' },
  ],
}
