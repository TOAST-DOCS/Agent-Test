---
public:
    api:
      regions:
        - { name: "한국(판교) 리전", url: "https://kr1-api-instance-infrastructure.nhncloudservice.com" }
        - { name: "한국(평촌) 리전", url: "https://kr2-api-instance-infrastructure.nhncloudservice.com" }
        - { name: "한국(광주) 리전", url: "https://kr3-api-instance-infrastructure.nhncloudservice.com" }
        - { name: "일본 리전",       url: "https://jp1-api-instance-infrastructure.nhncloudservice.com" }
gov:
    api:
      regions:
        - { name: "한국(판교) 리전", url: "https://kr1-api-instance-infrastructure.gov-nhncloudservice.com" }
        - { name: "한국(평촌) 리전", url: "https://kr2-api-instance-infrastructure.gov-nhncloudservice.com" }
---
{% if 'gov' in build_flags %}{% set env = gov %}{% else %}{% set env = public %}{% endif %}

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
| compute | {% for r in env.api.regions %}$[ r.name ]$<br>{% endfor %} | {% for r in env.api.regions %}$[ r.url ]$<br>{% endfor %} |

## HTML 상대경로 테스트
* 기본 인프라 서비스(Infrastructure)의 역할별 상세 권한은 [전체 권한 매트릭스 보기](../static/etc/infrastructure_roles_guide_202608_v1.html){:target="_blank" rel="noopener"}을 참조하세요.

## Tab 기능 테스트
=== "Java"
    ```java
    // AuthService.java
    package com.nhn.cloud.auth;
    
    // .. import list
    
    @Data
    public class AuthService {
    
        // Inner class for the request body
        @Data
        public class TokenRequest {
    
            private Auth auth = new Auth();
    
            @Data
            public class Auth {
                private String tenantId;
                private PasswordCredentials passwordCredentials = new PasswordCredentials();
            }
    
            @Data
            public class PasswordCredentials {
                private String username;
                private String password;
            }
        }
    
        private String authUrl;
        private TokenRequest tokenRequest;
        private RestTemplate restTemplate;
    
        public AuthService(String authUrl, String tenantId, String username, String password) {
            this.authUrl = authUrl;
    
            // 요청 본문 생성
            this.tokenRequest = new TokenRequest();
            this.tokenRequest.getAuth().setTenantId(tenantId);
            this.tokenRequest.getAuth().getPasswordCredentials().setUsername(username);
            this.tokenRequest.getAuth().getPasswordCredentials().setPassword(password);
    
            this.restTemplate = new RestTemplate();
        }
    
        public String requestToken() {
            String identityUrl = this.authUrl + "/tokens";
    
            // 헤더 생성
            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Type", "application/json");
    
            HttpEntity<TokenRequest> httpEntity
                = new HttpEntity<TokenRequest>(this.tokenRequest, headers);
    
            // 토큰 요청
            ResponseEntity<String> response
                = this.restTemplate.exchange(identityUrl, HttpMethod.POST, httpEntity, String.class);
    
            return response.getBody();
        }
    
        public static void main(String[] args) {
            final String authUrl = "https://api-identity-infrastructure.nhncloudservice.com/v2.0";
            final String tenantId = "{Tenant ID}";
            final String username = "{NHN Cloud Account}";
            final String password = "{API Password}";
    
            AuthService authService = new AuthService(authUrl, tenantId, username, password);
            String token = authService.requestToken();
    
            System.out.println(token);
        }
    }
    ```

=== "Python"
    ```python
    # auth.py
    import json
    import requests
    
    
    def get_token(auth_url, tenant_id, username, password):
        token_url = auth_url + '/tokens'
        req_header = {'Content-Type': 'application/json'}
        req_body = {
            'auth': {
                'tenantId': tenant_id,
                'passwordCredentials': {
                    'username': username,
                    'password': password
                }
            }
        }
    
        response = requests.post(token_url, headers=req_header, json=req_body)
        return response.json()
    
    
    if __name__ == '__main__':
        AUTH_URL = 'https://api-identity-infrastructure.nhncloudservice.com/v2.0'
        TENANT_ID = '{Tenant ID}'
        USERNAME = '{NHN Cloud Account}'
        PASSWORD = '{API Password}'
    
        token = get_token(AUTH_URL, TENANT_ID, USERNAME, PASSWORD)
        print(json.dumps(token, indent=4))
    ```

{% include-markdown './console-guide.md' %}
