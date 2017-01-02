{
  port: 8125,
  address: "::",

  mgmt_port: 8126,
  mgmt_address: "::",

  percentThreshold: [ 50, 75, 90, 95, 98, 99, 99.9, 99.99, 99.999],

  graphitePort: 2003,
  graphiteHost: "localhost",
  flushInterval: 10000,

  backends: ['./backends/graphite'],
  graphite: {
    legacyNamespace: false
  }
}
