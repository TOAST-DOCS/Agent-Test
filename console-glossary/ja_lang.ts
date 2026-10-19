export default {
  filter: {
    aggregate: {
      allowed_lateness: {
        "alias": "遅延許可時間",
        "description": "遅延許可時間(秒)。",
      },
      watermark: { alias: 'ウォーターマーク遅延時間' },
    },
  },
  flow: {
    metric: { open: 'メトリクス詳細表示', title: '実行メトリクス' },
  },
}
