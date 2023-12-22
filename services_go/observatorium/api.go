package observatorium

import (
	"fmt"
	"maps"
	"net"
	"strings"
	"time"

	"github.com/bwplotka/mimic"
	"github.com/bwplotka/mimic/encoding"
	"github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/memcached"
	observatoriumapi "github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/observatorium/api"
	observatoriumup "github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/observatorium/up"
	"github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/prometheus/avalanche"
	"github.com/observatorium/observatorium/configuration_go/abstr/kubernetes/thanos/ruler"
	"github.com/observatorium/observatorium/configuration_go/k8sutil"
	"github.com/observatorium/observatorium/configuration_go/openshift"
	"github.com/observatorium/observatorium/configuration_go/schemas/log"
	"github.com/observatorium/observatorium/configuration_go/schemas/thanos/objstore"
	objstoreS3 "github.com/observatorium/observatorium/configuration_go/schemas/thanos/objstore/s3"
	upoptions "github.com/observatorium/up/pkg/options"
	templatev1 "github.com/openshift/api/template/v1"
	monv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	"github.com/prometheus/common/model"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

const (
	obsApiImage          = "quay.io/observatorium/api"
	obsApiTag            = "main-2023-12-06-62d7703"
	gubernatorImage      = "quay.io/app-sre/gubernator"
	gubernatorTag        = "v2.0.0-rc.36"
	observatoriumUpImage = "quay.io/observatorium/up"
	observatoriumUpTag   = "master-2022-03-24-098c31a"
	avalancheImage       = "quay.io/prometheuscommunity/avalanche"
	avalancheTag         = "main"
	obsctlReloaderImage  = "quay.io/app-sre/obsctl-reloader"
	obsctlReloaderTag    = "9c789b9"
	rulesObjstoreName    = "observatorium-rules-objstore"
)

type ObservatoriumAPI struct {
	Namespace                    string
	Tenants                      []observatoriumapi.Tenant
	ThanosImageTag               string
	APIPremanifestsHook          func(*observatoriumapi.ObservatoriumAPIDeployment)
	CachePremanifestsHook        func(*memcached.MemcachedDeployment)
	GubernatorPremanifestsHook   func(*observatoriumapi.GubernatorDeployment)
	RBAC                         string
	AmsUrl                       string
	AmsClientSecretName          string
	UpQueryFrontendOpts          func(*observatoriumup.UpOptions)
	UpQueryFrontendDeploy        func(*observatoriumup.UpDeployment)
	UpQueriesTenant              string
	AvalancheOpts                func(*avalanche.AvalancheOptions)
	AvalancheDeploy              func(*avalanche.AvalancheDeployment)
	ObsCtlReloaderManagedTenants []string
	RuleObjStoreSecret           string
}

func (o *ObservatoriumAPI) Manifests(generator *mimic.Generator) {
	withStatusRemove := func(encoder encoding.Encoder) encoding.Encoder {
		return &statusRemoveEncoder{encoder: encoder}
	}

	generator.Add("observatorium-api-template.yaml", withStatusRemove(o.makeAPI()))
}

func (o *ObservatoriumAPI) makeAPI() encoding.Encoder {
	// Observatorium api config
	gubernatorName := "observatorium-gubernator"
	tenantsConfig := observatoriumapi.Tenants{Tenants: o.Tenants}
	opts := &observatoriumapi.ObservatoriumAPIOptions{
		InternalTracingEndpoint:          "localhost:6831",
		LogLevel:                         log.LogLevelWarn,
		MiddlewareRateLimiterGrpcAddress: fmt.Sprintf("%s.%s.svc.cluster.local:8081", gubernatorName, o.Namespace),
		MetricsReadEndpoint:              fmt.Sprintf("http://%s.%s.svc.cluster.local:9090", obsQueryFrontendName, o.Namespace),
		MetricsWriteEndpoint:             fmt.Sprintf("http://%s.%s.svc.cluster.local:19291", receiveRouterName, o.Namespace),
		MetricsRulesEndpoint:             fmt.Sprintf("http://%s.%s.svc.cluster.local:8080", rulesObjstoreName, o.Namespace),
		MetricsAlertmanagerEndpoint:      fmt.Sprintf("http://%s.%s.svc.cluster.local:9093", alertManagerName, o.Namespace),
		TenantsConfig:                    observatoriumapi.NewTenantsConfig().WithValue(tenantsConfig),
	}

	if o.RBAC != "" {
		opts.RbacConfig = observatoriumapi.NewRbacConfig().WithValue(o.RBAC)
	}

	// K8s config
	obsapi := observatoriumapi.NewObservatoriumAPI(opts, o.Namespace, obsApiTag)
	obsapi.Image = obsApiImage
	obsapi.Replicas = 1
	delete(obsapi.PodResources.Limits, corev1.ResourceCPU)
	opaAmsCache := "observatorium-api-cache-memcached"
	cacheURL := fmt.Sprintf("%s.%s.svc.cluster.local:11211", opaAmsCache, o.Namespace)
	obsapi.Sidecars = []k8sutil.ContainerProvider{
		makeJaegerAgent("observatorium-tools"),
		o.makeOpaAms(o.AmsUrl, cacheURL, o.AmsClientSecretName),
	}

	// Execute preManifestsHook
	executeIfNotNil(o.APIPremanifestsHook, obsapi)

	// Post process
	manifests := obsapi.Manifests()
	postProcessServiceMonitor(k8sutil.GetObject[*monv1.ServiceMonitor](manifests, ""), obsapi.Namespace)
	addQuayPullSecret(k8sutil.GetObject[*corev1.ServiceAccount](manifests, ""))

	// Add rules objstore
	maps.Copy(manifests, o.makeRulesObjstore())

	// Add cache
	cachePreManHook := func(memdep *memcached.MemcachedDeployment) {
		memdep.CommonLabels[k8sutil.ComponentLabel] = "api-cache"
		executeIfNotNil(o.CachePremanifestsHook, memdep)
	}
	maps.Copy(manifests, makeMemcached(opaAmsCache, o.Namespace, cachePreManHook))

	// Add gubernator
	maps.Copy(manifests, o.makeGubernator(gubernatorName))

	// Add obsctl reloader
	maps.Copy(manifests, o.makeObsCtlReloader(obsapi.Name))

	// Add up query frontend
	endpoint := fmt.Sprintf("http://observatorium-thanos-query-frontend.%s.svc.cluster.local:9090", o.Namespace)
	maps.Copy(manifests, o.makeUp("observatorium-up-query-frontend", endpoint))

	// Add up ruler
	endpoint = fmt.Sprintf("http://observatorium-thanos-query-rule.%s.svc.cluster.local:9090", o.Namespace)
	maps.Copy(manifests, o.makeUp("observatorium-up-query-rule", endpoint))

	// Add avalanche
	maps.Copy(manifests, o.makeAvalanche())

	// Set encoders and template params
	params := []templatev1.Parameter{}
	cacheEncoder := NewStdTemplateYAML(opaAmsCache, "CACHE")
	params = append(params, cacheEncoder.TemplateParams()...)
	apiEncoder := NewStdTemplateYAML(obsapi.Name, "OBSAPI").WithLogLevel()
	params = append(params, apiEncoder.TemplateParams()...)
	template := openshift.WrapInTemplate("", manifests, metav1.ObjectMeta{
		Name: obsapi.Name,
	}, sortTemplateParams(params))

	return cacheEncoder.Wrap(apiEncoder.Wrap(encoding.GhodssYAML(template[""])))
}

func (o *ObservatoriumAPI) makeRulesObjstore() k8sutil.ObjectMap {
	rulesObjstore := ruler.NewRulesObjstore()
	rulesObjstore.ImageTag = "main-2022-09-21-9df4d2c"
	rulesObjstore.Namespace = o.Namespace
	rulesObjstore.Name = rulesObjstoreName
	rulesObjstore.Env = append(rulesObjstore.Env, objStoreEnvVars(o.RuleObjStoreSecret)...)
	rulesObjstore.Env = deleteObjStoreEnv(rulesObjstore.Env)
	rulesObjstore.Options.ObjstoreConfigFile = ruler.NewObjstoreConfigFile("observatorium-rules-objstore", objstore.BucketConfig{
		Type: objstore.S3,
		Config: objstoreS3.Config{
			Bucket:   "$(OBJ_STORE_BUCKET)",
			Endpoint: "$(OBJ_STORE_ENDPOINT)",
			Region:   "$(OBJ_STORE_REGION)",
		},
	})
	rulesObjstore.Options.LogLevel = string(log.LogLevelWarn)
	rulesObjstore.Options.LogFormat = string(log.LogFormatLogfmt)
	return rulesObjstore.Manifests()
}

func (o *ObservatoriumAPI) makeOpaAms(amsURL, memcachedUrl, clientSecretName string) *k8sutil.Container {
	opts := &observatoriumapi.OpaAmsOptions{
		WebListen:               &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1), Port: 8082},
		WebInternalListen:       &net.TCPAddr{IP: net.IPv4(0, 0, 0, 0), Port: 8083},
		WebHealthchecksURL:      "http://localhost:8082",
		LogLevel:                "warn",
		AmsURL:                  amsURL,
		ResourceTypePrefix:      "observatorium",
		OidcClientID:            "$(CLIENT_ID)",
		OidcClientSecret:        "$(CLIENT_SECRET)",
		OidcIssuerURL:           "$(ISSUER_URL)",
		OpaPackage:              "observatorium",
		Memcached:               memcachedUrl,
		MemcachedExpire:         300,
		InternalTracingEndpoint: &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1), Port: 6831},
	}

	ret := observatoriumapi.MakeOpaAms(opts, true)
	ret.ImageTag = "master-2022-11-03-222daab"
	ret.Env = append(ret.Env, k8sutil.NewEnvFromSecret("CLIENT_ID", clientSecretName, "client-id"))
	ret.Env = append(ret.Env, k8sutil.NewEnvFromSecret("CLIENT_SECRET", clientSecretName, "client-secret"))
	ret.Env = append(ret.Env, k8sutil.NewEnvFromSecret("ISSUER_URL", clientSecretName, "issuer-url"))

	return ret
}

