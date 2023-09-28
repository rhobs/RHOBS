package observatorium

import (
	_ "embed"
	"fmt"
	"maps"
	"time"

	"github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/thanos/compactor"
	"github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/thanos/store"
	"github.com/observatorium/observatorium/configuration_go/k8sutil"
	"github.com/observatorium/observatorium/configuration_go/schemas/thanos/common"
	trclient "github.com/observatorium/observatorium/configuration_go/schemas/thanos/tracing/client"
	"github.com/observatorium/observatorium/configuration_go/schemas/thanos/tracing/jaeger"
	monv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

const (
	thanosImage                     = "quay.io/thanos/thanos"
	thanosImageTag                  = "v0.32.3"
	monitoringNamespace             = "openshift-customer-monitoring"
	servingCertSecretNameAnnotation = "service.alpha.openshift.io/serving-cert-secret-name"
)

//go:embed assets/store-auto-shard-relabel-configMap.sh
var storeAutoShardRelabelConfigMap string

// makeCompactor creates a base compactor component that can be derived from using the preManifestsHook.
func makeCompactor(namespace string, preManifestsHook func(*compactor.CompactorStatefulSet)) k8sutil.ObjectMap {
	// K8s config
	compactorSatefulset := compactor.NewCompactor()
	compactorSatefulset.Image = thanosImage
	compactorSatefulset.ImageTag = thanosImageTag
	compactorSatefulset.Namespace = namespace
	compactorSatefulset.Affinity.PodAntiAffinity.PreferredDuringSchedulingIgnoredDuringExecution[0].PodAffinityTerm.Namespaces = []string{}
	compactorSatefulset.Replicas = 1
	delete(compactorSatefulset.PodResources.Limits, corev1.ResourceCPU) // To be confirmed
	compactorSatefulset.PodResources.Requests[corev1.ResourceCPU] = resource.MustParse("200m")
	compactorSatefulset.PodResources.Requests[corev1.ResourceMemory] = resource.MustParse("1Gi")
	compactorSatefulset.PodResources.Limits[corev1.ResourceMemory] = resource.MustParse("5Gi")
	compactorSatefulset.VolumeType = "gp2"
	compactorSatefulset.VolumeSize = "500Gi"
	compactorSatefulset.Env = []corev1.EnvVar{
		k8sutil.NewEnvFromSecret("AWS_ACCESS_KEY_ID", "rhobs-thanos-s3", "aws_access_key_id"),
		k8sutil.NewEnvFromSecret("AWS_SECRET_ACCESS_KEY", "rhobs-thanos-s3", "aws_secret_access_key"),
		k8sutil.NewEnvFromSecret("OBJSTORE_CONFIG", "rhobs-thanos-objectstorage", "thanos.yaml"),
	}
	tlsSecret := "compact-tls"
	compactorSatefulset.Sidecars = []k8sutil.ContainerProvider{makeOauthProxy(10902, namespace, compactorSatefulset.Name, tlsSecret)}

	// Compactor config
	compactorSatefulset.Options.LogLevel = "warn"
	compactorSatefulset.Options.RetentionResolutionRaw = 365 * 24 * time.Hour
	compactorSatefulset.Options.RetentionResolution5m = 365 * 24 * time.Hour
	compactorSatefulset.Options.RetentionResolution1h = 365 * 24 * time.Hour
	compactorSatefulset.Options.DeleteDelay = 24 * time.Hour
	compactorSatefulset.Options.CompactConcurrency = 1
	compactorSatefulset.Options.DownsampleConcurrency = 1
	compactorSatefulset.Options.DeduplicationReplicaLabel = "replica"
	compactorSatefulset.Options.AddExtraOpts("--debug.max-compaction-level=3")

	// Post process
	if preManifestsHook != nil {
		preManifestsHook(compactorSatefulset)
	}
	manifests := compactorSatefulset.Manifests()
	service := getObject[*corev1.Service](manifests)
	service.ObjectMeta.Annotations[servingCertSecretNameAnnotation] = tlsSecret
	postProcessServiceMonitor(getObject[*monv1.ServiceMonitor](manifests))

	return manifests

}

// makeStore creates a base store component that can be derived from using the preManifestsHook.
func makeStore(namespace string, preManifestHook func(*store.StoreStatefulSet)) k8sutil.ObjectMap {
	// K8s config
	storeStatefulSet := store.NewStore()
	storeStatefulSet.Image = thanosImage
	storeStatefulSet.ImageTag = thanosImageTag
	storeStatefulSet.Namespace = namespace
	storeStatefulSet.Affinity.PodAntiAffinity.PreferredDuringSchedulingIgnoredDuringExecution[0].PodAffinityTerm.Namespaces = []string{}
	storeStatefulSet.Replicas = 1
	delete(storeStatefulSet.PodResources.Limits, corev1.ResourceCPU) // To be confirmed
	storeStatefulSet.PodResources.Requests[corev1.ResourceCPU] = resource.MustParse("4")
	storeStatefulSet.PodResources.Requests[corev1.ResourceMemory] = resource.MustParse("20Gi")
	storeStatefulSet.PodResources.Limits[corev1.ResourceMemory] = resource.MustParse("80Gi")
	storeStatefulSet.VolumeType = "gp2"
	storeStatefulSet.VolumeSize = "500Gi"
	storeStatefulSet.Env = []corev1.EnvVar{
		k8sutil.NewEnvFromSecret("AWS_ACCESS_KEY_ID", "rhobs-thanos-s3", "aws_access_key_id"),
		k8sutil.NewEnvFromSecret("AWS_SECRET_ACCESS_KEY", "rhobs-thanos-s3", "aws_secret_access_key"),
		k8sutil.NewEnvFromSecret("OBJSTORE_CONFIG", "rhobs-thanos-objectstorage", "thanos.yaml"),
	}
	storeStatefulSet.Sidecars = []k8sutil.ContainerProvider{makeJaegerAgent("observatorium-tools")}

	// Store auto-sharding using a configMap and an initContainer
	// The configMap contains a script that will be executed by the initContainer
	// The script generates the relabeling config based on the replica ordinal and the number of replicas
	// The relabeling config is then written to a volume shared with the store container
	storeStatefulSet.ConfigMaps["hashmod-config-template"] = map[string]string{
		"entrypoint.sh": storeAutoShardRelabelConfigMap,
	}
	initContainer := corev1.Container{
		Name:            "init-hashmod-file",
		Image:           "quay.io/app-sre/ubi8-ubi",
		ImagePullPolicy: corev1.PullIfNotPresent,
		Args: []string{
			"/tmp/entrypoint/entrypoint.sh",
		},
		Env: []corev1.EnvVar{
			{
				Name: "NAMESPACE",
				ValueFrom: &corev1.EnvVarSource{
					FieldRef: &corev1.ObjectFieldSelector{
						FieldPath: "metadata.namespace",
					},
				},
			},
		},
		VolumeMounts: []corev1.VolumeMount{
			{
				Name:      "hashmod-config-template",
				MountPath: "/tmp/entrypoint",
			},
			{
				Name:      "hashmod-config",
				MountPath: "/etc/config",
			},
		},
	}

	// Store config
	storeStatefulSet.Options.LogLevel = common.LogLevelWarn
	storeStatefulSet.Options.LogFormat = common.LogFormatLogfmt
	storeStatefulSet.Options.IgnoreDeletionMarksDelay = 24 * time.Hour
	maxTimeDur := time.Duration(-22) * time.Hour
	storeStatefulSet.Options.MaxTime = &common.TimeOrDurationValue{Dur: &maxTimeDur}
	storeStatefulSet.Options.SelectorRelabelConfigFile = "/tmp/config/hashmod-config.yaml"
	storeStatefulSet.Options.TracingConfig = &trclient.TracingConfig{
		Type: trclient.Jaeger,
		Config: jaeger.Config{
			SamplerParam: 2,
			SamplerType:  jaeger.SamplerTypeRateLimiting,
			ServiceName:  "thanos-store",
		},
	}
	storeStatefulSet.Options.StoreEnableIndexHeaderLazyReader = true // Enables parallel rolling update of store nodes.

	// Post process
	if preManifestHook != nil {
		preManifestHook(storeStatefulSet)
	}
	manifests := storeStatefulSet.Manifests()
	postProcessServiceMonitor(getObject[*monv1.ServiceMonitor](manifests))
	statefulset := getObject[*appsv1.StatefulSet](manifests)
	defaultMode := int32(0777)
	statefulset.Spec.Template.Spec.Volumes = append(statefulset.Spec.Template.Spec.Volumes, corev1.Volume{
		Name: "hashmod-config",
		VolumeSource: corev1.VolumeSource{
			EmptyDir: &corev1.EmptyDirVolumeSource{},
		},
	}, corev1.Volume{
		Name: "hashmod-config-template",
		VolumeSource: corev1.VolumeSource{
			ConfigMap: &corev1.ConfigMapVolumeSource{
				LocalObjectReference: corev1.LocalObjectReference{
					Name: storeStatefulSet.CommonLabels[k8sutil.NameLabel],
				},
				DefaultMode: &defaultMode,
			},
		},
	})
	statefulset.Spec.Template.Spec.InitContainers = append(statefulset.Spec.Template.Spec.InitContainers, initContainer)
	mainContainer := &statefulset.Spec.Template.Spec.Containers[0]
	mainContainer.VolumeMounts = append(mainContainer.VolumeMounts, corev1.VolumeMount{
		Name:      "hashmod-config",
		MountPath: "/etc/config",
	})

	// add rbac for reading the number of replicas from the statefulset in the initContainer
	labels := maps.Clone(statefulset.ObjectMeta.Labels)
	delete(labels, k8sutil.VersionLabel)
	manifests["list-pods-rbac"] = &rbacv1.Role{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "list-pods",
			Namespace: namespace,
			Labels:    labels,
		},
		Rules: []rbacv1.PolicyRule{
			{
				APIGroups: []string{"apps"},
				Resources: []string{"statefulsets"},
				Verbs:     []string{"get", "list"},
			},
		},
	}
	manifests["list-pods-rbac-binding"] = &rbacv1.RoleBinding{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "list-pods",
			Namespace: namespace,
			Labels:    labels,
		},
		Subjects: []rbacv1.Subject{
			{

				Kind:      "ServiceAccount",
				Name:      statefulset.Spec.Template.Spec.ServiceAccountName,
				Namespace: namespace,
			},
		},
		RoleRef: rbacv1.RoleRef{
			Kind:     "Role",
			Name:     "list-pods",
			APIGroup: "rbac.authorization.k8s.io",
		},
	}

	// Add pod disruption budget
	manifests["store-pdb"] = &policyv1.PodDisruptionBudget{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "store",
			Namespace: namespace,
			Labels:    labels,
		},
		Spec: policyv1.PodDisruptionBudgetSpec{
			MaxUnavailable: &intstr.IntOrString{

				Type:   intstr.Int,
				IntVal: 1,
			},
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
		},
	}

	return manifests
}

type kubeObject interface {
	*corev1.Service | *appsv1.StatefulSet | *monv1.ServiceMonitor | *corev1.ServiceAccount
}

func getObject[T kubeObject](manifests k8sutil.ObjectMap) T {
	for _, obj := range manifests {
		if service, ok := obj.(T); ok {
			return service
		}
	}

	panic(fmt.Sprintf("could not find object of type %T", *new(T)))
}

func postProcessServiceMonitor(serviceMonitor *monv1.ServiceMonitor) {
	serviceMonitor.ObjectMeta.Namespace = monitoringNamespace
	// Same labels map is shared between all objects in the manifests. Need to clone it to avoid modifying all.
	labels := maps.Clone(serviceMonitor.ObjectMeta.Labels)
	labels["prometheus"] = "app-sre"
	serviceMonitor.ObjectMeta.Labels = labels
}
