local obs = import 'observatorium.libsonnet';
{
  apiVersion: 'template.openshift.io/v1',
  kind: 'Template',
  metadata: {
    name: 'observatorium-traces',
  },
  objects: [
    obs.elasticsearch,
  ] + [
    obs.tracing.manifests[name] {
      metadata+: {
      },
    }
    for name in std.objectFields(obs.tracing.manifests)
  ],
  parameters: [
    { name: 'NAMESPACE', value: 'observatorium-traces' },
    { name: 'OPENTELEMETRY_COLLECTOR_IMAGE', value: 'ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib' },
    { name: 'OPENTELEMETRY_COLLECTOR_IMAGE_TAG', value: '0.46.0' },
    { name: 'ELASTICSEARCH_MEMORY', value: '4Gi' },
    { name: 'ELASTICSEARCH_REQUEST_CPU', value: '200m' },
    { name: 'ELASTICSEARCH_NAME', value: 'shared-es' },
    { name: 'ELASTICSEARCH_NODE_COUNT', value: '1' },
    { name: 'ELASTICSEARCH_REDUNDANCY_POLICY', value: 'ZeroRedundancy' },
  ],
}