func (o *ObservatoriumAPI) makeGubernator(name string) k8sutil.ObjectMap {
	gube := observatoriumapi.NewGubernatorDeployment(o.Namespace, gubernatorTag)
	gube.Image = gubernatorImage
	gube.Replicas = 1
	gube.Name = name
	executeIfNotNil(o.GubernatorPremanifestsHook, gube)

	// Post process
	manifests := gube.Manifests()
	postProcessServiceMonitor(k8sutil.GetObject[*monv1.ServiceMonitor](manifests, ""), gube.Namespace)
	addQuayPullSecret(k8sutil.GetObject[*corev1.ServiceAccount](manifests, ""))

	return manifests
}

func (o *ObservatoriumAPI) makeUp(name, endpoint string) k8sutil.ObjectMap {
	opts := &observatoriumup.UpOptions{}
	opts.LogLevel = log.LogLevelInfo
	opts.EndpointType = observatoriumup.EndpointTypeMetrics
	opts.EndpointRead = fmt.Sprintf("http://observatorium-thanos-query-frontend.%s.svc.cluster.local:9090", o.Namespace)
	zeroDur := model.Duration(0)
	opts.Duration = &zeroDur
	opts.QueriesFile = observatoriumup.NewQueriesFileOption().WithValue(observatoriumup.QueriesFile{
		Queries: []upoptions.QuerySpec{
			{
				Name:  "query-path-sli-1M-samples",
				Query: fmt.Sprintf("avg_over_time(avalanche_metric_mmmmm_0_0{tenant_id=\"%s\"}[1h])", o.UpQueriesTenant),
			},
			{
				Name:  "query-path-sli-10M-samples",
				Query: fmt.Sprintf("avg_over_time(avalanche_metric_mmmmm_0_0{tenant_id=\"%s\"}[10h])", o.UpQueriesTenant),
			},
			{
				Name:  "query-path-sli-100M-samples",
				Query: fmt.Sprintf("avg_over_time(avalanche_metric_mmmmm_0_0{tenant_id=\"%s\"}[100h])", o.UpQueriesTenant),
			},
		},
	})
	executeIfNotNil(o.UpQueryFrontendOpts, opts)

	obsup := observatoriumup.NewUp(opts, o.Namespace, observatoriumUpTag)
	obsup.Image = observatoriumUpImage
	obsup.Name = name
	executeIfNotNil(o.UpQueryFrontendDeploy, obsup)

	// Post process
	manifests := obsup.Manifests()
	postProcessServiceMonitor(k8sutil.GetObject[*monv1.ServiceMonitor](manifests, ""), obsup.Namespace)
	addQuayPullSecret(k8sutil.GetObject[*corev1.ServiceAccount](manifests, obsup.Name))

	return manifests
}

