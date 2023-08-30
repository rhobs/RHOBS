local obs = import 'observatorium.libsonnet';
{
  apiVersion: 'template.openshift.io/v1',
  kind: 'Template',
  metadata: { name: 'observatorium' },
  objects:
    [
      obs.manifests[name] {
        metadata+: { namespace:: 'hidden' },
      }
      for name in std.objectFields(obs.manifests)
      if obs.manifests[name] != null &&
         !std.startsWith(name, 'observatorium/thanos-') &&
         !std.startsWith(name, 'observatorium/loki-') &&
         !std.startsWith(name, 'observatorium/tracing-')
    ],
  parameters: [
    { name: 'NAMESPACE', value: 'observatorium' },
    // Used for ServiceMonitors to discover workloads in given namespaces.
    // This variable is applied using ${{}} syntax, so make sure to provide valid YAML array.
    // See https://docs.openshift.com/container-platform/4.7/openshift_images/using-templates.html#templates-writing-parameters_using-templates
    { name: 'NAMESPACES', value: '["telemeter", "observatorium-metrics", "observatorium-mst-production"]' },
    { name: 'OBSERVATORIUM_METRICS_NAMESPACE', value: 'observatorium-metrics' },
    { name: 'OBSERVATORIUM_LOGS_NAMESPACE', value: 'observatorium-logs' },
    { name: 'OBSERVATORIUM_TRACES_NAMESPACE', value: 'observatorium-traces' },
    { name: 'AMS_URL', value: 'https://api.openshift.com' },
    { name: 'GUBERNATOR_CPU_LIMIT', value: '600m' },
    { name: 'GUBERNATOR_CPU_REQUEST', value: '300m' },
    { name: 'GUBERNATOR_IMAGE_TAG', value: 'v2.0.0-rc.36' },
    { name: 'GUBERNATOR_IMAGE', value: 'quay.io/app-sre/gubernator' },
    { name: 'GUBERNATOR_MEMORY_LIMIT', value: '200Mi' },
    { name: 'GUBERNATOR_MEMORY_REQUEST', value: '100Mi' },
    { name: 'GUBERNATOR_REPLICAS', value: '2' },
    { name: 'JAEGER_AGENT_IMAGE_TAG', value: '1.29.0' },
    { name: 'JAEGER_AGENT_IMAGE', value: 'jaegertracing/jaeger-agent' },
    { name: 'JAEGER_COLLECTOR_NAMESPACE', value: '$(NAMESPACE)' },
    { name: 'MEMCACHED_CONNECTION_LIMIT', value: '3072' },
    { name: 'MEMCACHED_CPU_LIMIT', value: '3' },
    { name: 'MEMCACHED_CPU_REQUEST', value: '500m' },
    { name: 'MEMCACHED_EXPORTER_CPU_LIMIT', value: '200m' },
    { name: 'MEMCACHED_EXPORTER_CPU_REQUEST', value: '50m' },
    { name: 'MEMCACHED_EXPORTER_IMAGE_TAG', value: 'v0.6.0' },
    { name: 'MEMCACHED_EXPORTER_IMAGE', value: 'docker.io/prom/memcached-exporter' },
    { name: 'MEMCACHED_EXPORTER_MEMORY_LIMIT', value: '200Mi' },
    { name: 'MEMCACHED_EXPORTER_MEMORY_REQUEST', value: '50Mi' },
    { name: 'MEMCACHED_IMAGE_TAG', value: '1.6.13-alpine' },
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
    { name: 'OBSERVATORIUM_API_IMAGE_TAG', value: 'main-2023-08-17-3f47d62' },
    { name: 'OBSERVATORIUM_API_IMAGE', value: 'quay.io/observatorium/api' },
    { name: 'OBSERVATORIUM_API_MEMORY_LIMIT', value: '1Gi' },
    { name: 'OBSERVATORIUM_API_MEMORY_REQUEST', value: '256Mi' },
    { name: 'OBSERVATORIUM_API_REPLICAS', value: '3' },
    { name: 'OBSERVATORIUM_API_PER_POD_CONCURRENT_REQUETST_LIMIT', value: '50' },
    { name: 'OBSERVATORIUM_API_LOG_LEVEL', value: 'warn' },
    { name: 'OPA_AMS_CPU_LIMIT', value: '200m' },
    { name: 'OPA_AMS_CPU_REQUEST', value: '100m' },
    { name: 'OPA_AMS_IMAGE_TAG', value: 'master-2022-11-03-222daab' },
    { name: 'OPA_AMS_IMAGE', value: 'quay.io/observatorium/opa-ams' },
    { name: 'OPA_AMS_MEMCACHED_EXPIRE', value: '300' },
    { name: 'OPA_AMS_MEMORY_LIMIT', value: '200Mi' },
    { name: 'OPA_AMS_MEMORY_REQUEST', value: '100Mi' },
    { name: 'OPA_AMS_LOG_LEVEL', value: 'warn' },
    { name: 'RULES_OBJSTORE_IMAGE', value: 'quay.io/observatorium/rules-objstore' },
    { name: 'RULES_OBJSTORE_IMAGE_TAG', value: 'main-2022-09-21-9df4d2c' },
    { name: 'RULES_OBJSTORE_S3_SECRET', value: 'rules-objstore-stage-s3' },
    { name: 'RULES_OBJSTORE_SECRET', value: 'rules-objstore' },
    { name: 'RULES_OBJSTORE_LOG_LEVEL', value: 'info' },
    { name: 'SERVICE_ACCOUNT_NAME', value: 'prometheus-telemeter' },
    { name: 'UP_CPU_REQUEST', value: '100m' },
    { name: 'UP_CPU_LIMIT', value: '500m' },
    { name: 'UP_MEMORY_REQUEST', value: '1Gi' },
    { name: 'UP_MEMORY_LIMIT', value: '2Gi' },
    { name: 'UP_REPLICAS', value: '1' },
    { name: 'AVALANCHE_REPLICAS', value: '1' },
    { name: 'OBSERVATORIUM_URL', value: 'http://observatorium-observatorium-api.${NAMESPACE}.svc:8080' },
    { name: 'OIDC_AUDIENCE', value: 'observatorium' },
    { name: 'OIDC_ISSUER_URL', value: 'https://sso.redhat.com/auth/realms/redhat-external' },
    { name: 'SLEEP_DURATION_SECONDS', value: '15' },
    { name: 'MANAGED_TENANTS', value: 'rhobs,osd,appsre' },
    { name: 'RHOBS_RELOADER_SECRET_NAME', value: 'rhobs-tenant' },
    { name: 'OSD_RELOADER_SECRET_NAME', value: 'observatorium-observatorium-mst-api' },
    { name: 'HYPERSHIFT_PLATFORM_STAGING_RELOADER_SECRET_NAME', value: 'rhobs-hypershift-platform-staging-tenant' },
    { name: 'HYPERSHIFT_PLATFORM_RELOADER_SECRET_NAME', value: 'rhobs-hypershift-platform-tenant' },
    { name: 'APPSRE_RELOADER_SECRET_NAME', value: 'observatorium-appsre' },
    { name: 'RHTAP_RELOADER_SECRET_NAME', value: 'observatorium-rhtap' },
    { name: 'LOG_RULES_ENABLED', value: 'true' },
    { name: 'OBSCTL_RELOADER_IMAGE', value: 'quay.io/app-sre/obsctl-reloader' },
    { name: 'OBSCTL_RELOADER_IMAGE_TAG', value: '6743d93' },
    { name: 'METRICS_WRITE_SERVICE_NAME', value: obs.thanos.receiversService.metadata.name },
    { name: 'METRICS_WRITE_SERVICE_PORT', value: std.toString(obs.thanos.receiversService.spec.ports[2].port) },
    // AMS Org IDs
    { name: 'CNVQE_ORGANIZATION_ID', value: '' },
    { name: 'OSD_ORGANIZATION_ID', value: '' },
    { name: 'SD_OPS_ORGANIZATION_ID', value: '' },
    { name: 'ALERTMANAGER_API_ENDPOINT', value: '' },
  ],
}
