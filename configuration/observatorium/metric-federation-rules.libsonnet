{
  prometheus+:: {
    recordingrules+: {
      groups+: [
        {
          name: 'kafka.rules',
          interval: '1m',
          rules: [
            {
              record: 'kafka_id:strimzi_resource_state:group',
              expr: |||
                kafka_id:strimzi_resource_state:group
              |||,
            },
            {
              record: 'kafka_id:haproxy_server_bytes_in_total:rate1h_gibibytes',
              expr: |||
                kafka_id:haproxy_server_bytes_in_total:rate1h_gibibytes
              |||,
            },
            {
              record: 'kafka_id:haproxy_server_bytes_out_total:rate1h_gibibytes',
              expr: |||
                kafka_id:haproxy_server_bytes_out_total:rate1h_gibibytes
              |||,
            },
            {
              record: 'kafka_id:kafka_broker_quota_totalstorageusedbytes:max_over_time1h_gibibytes',
              expr: |||
                kafka_id:kafka_broker_quota_totalstorageusedbytes:max_over_time1h_gibibytes
              |||,
            },
            {
              record: 'kafka_id:haproxy_server_bytes_in_out_total:rate1h_gibibytes',
              expr: |||
                kafka_id:haproxy_server_bytes_in_out_total:rate1h_gibibytes
              |||,
            },
          ],
        },
      ],
    },
  },
}