func (o *ObservatoriumAPI) makeAvalanche() k8sutil.ObjectMap {
	opts := &avalanche.AvalancheOptions{}
	opts.MetricCount = 1
	opts.SeriesCount = 8333
	opts.RemoteURL = fmt.Sprintf("http://observatorium-thanos-receive-router.%s.svc.cluster.local:19291/api/v1/receive", o.Namespace)
	opts.RemoteWriteInterval = time.Duration(30) * time.Second
	opts.RemoteRequestsCount = 10e6
	opts.ValueInterval = 3600
	opts.SeriesInterval = 315360000 // 10y
	opts.MetricInterval = 315360000 // 10y
	opts.RemoteTenantHeader = "THANOS-TENANT"
	opts.RemoteTenant = o.UpQueriesTenant
	executeIfNotNil(o.AvalancheOpts, opts)

	aval := avalanche.NewAvalanche(opts, o.Namespace, avalancheTag)
	aval.Image = avalancheImage
	executeIfNotNil(o.AvalancheDeploy, aval)

	// Post process
	manifests := aval.Manifests()
	postProcessServiceMonitor(k8sutil.GetObject[*monv1.ServiceMonitor](manifests, ""), aval.Namespace)
	addQuayPullSecret(k8sutil.GetObject[*corev1.ServiceAccount](manifests, aval.Name))

	return manifests
}

