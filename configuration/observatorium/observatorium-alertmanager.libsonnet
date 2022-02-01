{
  "global": {
    "resolve_timeout": "5m"
  },
  "inhibit_rules": [
    {
      "equal": [
        "namespace",
        "alertname"
      ],
      "source_matchers": [
        "severity = critical"
      ],
      "target_matchers": [
        "severity =~ warning|info"
      ]
    },
    {
      "equal": [
        "namespace",
        "alertname"
      ],
      "source_matchers": [
        "severity = warning"
      ],
      "target_matchers": [
        "severity = info"
      ]
    }
  ],
  "receivers": [
    {
      "name": "Default"
    },
    {
      "name": "Watchdog"
    },
    {
      "name": "Critical"
    }
  ],
  "route": {
    "group_by": [
      "namespace"
    ],
    "group_interval": "5m",
    "group_wait": "30s",
    "receiver": "Default",
    "repeat_interval": "12h",
    "routes": [
      {
        "matchers": [
          "alertname = Watchdog"
        ],
        "receiver": "Watchdog"
      },
      {
        "matchers": [
          "severity = critical"
        ],
        "receiver": "Critical"
      }
    ]
  }
}