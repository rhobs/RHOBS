local c = import 'github.com/conprof/conprof/deployments/jsonnet/conprof/conprof.libsonnet';

local conprof = c + c.withConfigMap {
  local conprof = self,

  config+:: {
    name: 'conprof',
    namespace: '${NAMESPACE}',  // Target namespace to deploy Conprof.
    image: '${IMAGE}:${IMAGE_TAG}',
    version: '${IMAGE_TAG}',

    serviceAccountName: '${SERVICE_ACCOUNT_NAME}',

    namespaces: {
      default: '${NAMESPACE}',
      metrics: '${OBSERVATORIUM_METRICS_NAMESPACE}',
      mst: '${OBSERVATORIUM_MST_NAMESPACE}',
      logs: '${OBSERVATORIUM_LOGS_NAMESPACE}',
    },

    rawconfig+:: {
      scrape_configs: [{
        job_name: 'thanos',
        kubernetes_sd_configs: [{
          namespaces: { names: [
            conprof.config.namespaces.default,
            conprof.config.namespaces.metrics,
            conprof.config.namespaces.mst,
          ] },
          role: 'pod',
        }],
        relabel_configs: [
          {
            action: 'keep',
            regex: 'observatorium-thanos-.+',
            source_labels: ['__meta_kubernetes_pod_name'],
          },
          {
            action: 'keep',
            regex: 'http',
            source_labels: ['__meta_kubernetes_pod_container_port_name'],
          },
          {
            source_labels: ['__meta_kubernetes_namespace'],
            target_label: 'namespace',
          },
          {
            source_labels: ['__meta_kubernetes_pod_name'],
            target_label: 'pod',
          },
          {
            source_labels: ['__meta_kubernetes_pod_container_name'],
            target_label: 'container',
          },
        ],
        scrape_interval: '30s',
        scrape_timeout: '1m',
      }, {
        job_name: 'loki',
        kubernetes_sd_configs: [{
          namespaces: { names: ['${OBSERVATORIUM_LOGS_NAMESPACE}'] },
          role: 'pod',
        }],
        relabel_configs: [
          {
            action: 'keep',
            regex: 'observatorium-loki-.+',
            source_labels: ['__meta_kubernetes_pod_name'],
          },
          {
            action: 'keep',
            regex: 'observatorium-loki-.+',
            source_labels: ['__meta_kubernetes_pod_container_name'],
          },
          {
            action: 'keep',
            regex: 'metrics',
            source_labels: ['__meta_kubernetes_pod_container_port_name'],
          },
          {
            source_labels: ['__meta_kubernetes_namespace'],
            target_label: 'namespace',
          },
          {
            source_labels: ['__meta_kubernetes_pod_name'],
            target_label: 'pod',
          },
          {
            source_labels: ['__meta_kubernetes_pod_container_name'],
            target_label: 'container',
          },
        ],
        scrape_interval: '30s',
        scrape_timeout: '1m',
      }, {
        job_name: 'telemeter',
        kubernetes_sd_configs: [{
          namespaces: { names: [conprof.config.namespaces.default] },
          role: 'pod',
        }],
        relabel_configs: [
          {
            action: 'keep',
            regex: 'telemeter-server-.+',
            source_labels: ['__meta_kubernetes_pod_name'],
          },
          {
            action: 'keep',
            regex: 'internal',
            source_labels: ['__meta_kubernetes_pod_container_port_name'],
          },
          {
            source_labels: ['__meta_kubernetes_namespace'],
            target_label: 'namespace',
          },
          {
            source_labels: ['__meta_kubernetes_pod_name'],
            target_label: 'pod',
          },
          {
            source_labels: ['__meta_kubernetes_pod_container_name'],
            target_label: 'container',
          },
        ],
        scrape_interval: '30s',
        scrape_timeout: '1m',
        scheme: 'https',
        tls_config: {
          insecure_skip_verify: true,
        },
      }],
    },
  },

  roles:
    local newSpecificRole(namespace) = {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'Role',
      metadata: {
        name: conprof.config.name + '-' + namespace,
        namespace: namespace,
        labels: conprof.config.commonLabels,
      },
      rules: [{
        apiGroups: [''],
        resources: ['services', 'endpoints', 'pods'],
        verbs: ['get', 'list', 'watch'],
      }],
    };
    {
      'conprof-observatorium': newSpecificRole(conprof.config.namespaces.default),
      'conprof-observatorium-metrics': newSpecificRole(conprof.config.namespaces.metrics),
      'conprof-observatorium-mst': newSpecificRole(conprof.config.namespaces.mst),
      'conprof-observatorium-logs': newSpecificRole(conprof.config.namespaces.logs),
    },

  roleBindings:
    local newSpecificRoleBinding(namespace) = {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'RoleBinding',
      metadata: {
        name: conprof.config.name + '-' + namespace,
        namespace: namespace,
        labels: conprof.config.commonLabels,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'Role',
        name: conprof.config.name + '-' + namespace,
      },
      subjects: [{ kind: 'ServiceAccount', name: conprof.config.serviceAccountName, namespace: conprof.config.namespace }],
    };

    {
      'conprof-observatorium': newSpecificRoleBinding(conprof.config.namespaces.default),
      'conprof-observatorium-metrics': newSpecificRoleBinding(conprof.config.namespaces.metrics),
      'conprof-observatorium-mst': newSpecificRoleBinding(conprof.config.namespaces.mst),
      'conprof-observatorium-logs': newSpecificRoleBinding(conprof.config.namespaces.logs),
    },

  service+: {
    metadata+: {
      annotations+: {
        'service.alpha.openshift.io/serving-cert-secret-name': 'conprof-tls',
      },
    },
    spec+: {
      ports: [
        { name: 'http', port: 10902, targetPort: 10902 },
        { name: 'https', port: 8443, targetPort: 8443 },
      ],
    },
  },

  local c = {
    name: 'proxy',
    image: '${OAUTH_PROXY_IMAGE}:${OAUTH_PROXY_IMAGE_TAG}',
    args: [
      '-provider=openshift',
      '-https-address=:%d' % conprof.service.spec.ports[1].port,
      '-http-address=',
      '-email-domain=*',
      '-upstream=http://localhost:%d' % conprof.service.spec.ports[0].port,
      '-openshift-service-account=' + conprof.config.serviceAccountName,
      '-openshift-sar={"resource": "namespaces", "verb": "get", "name": "${NAMESPACE}", "namespace": "${NAMESPACE}"}',
      '-openshift-delegate-urls={"/": {"resource": "namespaces", "verb": "get", "name": "${NAMESPACE}", "namespace": "${NAMESPACE}"}}',
      '-tls-cert=/etc/tls/private/tls.crt',
      '-tls-key=/etc/tls/private/tls.key',
      '-client-secret-file=/var/run/secrets/kubernetes.io/serviceaccount/token',
      '-cookie-secret-file=/etc/proxy/secrets/session_secret',
      '-openshift-ca=/etc/pki/tls/cert.pem',
      '-openshift-ca=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
    ],
    ports: [
      { name: 'https', containerPort: conprof.service.spec.ports[1].port },
    ],
    volumeMounts: [
      { name: 'secret-conprof-tls', mountPath: '/etc/tls/private', readOnly: false },
      { name: 'secret-conprof-proxy', mountPath: '/etc/proxy/secrets', readOnly: false },
    ],
    resources: {
      requests: {
        cpu: '${CONPROF_PROXY_CPU_REQUEST}',
        memory: '${CONPROF_PROXY_MEMORY_REQUEST}',
      },
      limits: {
        cpu: '${CONPROF_PROXY_CPU_LIMITS}',
        memory: '${CONPROF_PROXY_MEMORY_LIMITS}',
      },
    },
  },

  statefulset+: {
    spec+: {
      replicas: '${{CONPROF_REPLICAS}}',
      template+: {
        spec+: {
          containers: std.map(
            function(c) if c.name == 'conprof' then c {
              resources: {
                requests: {
                  cpu: '${CONPROF_CPU_REQUEST}',
                  memory: '${CONPROF_MEMORY_REQUEST}',
                },
                limits: {
                  cpu: '${CONPROF_CPU_LIMITS}',
                  memory: '${CONPROF_MEMORY_LIMITS}',
                },
              },
            } else c,
            super.containers
          ) + [c],
          serviceAccountName: conprof.config.serviceAccountName,
          volumes+: [
            { name: 'secret-conprof-tls', secret: { secretName: 'conprof-tls' } },
            { name: 'secret-conprof-proxy', secret: { secretName: 'conprof-proxy' } },
          ],
        },
      },
    },
  },
};

