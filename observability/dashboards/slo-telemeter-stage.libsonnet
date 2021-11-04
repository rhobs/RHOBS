function() {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'grafana-dashboard-observatorium-api',
  },
  data: {
      annotations: {
        list: [
          {
            builtIn: 1,
            datasource: '-- Grafana --',
            enable: true,
            hide: true,
            iconColor: 'rgba(0, 211, 255, 1)',
            name: 'Annotations & Alerts',
            target: {
              limit: 100,
              matchAny: false,
              tags: [],
              type: 'dashboard',
            },
            type: 'dashboard',
          },
        ],
      },
      editable: true,
      fiscalYearStartMonth: 0,
      gnetId: null,
      graphTooltip: 1,
      id: 211,
      links: [],
      liveNow: false,
      panels: [
        {
          datasource: null,
          gridPos: {
            h: 3,
            w: 15,
            x: 0,
            y: 0,
          },
          id: 44,
          options: {
            content: 'This dashboard displays the SLOs as defined in the [RHOBS Service Level Objectives](https://docs.google.com/document/d/1wJjcpgg-r8rlnOtRiqWGv0zwr1MB6WwkQED1XDWXVQs/edit) document.',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'Description',
          transparent: true,
          type: 'text',
        },
        {
          collapsed: false,
          datasource: null,
          gridPos: {
            h: 1,
            w: 24,
            x: 0,
            y: 3,
          },
          id: 2,
          panels: [],
          title: 'Telemeter Server > Metrics Write > Availability',
          type: 'row',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 4,
          },
          id: 14,
          options: {
            content: '<center style="font-size: 25px;">\n\n95% of valid requests return successfully\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 95,
                  },
                  {
                    color: 'green',
                    value: 97.5,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 4,
          },
          id: 23,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: '1- sum(rate(haproxy_server_http_responses_total{route=~"telemeter-server-upload|telemeter-server-metrics-v1-receive",code="5xx"}[28d]))\n/\nsum(rate(haproxy_server_http_responses_total{route=~"telemeter-server-upload|telemeter-server-metrics-v1-receive", code!="4xx"}[28d]))\n\n',
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Availability (28d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 4,
          },
          id: 34,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    1 -\n    sum(rate(haproxy_server_http_responses_total{route=~"telemeter-server-upload|telemeter-server-metrics-v1-receive",code="5xx"}[28d]))\n    /\n    sum(rate(haproxy_server_http_responses_total{route=~"telemeter-server-upload|telemeter-server-metrics-v1-receive", code!="4xx"}[28d]))\n  ) - 0.95\n)\n/ \n(1 - 0.95), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          collapsed: false,
          datasource: null,
          gridPos: {
            h: 1,
            w: 24,
            x: 0,
            y: 9,
          },
          id: 4,
          panels: [],
          title: 'Telemeter Server > Metrics Write > Latency',
          type: 'row',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 10,
          },
          id: 15,
          options: {
            content: '<center style="font-size: 25px;">\n\n90% of valid requests return < 5s\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              mappings: [],
              max: 5,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'green',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 50,
                  },
                  {
                    color: 'red',
                    value: 100,
                  },
                ],
              },
              unit: 's',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 10,
          },
          id: 29,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'histogram_quantile(0.9, sum by (le) (rate(http_request_duration_seconds_bucket{job="telemeter-server",code!~"4..",handler=~"upload|receive"}[28d])))',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: '90th Percentile Request Latency (28d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 10,
          },
          id: 35,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    sum(rate(http_request_duration_seconds_bucket{job="telemeter-server",handler=~"upload|receive",le="5"}[28d]))\n/\nsum(rate(http_request_duration_seconds_count{job="telemeter-server",handler=~"upload|receive"}[28d]))\n  ) - 0.9\n)\n/ \n(1 - 0.9), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
            {
              exemplar: true,
              expr: 'histogram_quantile(0.9, sum by (le) (rate(http_request_duration_seconds_bucket{job="telemeter-server",code!~"4..",handler=~"upload|receive"}[28d])))',
              hide: true,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          collapsed: false,
          datasource: null,
          gridPos: {
            h: 1,
            w: 24,
            x: 0,
            y: 15,
          },
          id: 6,
          panels: [],
          title: 'API > Metrics Write > Availability',
          type: 'row',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 16,
          },
          id: 16,
          options: {
            content: '<center style="font-size: 25px;">\n\n95% of valid requests return successfully\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 95,
                  },
                  {
                    color: 'green',
                    value: 97.5,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 16,
          },
          id: 24,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: '1 -\n(\n  sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"receive", code=~"5.+"}[28d])) or vector(0)\n  /\n  sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"receive", code!~"4.+"}[28d]))\n)',
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Availability (28d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 95,
                  },
                  {
                    color: 'green',
                    value: 97.5,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 16,
          },
          id: 36,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n( 1 - \n  (\n     sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"receive", code=~"5.+"}[28d])) or vector(0)\n    /\n    sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"receive", code!~"4.+"}[28d]))\n  ) - 0.95\n)\n/ \n(1 - 0.95), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          collapsed: false,
          datasource: null,
          gridPos: {
            h: 1,
            w: 24,
            x: 0,
            y: 21,
          },
          id: 8,
          panels: [],
          title: 'API > Metrics Write > Latency',
          type: 'row',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 22,
          },
          id: 18,
          options: {
            content: '<center style="font-size: 25px;">\n\n90% of valid requests return < 5s\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              mappings: [],
              max: 5,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'green',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 50,
                  },
                  {
                    color: 'red',
                    value: 100,
                  },
                ],
              },
              unit: 's',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 22,
          },
          id: 30,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'histogram_quantile(0.9, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api",code!~"4..",handler=~"receive"}[28d])))',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: '90th Percentile Request Latency (28d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 22,
          },
          id: 37,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    sum(rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api",code!~"4..",handler=~"receive", le="5"}[28d]))\n/\nsum(rate(http_request_duration_seconds_count{job="observatorium-observatorium-api",code!~"4..",handler=~"receive"}[28d]))\n  ) - 0.9\n)\n/ \n(1 - 0.9), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
            {
              exemplar: true,
              expr: 'http_request_duration_seconds_bucket{job="observatorium-observatorium-api",code!~"4..",handler=~"receive"',
              hide: true,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          collapsed: false,
          datasource: null,
          gridPos: {
            h: 1,
            w: 24,
            x: 0,
            y: 27,
          },
          id: 10,
          panels: [],
          title: 'API > Metrics Read > Availability',
          type: 'row',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 28,
          },
          id: 17,
          options: {
            content: '<center style="font-size: 25px;">\n\n95% of valid /query requests return successfully\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: '#EAB839',
                    value: 95,
                  },
                  {
                    color: 'green',
                    value: 96,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 28,
          },
          id: 26,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: '1 -\n(\n  sum(rate(http_requests_total{job="observatorium-observatorium-api",handler="query", code=~"5.+"}[28d]))\n  /\n  sum(rate(http_requests_total{job="observatorium-observatorium-api",handler="query", code!~"4.+"}[28d]))\n)',
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Availability (28d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 28,
          },
          id: 38,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    1 -\n     sum(rate(http_requests_total{job="observatorium-observatorium-api",handler="query", code=~"5.+"}[28d]))\n    /\n    sum(rate(http_requests_total{job="observatorium-observatorium-api",handler="query", code!~"4.+"}[28d]))\n  ) - 0.95\n)\n/ \n(1 - 0.95), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 33,
          },
          id: 25,
          options: {
            content: '<center style="font-size: 25px;">\n\n95% of valid /query_range requests return successfully\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: '#EAB839',
                    value: 95,
                  },
                  {
                    color: 'green',
                    value: 96,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 33,
          },
          id: 27,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: '1 -\n(\n  sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query_range", code=~"5.+"}[28d]))\n  /\n  sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query_range", code!~"4.+"}[28d]))\n)',
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Availability (28d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 33,
          },
          id: 39,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    1 -\n     sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query_range", code=~"5.+"}[28d]))\n    /\n    sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query_range", code!~"4.+"}[28d]))\n  ) - 0.95\n)\n/ \n(1 - 0.95), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          collapsed: false,
          datasource: null,
          gridPos: {
            h: 1,
            w: 24,
            x: 0,
            y: 38,
          },
          id: 12,
          panels: [],
          title: 'API > Metrics Read > Latency',
          type: 'row',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 39,
          },
          id: 19,
          options: {
            content: '<center style="font-size: 25px;">\n\n90% of valid requests that process 1M samples return < 2s\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'green',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 50,
                  },
                  {
                    color: 'red',
                    value: 100,
                  },
                ],
              },
              unit: 's',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 39,
          },
          id: 31,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'histogram_quantile(0.9, sum by (le) (rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-1M-samples"}[1d])))',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: '90th Percentile Request Latency (1d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 39,
          },
          id: 40,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    sum(rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-1M-samples",le="2.0113571874999994"}[28d]))\n/\nsum(rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-1M-samples"}[28d]))\n  ) - 0.9\n)\n/ \n(1 - 0.9), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 44,
          },
          id: 20,
          options: {
            content: '<center style="font-size: 25px;">\n\n90% of valid requests that process 10M samples return < 10s\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              mappings: [],
              max: 5,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'green',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 50,
                  },
                  {
                    color: 'red',
                    value: 100,
                  },
                ],
              },
              unit: 's',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 44,
          },
          id: 32,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'histogram_quantile(0.9, sum by (le) (rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-10M-samples"}[1d])))',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: '90th Percentile Request Latency (1d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 44,
          },
          id: 41,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    sum(rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-10M-samples",le="10.761264004567169"}[28d]))\n/\nsum(rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-10M-samples"}[28d]))\n  ) - 0.9\n)\n/ \n(1 - 0.9), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
            {
              exemplar: true,
              expr: 'http_request_duration_seconds_bucket{job="observatorium-observatorium-api",code!~"4..",handler=~"receive"',
              hide: true,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
        {
          datasource: null,
          gridPos: {
            h: 5,
            w: 5,
            x: 0,
            y: 49,
          },
          id: 21,
          options: {
            content: '<center style="font-size: 25px;">\n\n90% of valid requests that process 100M samples return < 20s\n\n</center>\n\n',
            mode: 'markdown',
          },
          pluginVersion: '8.2.1',
          title: 'SLO',
          type: 'text',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              mappings: [],
              max: 10,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'green',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 50,
                  },
                  {
                    color: 'red',
                    value: 100,
                  },
                ],
              },
              unit: 's',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 5,
            y: 49,
          },
          id: 33,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'histogram_quantile(0.9, sum by (le) (rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-100M-samples"}[1d])))',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'A',
            },
          ],
          title: '90th Percentile Request Latency (1d)',
          type: 'stat',
        },
        {
          datasource: 'app-sre-stage-01-prometheus',
          fieldConfig: {
            defaults: {
              color: {
                mode: 'thresholds',
              },
              decimals: 2,
              mappings: [],
              max: 1,
              min: 0,
              thresholds: {
                mode: 'percentage',
                steps: [
                  {
                    color: 'red',
                    value: null,
                  },
                  {
                    color: 'orange',
                    value: 33,
                  },
                  {
                    color: 'green',
                    value: 66,
                  },
                ],
              },
              unit: 'percentunit',
            },
            overrides: [],
          },
          gridPos: {
            h: 5,
            w: 5,
            x: 10,
            y: 49,
          },
          id: 42,
          options: {
            colorMode: 'value',
            graphMode: 'area',
            justifyMode: 'auto',
            orientation: 'auto',
            reduceOptions: {
              calcs: [
                'lastNotNull',
              ],
              fields: '',
              values: false,
            },
            text: {},
            textMode: 'auto',
          },
          pluginVersion: '8.2.1',
          targets: [
            {
              exemplar: true,
              expr: 'clamp_min(\n(\n  (\n    sum(rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-100M-samples",le="21.6447457021712"}[28d]))\n/\nsum(rate(up_custom_query_duration_seconds_bucket{namespace="observatorium-stage",query="query-path-sli-100M-samples"}[28d]))\n  ) - 0.9\n)\n/ \n(1 - 0.9), 0)',
              hide: false,
              interval: '',
              legendFormat: '',
              refId: 'B',
            },
          ],
          title: 'Error Budget (28d)',
          type: 'stat',
        },
      ],
      refresh: false,
      schemaVersion: 31,
      style: 'dark',
      tags: [],
      templating: {
        list: [],
      },
      time: {
        from: 'now-6h',
        to: 'now',
      },
      timepicker: {},
      timezone: '',
      title: 'SLOs - Telemeter - Staging',
      uid: 'h-0roLFnz',
      version: 2,
    },
}
