export default {
  filter: {
    aggregate: {
      allowed_lateness: {
        alias: 'Allowed lateness',
        description: `Allowed lateness (in seconds).`,
      },
      watermark: { alias: 'Watermark delay' },
    },
  },
  flow: {
    metric: { open: 'View metrics in detail', title: `Run metrics` },
  },
}
