function(datasource, namespace) {
  local createGridPos(h, w, x, y) = {
    h: h,
    w: w,
    x: x,
    y: y,
  },
  local titleRow(gridPos, id, title, redPanel) =
    {
      collapsed: false,
      datasource: null,
      gridPos: gridPos,
      id: id,
      panels: [],
      title: title,
      [if redPanel then 'repeat']: 'handler',
      [if redPanel then 'scopedVars']: {
        handler: {
          selected: false,
          text: 'query_legacy',
          value: 'query_legacy',
        },
      },
      type: 'row',
    },
  local availabilityPanel(gridPos, id, query, thresholds, title) =
    {
      cacheTimeout: null,
      colorBackground: false,
      colorValue: true,
      colors: [
        '#d44a3a',
        'rgba(237, 129, 40, 0.89)',
        '#299c46',
      ],
      datasource: '$datasource',
      decimals: 3,
      format: 'percentunit',
      gauge: {
        maxValue: 100,
        minValue: 0,
        show: false,
        thresholdLabels: false,
        thresholdMarkers: true,
      },
      gridPos: gridPos,
      id: id,
      interval: null,
      links: [],
      mappingType: 1,
      mappingTypes: [
        {
          name: 'value to text',
          value: 1,
        },
        {
          name: 'range to text',
          value: 2,
        },
      ],
      maxDataPoints: 100,
      nullPointMode: 'connected',
      nullText: null,
      options: {},
      postfix: '',
      postfixFontSize: '50%',
      prefix: '',
      prefixFontSize: '50%',
      rangeMaps: [
        {
          from: 'null',
          text: 'N/A',
          to: 'null',
        },
      ],
      sparkline: {
        fillColor: 'rgba(31, 118, 189, 0.18)',
        full: false,
        lineColor: 'rgb(31, 120, 193)',
        show: false,
        ymax: null,
        ymin: null,
      },
      tableColumn: '',
      targets: [
        {
          expr: query,
          instant: true,
          refId: 'A',
        },
      ],
      thresholds: thresholds,
      timeFrom: null,
      timeShift: null,
      title: title,
      type: 'singlestat',
      valueFontSize: '120%',
      valueMaps: [
        {
          op: '=',
          text: 'N/A',
          value: 'null',
        },
      ],
      valueName: 'current',
    },
  local targetsQuery(query, legendFormat) = [
    {
      expr: query,
      format: 'time_series',
      intervalFactor: 1,
      legendFormat: legendFormat,
      refId: 'A',
    },
  ],
  local targetsQueryDuration =
    [
      {
        expr: 'histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api",handler=~"query|query_legacy",code!~"5.."}[5m])))',
        format: 'time_series',
        intervalFactor: 1,
        legendFormat: '99th',
        refId: 'A',
      },
      {
        expr: 'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api",handler=~"query|query_legacy",code!~"5.."}[5m])))',
        format: 'time_series',
        intervalFactor: 1,
        legendFormat: '95th',
        refId: 'B',
      },
      {
        expr: 'histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api",handler=~"query|query_legacy",code!~"5.."}[5m])))',
        format: 'time_series',
        intervalFactor: 1,
        legendFormat: '50th',
        refId: 'C',
      },
    ],
  local targetsAllQuery =
    [
      {
        expr: 'sum by (code) (rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler"}[5m]))',
        legendFormat: '{{ code }}',
        refId: 'A',
      },
    ],

  local query = 'sum by (code) (rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query|query_legacy"}[5m]))',
  local legendQuery = '{{code}}',
  local errQuery = 'sum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query|query_legacy",code=~"5.."}[5m]))\n/\nsum(rate(http_requests_total{job="observatorium-observatorium-api",handler=~"query|query_legacy"}[5m]))',
  local errLegendQuery = 'errors',
  local rangeQuery = 'sum by (code) (rate(http_requests_total{job="observatorium-thanos-query",handler="query_range"}[5m]))',
  local rangeQueryErr = 'sum(rate(http_requests_total{job="observatorium-thanos-query",handler="query_range",code=~"5.."}[5m])) / \nsum(rate(http_requests_total{job="observatorium-thanos-query",handler="query_range"}[5m]))',
  local allQuery = 'sum by (code) (rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler"}[5m]))',
  local defaultAliasColors = {
    '2xx': 'semi-dark-green',
    '{code="200"}': 'dark-green',
    '{code="429"}': 'dark-orange',
    '{code="500"}': 'dark-red',
  },

  local redPanel(gridPos, id, seriesOverrides, stack, targets, title, yaxes, fill=10, lineWidth=0, aliasColors=defaultAliasColors, pointRadius=5, paceLength=true, repeatDirection=true, scopedVars=false) =
    {
      aliasColors: aliasColors,
      bars: false,
      dashLength: 10,
      dashes: false,
      datasource: '$datasource',
      fill: fill,
      fillGradient: 0,
      gridPos: gridPos,
      hiddenSeries: false,
      id: id,
      legend: {
        avg: false,
        current: false,
        max: false,
        min: false,
        show: true,
        total: false,
        values: false,
      },
      lines: true,
      linewidth: lineWidth,
      links: [],
      nullPointMode: 'null',
      options: {
        dataLinks: [],
      },
      [if paceLength then 'paceLength']: 10,
      percentage: false,
      pointradius: pointRadius,
      points: false,
      renderer: 'flot',
      [if scopedVars then 'scopedVars']: {
        handler: {
          selected: false,
          text: 'query_legacy',
          value: 'query_legacy',
        },
      },
      [if repeatDirection then 'repeatDirection']: 'v',
      seriesOverrides: seriesOverrides,
      spaceLength: 10,
      stack: stack,
      steppedLine: false,
      targets: targets,
      thresholds: [],
      timeFrom: null,
      timeRegions: [],
      timeShift: null,
      title: title,
      tooltip: {
        shared: true,
        sort: 0,
        value_type: 'individual',
      },
      type: 'graph',
      xaxis: {
        buckets: null,
        mode: 'time',
        name: null,
        show: true,
        values: [],
      },
      yaxes: yaxes,
      yaxis: {
        align: false,
        alignLevel: null,
      },
    },
  local seriesOverridesQuery = [
    {
      alias: '/2../i',
      color: '#56A64B',
    },
    {
      alias: '/3../i',
      color: '#5794F2',
    },
    {
      alias: '/4../i',
      color: '#FF9830',
    },
    {
      alias: '/5../i',
      color: '#C4162A',
    },
  ],
  local yaxesQuery =
    [
      {
        format: 'reqps',
        label: null,
        logBase: 1,
        max: null,
        min: null,
        show: true,
      },
      {
        format: 'short',
        label: null,
        logBase: 1,
        max: null,
        min: null,
        show: false,
      },
    ],
  local seriesOverridesQueryErrs =
    [
      {
        alias: 'errors',
        color: '#C4162A',
      },
    ],
  local yaxesQueryErr =
    [
      {
        decimals: null,
        format: 'percentunit',
        label: null,
        logBase: 1,
        max: null,
        min: '0',
        show: true,
      },
      {
        format: 'short',
        label: null,
        logBase: 1,
        max: null,
        min: null,
        show: true,
      },
    ],
  local seriesOverridesQueryDuration =
    [
      {
        alias: '99th',
        color: '#FA6400',
      },
      {
        alias: '90th',
        color: '#E0B400',
      },
      {
        alias: '50th',
        color: '#37872D',
        fill: 10,
        linewidth: 0,
      },
    ],
  local yaxesQueryDuration =
    [
      {
        format: 's',
        label: null,
        logBase: 10,
        max: null,
        min: null,
        show: true,
      },
      {
        format: 'short',
        label: null,
        logBase: 1,
        max: null,
        min: null,
        show: true,
      },
    ],
  local seriesOverridesQueryRange =
    [
      {
        alias: '1xx',
        color: '#FADE2A',
      },
      {
        alias: '2xx',
        color: '#56A64B',
      },
      {
        alias: '3xx',
        color: '#5794F2',
      },
      {
        alias: '4xx',
        color: '#FF9830',
      },
      {
        alias: '5xx',
        color: '#C4162A',
      },
    ],
  local yaxesQueryRange = [
    {
      format: 'reqps',
      label: null,
      logBase: 1,
      max: null,
      min: null,
      show: true,
    },
    {
      format: 'short',
      label: null,
      logBase: 1,
      max: null,
      min: null,
      show: true,
    },
  ],
  local seriesOverridesQueryRangeDuration =
    [
      {
        alias: '95th',
        color: '#FA6400',
      },
      {
        alias: '90th',
        color: '#E0B400',
      },
      {
        alias: '50th',
        color: '#37872D',
        fill: 10,
        linewidth: 0,
      },
    ],
  local targetsQueryRangeDuration =
    [
      {
        expr: 'histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-thanos-query",code!~"5..",handler="query_range"}[5m])))',
        format: 'time_series',
        intervalFactor: 1,
        legendFormat: '99th',
        refId: 'A',
      },
      {
        expr: 'histogram_quantile(0.9, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-thanos-query",code!~"5..",handler="query_range"}[5m])))',
        format: 'time_series',
        intervalFactor: 1,
        legendFormat: '90th',
        refId: 'B',
      },
      {
        expr: 'histogram_quantile(0.5, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-thanos-query",code!~"5..",handler="query_range"}[5m])))',
        format: 'time_series',
        intervalFactor: 1,
        legendFormat: '50th',
        refId: 'C',
      },
    ],
  local seriesOverridesAllQuery =
    [
      {
        alias: '/2../i',
        color: '#56A64B',
      },
      {
        alias: '/3../i',
        color: '#F2CC0C',
      },
      {
        alias: '/4../i',
        color: '#3274D9',
      },
      {
        alias: '/5../i',
        color: '#E02F44',
      },
    ],

  local panels = [
    titleRow(createGridPos(1, 24, 0, 0), 116, '/query & /query_legacy', false),
    availabilityPanel(
      createGridPos(3, 12, 0, 1),
      114,
      'sum(rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api",handler=~"query|query_legacy",le="1"}[28d]))\n/\nsum(rate(http_request_duration_seconds_count{job="observatorium-observatorium-api",handler=~"query|query_legacy"}[28d]))',
      '0.95,0.96',
      'Availability 1s [28d] > 95%',
    ),
    availabilityPanel(
      createGridPos(3, 12, 12, 1),
      128,
      'sum(rate(http_request_duration_seconds_bucket{job="observatorium-thanos-query",handler="query",le="3",code!~"5.."}[28d]))\n/\nsum(rate(http_request_duration_seconds_count{job="observatorium-thanos-query",handler="query"}[28d]))',
      '0.99,0.992',
      'Availability 3s [28d] > 99%',
    ),
    redPanel(
      createGridPos(8, 8, 0, 4),
      120,
      seriesOverridesQuery,
      true,
      targetsQuery(query, legendQuery),
      'Requests',
      yaxesQuery,
    ),
    redPanel(
      createGridPos(8, 8, 8, 4),
      123,
      seriesOverridesQueryErrs,
      false,
      targetsQuery(errQuery, errLegendQuery),
      'Errors',
      yaxesQueryErr,
    ),
    redPanel(
      createGridPos(8, 8, 16, 4),
      91,
      seriesOverridesQueryDuration,
      false,
      targetsQueryDuration,
      'Duration',
      yaxesQueryDuration,
      0,
      1,
    ),
    titleRow(createGridPos(1, 24, 0, 12), 122, '/query_range', false),
    availabilityPanel(
      createGridPos(3, 12, 0, 13),
      118,
      'sum(rate(http_request_duration_seconds_bucket{handler="query_range",le="60",code!~"5.."}[28d]))\n/\nsum(rate(http_request_duration_seconds_count{handler="query_range"}[28d]))',
      '0.90,0.92',
      'Availability 60s [28d] > 90%',
    ),
    availabilityPanel(
      createGridPos(3, 12, 12, 13),
      119,
      'sum(increase(http_request_duration_seconds_bucket{handler="query_range",le="120",code!~"5.."}[28d]))\n/\nsum(increase(http_request_duration_seconds_count{handler="query_range"}[28d]))',
      '0.99,0.992',
      'Availability 120s [28d] > 99%',
    ),
    redPanel(
      createGridPos(8, 8, 0, 16),
      125,
      seriesOverridesQueryRange,
      true,
      targetsQuery(rangeQuery, legendQuery),
      'Requests',
      yaxesQueryRange,
    ),
    redPanel(
      createGridPos(8, 8, 8, 16),
      126,
      seriesOverridesQueryErrs,
      false,
      targetsQuery(rangeQueryErr, errLegendQuery),
      'Errors',
      yaxesQueryErr,
    ),
    redPanel(
      createGridPos(8, 8, 16, 16),
      127,
      seriesOverridesQueryRangeDuration,
      false,
      targetsQueryRangeDuration,
      'Duration',
      yaxesQueryDuration,
      0,
      1,
    ),
    titleRow(createGridPos(1, 24, 0, 24), 130, 'RED for $handler', true),
    redPanel(
      createGridPos(6, 8, 0, 25),
      132,
      seriesOverridesAllQuery,
      true,
      targetsAllQuery,
      'Requests',
      yaxesQuery,
      aliasColors={},
      pointRadius=2,
      paceLength=false,
      repeatDirection=false,
      scopedVars=true,
    ),
    {
      aliasColors: {},
      bars: false,
      dashLength: 10,
      dashes: false,
      datasource: '$datasource',
      fill: 10,
      fillGradient: 0,
      gridPos: {
        h: 6,
        w: 8,
        x: 8,
        y: 25,
      },
      hiddenSeries: false,
      id: 133,
      legend: {
        avg: false,
        current: false,
        max: false,
        min: false,
        show: true,
        total: false,
        values: false,
      },
      lines: true,
      linewidth: 0,
      nullPointMode: 'null',
      options: {
        dataLinks: [],
      },
      percentage: false,
      pointradius: 2,
      points: false,
      renderer: 'flot',
      scopedVars: {
        handler: {
          selected: false,
          text: 'query_legacy',
          value: 'query_legacy',
        },
      },
      seriesOverrides: [
        {
          alias: 'errors',
          color: '#E02F44',
        },
      ],
      spaceLength: 10,
      stack: true,
      steppedLine: false,
      targets: [
        {
          expr: 'sum(rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code=~"5.."}[5m]))\n/\nsum(rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler"}[5m]))',
          legendFormat: 'errors',
          refId: 'A',
        },
      ],
      thresholds: [],
      timeFrom: null,
      timeRegions: [],
      timeShift: null,
      title: 'Errors',
      tooltip: {
        shared: true,
        sort: 0,
        value_type: 'individual',
      },
      type: 'graph',
      xaxis: {
        buckets: null,
        mode: 'time',
        name: null,
        show: true,
        values: [],
      },
      yaxes: [
        {
          format: 'percentunit',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: true,
        },
        {
          format: 'short',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: false,
        },
      ],
      yaxis: {
        align: false,
        alignLevel: null,
      },
    },
    {
      aliasColors: {},
      bars: false,
      dashLength: 10,
      dashes: false,
      datasource: '$datasource',
      fill: 0,
      fillGradient: 0,
      gridPos: {
        h: 6,
        w: 8,
        x: 16,
        y: 25,
      },
      hiddenSeries: false,
      id: 134,
      legend: {
        avg: false,
        current: false,
        max: false,
        min: false,
        show: true,
        total: false,
        values: false,
      },
      lines: true,
      linewidth: 1,
      nullPointMode: 'null',
      options: {
        dataLinks: [],
      },
      percentage: false,
      pointradius: 2,
      points: false,
      renderer: 'flot',
      scopedVars: {
        handler: {
          selected: false,
          text: 'query_legacy',
          value: 'query_legacy',
        },
      },
      seriesOverrides: [
        {
          alias: 'p99',
          color: '#E02F44',
        },
        {
          alias: 'p90',
          color: '#F2CC0C',
        },
        {
          alias: 'p50',
          color: '#56A64B',
          fill: 10,
          linewidth: 0,
        },
      ],
      spaceLength: 10,
      stack: false,
      steppedLine: false,
      targets: [
        {
          expr: 'histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code!~"5.."}[5m])))',
          legendFormat: 'p50',
          refId: 'C',
        },
        {
          expr: 'histogram_quantile(0.90, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code!~"5.."}[5m])))',
          legendFormat: 'p90',
          refId: 'B',
        },
        {
          expr: 'histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code!~"5.."}[5m])))',
          legendFormat: 'p99',
          refId: 'A',
        },
      ],
      thresholds: [],
      timeFrom: null,
      timeRegions: [],
      timeShift: null,
      title: 'Duration',
      tooltip: {
        shared: true,
        sort: 0,
        value_type: 'individual',
      },
      type: 'graph',
      xaxis: {
        buckets: null,
        mode: 'time',
        name: null,
        show: true,
        values: [],
      },
      yaxes: [
        {
          format: 's',
          label: null,
          logBase: 10,
          max: null,
          min: null,
          show: true,
        },
        {
          format: 'short',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: false,
        },
      ],
      yaxis: {
        align: false,
        alignLevel: null,
      },
    },
    {
      collapsed: false,
      datasource: null,
      gridPos: {
        h: 1,
        w: 24,
        x: 0,
        y: 31,
      },
      id: 135,
      panels: [],
      repeat: null,
      repeatIteration: 1587637883569,
      repeatPanelId: 130,
      scopedVars: {
        handler: {
          selected: false,
          text: 'write',
          value: 'write',
        },
      },
      title: 'RED for $handler',
      type: 'row',
    },
    {
      aliasColors: {},
      bars: false,
      dashLength: 10,
      dashes: false,
      datasource: '$datasource',
      fill: 10,
      fillGradient: 0,
      gridPos: {
        h: 6,
        w: 8,
        x: 0,
        y: 32,
      },
      hiddenSeries: false,
      id: 136,
      legend: {
        avg: false,
        current: false,
        max: false,
        min: false,
        show: true,
        total: false,
        values: false,
      },
      lines: true,
      linewidth: 0,
      nullPointMode: 'null',
      options: {
        dataLinks: [],
      },
      percentage: false,
      pointradius: 2,
      points: false,
      renderer: 'flot',
      repeatIteration: 1587637883569,
      repeatPanelId: 132,
      repeatedByRow: true,
      scopedVars: {
        handler: {
          selected: false,
          text: 'write',
          value: 'write',
        },
      },
      seriesOverrides: [
        {
          alias: '/2../i',
          color: '#56A64B',
        },
        {
          alias: '/3../i',
          color: '#F2CC0C',
        },
        {
          alias: '/4../i',
          color: '#3274D9',
        },
        {
          alias: '/5../i',
          color: '#E02F44',
        },
      ],
      spaceLength: 10,
      stack: true,
      steppedLine: false,
      targets: [
        {
          expr: 'sum by (code) (rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler"}[5m]))',
          legendFormat: '{{ code }}',
          refId: 'A',
        },
      ],
      thresholds: [],
      timeFrom: null,
      timeRegions: [],
      timeShift: null,
      title: 'Requests',
      tooltip: {
        shared: true,
        sort: 0,
        value_type: 'individual',
      },
      type: 'graph',
      xaxis: {
        buckets: null,
        mode: 'time',
        name: null,
        show: true,
        values: [],
      },
      yaxes: [
        {
          format: 'reqps',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: true,
        },
        {
          format: 'short',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: false,
        },
      ],
      yaxis: {
        align: false,
        alignLevel: null,
      },
    },
    {
      aliasColors: {},
      bars: false,
      dashLength: 10,
      dashes: false,
      datasource: '$datasource',
      fill: 10,
      fillGradient: 0,
      gridPos: {
        h: 6,
        w: 8,
        x: 8,
        y: 32,
      },
      hiddenSeries: false,
      id: 137,
      legend: {
        avg: false,
        current: false,
        max: false,
        min: false,
        show: true,
        total: false,
        values: false,
      },
      lines: true,
      linewidth: 0,
      nullPointMode: 'null',
      options: {
        dataLinks: [],
      },
      percentage: false,
      pointradius: 2,
      points: false,
      renderer: 'flot',
      repeatIteration: 1587637883569,
      repeatPanelId: 133,
      repeatedByRow: true,
      scopedVars: {
        handler: {
          selected: false,
          text: 'write',
          value: 'write',
        },
      },
      seriesOverrides: [
        {
          alias: 'errors',
          color: '#E02F44',
        },
      ],
      spaceLength: 10,
      stack: true,
      steppedLine: false,
      targets: [
        {
          expr: 'sum(rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code=~"5.."}[5m]))\n/\nsum(rate(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler"}[5m]))',
          legendFormat: 'errors',
          refId: 'A',
        },
      ],
      thresholds: [],
      timeFrom: null,
      timeRegions: [],
      timeShift: null,
      title: 'Errors',
      tooltip: {
        shared: true,
        sort: 0,
        value_type: 'individual',
      },
      type: 'graph',
      xaxis: {
        buckets: null,
        mode: 'time',
        name: null,
        show: true,
        values: [],
      },
      yaxes: [
        {
          format: 'percentunit',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: true,
        },
        {
          format: 'short',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: false,
        },
      ],
      yaxis: {
        align: false,
        alignLevel: null,
      },
    },
    {
      aliasColors: {},
      bars: false,
      dashLength: 10,
      dashes: false,
      datasource: '$datasource',
      fill: 0,
      fillGradient: 0,
      gridPos: {
        h: 6,
        w: 8,
        x: 16,
        y: 32,
      },
      hiddenSeries: false,
      id: 138,
      legend: {
        avg: false,
        current: false,
        max: false,
        min: false,
        show: true,
        total: false,
        values: false,
      },
      lines: true,
      linewidth: 1,
      nullPointMode: 'null',
      options: {
        dataLinks: [],
      },
      percentage: false,
      pointradius: 2,
      points: false,
      renderer: 'flot',
      repeatIteration: 1587637883569,
      repeatPanelId: 134,
      repeatedByRow: true,
      scopedVars: {
        handler: {
          selected: false,
          text: 'write',
          value: 'write',
        },
      },
      seriesOverrides: [
        {
          alias: 'p99',
          color: '#E02F44',
        },
        {
          alias: 'p90',
          color: '#F2CC0C',
        },
        {
          alias: 'p50',
          color: '#56A64B',
          fill: 10,
          linewidth: 0,
        },
      ],
      spaceLength: 10,
      stack: false,
      steppedLine: false,
      targets: [
        {
          expr: 'histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code!~"5.."}[5m])))',
          legendFormat: 'p50',
          refId: 'C',
        },
        {
          expr: 'histogram_quantile(0.90, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code!~"5.."}[5m])))',
          legendFormat: 'p90',
          refId: 'B',
        },
        {
          expr: 'histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{job="observatorium-observatorium-api", namespace="$namespace", handler=~"$handler",code!~"5.."}[5m])))',
          legendFormat: 'p99',
          refId: 'A',
        },
      ],
      thresholds: [],
      timeFrom: null,
      timeRegions: [],
      timeShift: null,
      title: 'Duration',
      tooltip: {
        shared: true,
        sort: 0,
        value_type: 'individual',
      },
      type: 'graph',
      xaxis: {
        buckets: null,
        mode: 'time',
        name: null,
        show: true,
        values: [],
      },
      yaxes: [
        {
          format: 's',
          label: null,
          logBase: 10,
          max: null,
          min: null,
          show: true,
        },
        {
          format: 'short',
          label: null,
          logBase: 1,
          max: null,
          min: null,
          show: false,
        },
      ],
      yaxis: {
        align: false,
        alignLevel: null,
      },
    },
  ],

  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'grafana-dashboard-observatorium-api',
  },
  data: {
    'observatorium-api.json': std.manifestJsonEx(
      {
        annotations: {
          list: [
            {
              builtIn: 1,
              datasource: '-- Grafana --',
              enable: true,
              hide: true,
              iconColor: 'rgba(0, 211, 255, 1)',
              name: 'Annotations & Alerts',
              type: 'dashboard',
            },
          ],
        },
        description: 'The Observatorium API is the entrypoint for read and write requests',
        editable: true,
        gnetId: null,
        graphTooltip: 1,
        iteration: 1587637883569,
        links: [],
        panels: panels,
        refresh: '1m',
        schemaVersion: 22,
        style: 'dark',
        tags: [
          'observatorium',
        ],
        templating: {
          list: [
            {
              current: {
                selected: true,
                text: datasource,
                value: datasource,
              },
              hide: 0,
              includeAll: false,
              label: null,
              multi: false,
              name: 'datasource',
              options: [],
              query: 'prometheus',
              refresh: 1,
              regex: '',
              skipUrlSync: false,
              type: 'datasource',
            },
            {
              allValue: null,
              current: {
                text: namespace,
                value: namespace,
              },
              datasource: '$datasource',
              definition: 'label_values(kube_pod_info, namespace)',
              hide: 0,
              includeAll: false,
              label: 'namespace',
              multi: false,
              name: 'namespace',
              options: [

              ],
              query: 'label_values(kube_pod_info, namespace)',
              refresh: 1,
              regex: '^telemeter.*|observatorium-.*',
              skipUrlSync: false,
              sort: 2,
              tagValuesQuery: '',
              tags: [

              ],
              tagsQuery: '',
              type: 'query',
              useTags: false,
            },
            {
              allValue: null,
              current: {
                text: 'All',
                value: [
                  '$__all',
                ],
              },
              datasource: '$datasource',
              definition: 'label_values(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace"}, handler)',
              hide: 0,
              includeAll: true,
              label: null,
              multi: true,
              name: 'handler',
              options: [],
              query: 'label_values(http_requests_total{job="observatorium-observatorium-api", namespace="$namespace"}, handler)',
              refresh: 1,
              regex: '(query.*|write)',
              skipUrlSync: false,
              sort: 1,
              tagValuesQuery: '',
              tags: [],
              tagsQuery: '',
              type: 'query',
              useTags: false,
            },
          ],
        },
        time: {
          from: 'now-3h',
          to: 'now',
        },
        timepicker: {
          refresh_intervals: [
            '5s',
            '10s',
            '30s',
            '1m',
            '5m',
            '15m',
            '30m',
            '1h',
            '2h',
            '1d',
          ],
          time_options: [
            '5m',
            '15m',
            '1h',
            '6h',
            '12h',
            '24h',
            '2d',
            '7d',
            '30d',
          ],
        },
        timezone: 'UTC',
        title: 'API',
        uid: 'Tg-mH0rizaSJDKSADX',
        version: 1,
      }, '  ',
    ),
  },
}