func (o *ObservatoriumAPI) makeObsCtlReloader(obsApiName string) k8sutil.ObjectMap {
	depl := k8sutil.DeploymentGenericConfig{
		Name:                 "observatorium-obsctl-reloader",
		Namespace:            o.Namespace,
		Image:                obsctlReloaderImage,
		ImageTag:             obsctlReloaderTag,
		ImagePullPolicy:      corev1.PullIfNotPresent,
		Replicas:             1,
		EnableServiceMonitor: true,
		CommonLabels: map[string]string{
			k8sutil.NameLabel:      "rules-obsctl-reloader",
			k8sutil.InstanceLabel:  "observatorium",
			k8sutil.PartOfLabel:    "observatorium",
			k8sutil.ComponentLabel: "rules-obsctl-reloader",
			k8sutil.VersionLabel:   obsctlReloaderTag,
		},
		PodResources:                  k8sutil.NewResourcesRequirements("50m", "", "500Mi", "2Gi"),
		TerminationGracePeriodSeconds: 30,
	}

	container := depl.ToContainer()
	container.Name = "obsctl-reloader"
	internalPort := 8081
	container.Args = []string{
		"--log.level=debug",
		fmt.Sprintf("--web.internal.listen=0.0.0.0:%d", internalPort),
		"--sleep-duration-seconds=16",
		fmt.Sprintf("--observatorium-api-url=http://%s.%s.svc.cluster.local:8080", obsApiName, o.Namespace),
		"--managed-tenants=" + strings.Join(o.ObsCtlReloaderManagedTenants, ","),
		"--issuer-url=https://sso.redhat.com/auth/realms/redhat-external",
		"--audience=observatorium",
		"--log-rules-enabled=false",
	}
	container.Ports = []corev1.ContainerPort{
		{
			Name:          "http",
			ContainerPort: int32(internalPort),
			Protocol:      corev1.ProtocolTCP,
		},
	}
	container.ServicePorts = []corev1.ServicePort{k8sutil.NewServicePort("http", internalPort, internalPort)}
	container.MonitorPorts = []monv1.Endpoint{{Port: "http"}}

	manifests := k8sutil.ObjectMap{}
	manifests.AddAll(depl.GenerateObjects(container))

	postProcessServiceMonitor(k8sutil.GetObject[*monv1.ServiceMonitor](manifests, ""), depl.Namespace)
	addQuayPullSecret(k8sutil.GetObject[*corev1.ServiceAccount](manifests, depl.Name))

	rbacRules := []rbacv1.PolicyRule{
		{
			APIGroups: []string{"monitoring.coreos.com"},
			Resources: []string{"prometheusrules"},
			Verbs:     []string{"list", "watch", "get"},
		},
		{
			APIGroups: []string{"loki.grafana.com"},
			Resources: []string{"alertingrules", "recordingrules"},
			Verbs:     []string{"list", "watch", "get"},
		},
		{
			APIGroups: []string{""},
			Resources: []string{"secrets"},
			Verbs:     []string{"list", "watch", "get"},
		},
	}
	rbacRole := depl.RBACRole(rbacRules)
	manifests.Add(rbacRole)
	sa := k8sutil.GetObject[*corev1.ServiceAccount](manifests, depl.Name)
	manifests.Add(depl.RBACRoleBinding([]runtime.Object{sa}, rbacRole))

	return manifests
}