{
  'conprof-template': {
    apiVersion: 'v1',
    kind: 'Template',
    metadata: {
      name: 'conprof',
    },
    objects: [
      conprof.configmap {
        metadata+: {
          namespace:: 'hidden',
          annotations+: {
            'qontract.recycle': 'true',
          },
        },
      },
      conprof.statefulset {
        metadata+: { namespace:: 'hidden' },
      },
      conprof.service {
        metadata+: { namespace:: 'hidden' },
      },
    ] + [
      conprof.roles['conprof-observatorium'] {
        metadata+: { namespace:: 'hidden' },
      },
      conprof.roleBindings['conprof-observatorium'] {
        metadata+: { namespace:: 'hidden' },
      },
    ],
    parameters: [
      { name: 'NAMESPACE', value: 'observatorium' },
      { name: 'OBSERVATORIUM_METRICS_NAMESPACE', value: 'observatorium-metrics' },
      { name: 'OBSERVATORIUM_MST_NAMESPACE', value: 'observatorium-mst' },
      { name: 'OBSERVATORIUM_LOGS_NAMESPACE', value: 'observatorium-logs' },
      { name: 'IMAGE', value: 'quay.io/conprof/conprof' },
      { name: 'IMAGE_TAG', value: 'master-2020-04-29-73bf4f0' },
      { name: 'CONPROF_REPLICAS', value: '1' },
      { name: 'CONPROF_CPU_REQUEST', value: '1' },
      { name: 'CONPROF_MEMORY_REQUEST', value: '4Gi' },
      { name: 'CONPROF_CPU_LIMITS', value: '4' },
      { name: 'CONPROF_MEMORY_LIMITS', value: '8Gi' },
      { name: 'OAUTH_PROXY_IMAGE', value: 'quay.io/openshift/origin-oauth-proxy' },
      { name: 'OAUTH_PROXY_IMAGE_TAG', value: '4.7.0' },
      { name: 'CONPROF_PROXY_CPU_REQUEST', value: '100m' },
      { name: 'CONPROF_PROXY_MEMORY_REQUEST', value: '100Mi' },
      { name: 'CONPROF_PROXY_CPU_LIMITS', value: '200m' },
      { name: 'CONPROF_PROXY_MEMORY_LIMITS', value: '200Mi' },
      { name: 'SERVICE_ACCOUNT_NAME', value: 'observatorium' },
    ],
  },
  'conprof-observatorium-logs-rbac-template': {
    apiVersion: 'v1',
    kind: 'Template',
    metadata: {
      name: 'conprof-observatorium-logs-rbac',
    },
    objects: [
      conprof.roles['conprof-observatorium-logs'],
      conprof.roleBindings['conprof-observatorium-logs'],
    ],
    parameters: [
      { name: 'IMAGE_TAG', value: 'master-2020-04-29-73bf4f0' },
      { name: 'NAMESPACE', value: 'observatorium' },
      { name: 'OBSERVATORIUM_LOGS_NAMESPACE', value: 'observatorium-logs' },
      { name: 'SERVICE_ACCOUNT_NAME', value: 'observatorium' },
    ],
  },
  'conprof-observatorium-mst-rbac-template': {
    apiVersion: 'v1',
    kind: 'Template',
    metadata: {
      name: 'conprof-observatorium-mst-rbac',
    },
    objects: [
      conprof.roles['conprof-observatorium-mst'],
      conprof.roleBindings['conprof-observatorium-mst'],
    ],
    parameters: [
      { name: 'IMAGE_TAG', value: 'master-2020-04-29-73bf4f0' },
      { name: 'NAMESPACE', value: 'observatorium' },
      { name: 'OBSERVATORIUM_MST_NAMESPACE', value: 'observatorium-mst' },
      { name: 'SERVICE_ACCOUNT_NAME', value: 'observatorium' },
    ],
  },
}
