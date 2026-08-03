---
public:
    api:
      endpoint: https://api-instance.nhncloudservice.com
      regions:
        - { name: "한국(판교) 리전", url: "https://kr1-api-instance-infrastructure.nhncloudservice.com" }
        - { name: "한국(평촌) 리전", url: "https://kr2-api-instance-infrastructure.nhncloudservice.com" }
        - { name: "한국(광주) 리전", url: "https://kr3-api-instance-infrastructure.nhncloudservice.com" }
        - { name: "일본 리전",       url: "https://jp1-api-instance-infrastructure.nhncloudservice.com" }
gov:
    api:
      endpoint: https://api-instance.gov-nhncloudservice.com
      regions:
        - { name: "한국(판교) 리전", url: "https://kr1-api-instance-infrastructure.gov-nhncloudservice.com" }
        - { name: "한국(평촌) 리전", url: "https://kr2-api-instance-infrastructure.gov-nhncloudservice.com" }
---
{% if 'gov' in build_flags %}{% set env = gov %}{% else %}{% set env = public %}{% endif %}

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
| compute | {% for r in env.api.regions %}$[ r.name ]$<br>{% endfor %} | {% for r in env.api.regions %}$[ r.url ]$<br>{% endfor %} |
