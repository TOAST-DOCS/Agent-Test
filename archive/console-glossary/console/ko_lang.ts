// 서비스가 직접 관리하는 콘솔 문자열 (Data-Flow epsilon 의 lang 파일 모양)
export default {
  filter: {
    aggregate: {
      allowed_lateness: {
        alias: '지연 허용 시간',
        description: `지연 허용 시간(초). 윈도우가 닫힌 뒤에도
이 시간 동안 상태를 유지합니다.`,
      },
      watermark: { alias: '워터마크 지연 시간' },
    },
  },
  flow: {
    metric: { open: '메트릭 자세히 ' + '보기', title: `실행 메트릭 ${'x'}` },
  },
}
