# Local 중심 재구성 검토

## 의도

- state 이전용 `moved` 블록 제거
- 다음 4·5·6번 수업을 계속 추가하기 쉬운 구조
- 루트의 사용자 설정을 `local.tf`에 집중
- 모듈 내부 실제 리소스에서 `var.xxx` 직접 사용을 피하고 `local.xxx` 사용
- `data` 조회값도 local 이름으로 정리 후 사용

## 구조 변경

- 루트 `variable.tf` 제거
- 루트 `terraform.tfvars.example` 제거
- `owner`, `key_name`을 포함한 사용자 설정을 루트 `local.tf`로 이동
- Network / Security / Endpoints / Storage / Compute에 `local.tf` 패턴 적용
- Network의 Public / Private / Cluster 서브넷 필터를 `local.tf`에서 한 번만 계산
- Route Table의 `moved` 블록 제거
- 기존에 합의한 `non_public_*` 이름 유지
- Compute의 불필요한 명시적 depends_on은 추가하지 않고 network/storage만 유지

## AWS 리소스 구성

아래의 의도된 구성은 이전 정상 동작본과 동일합니다.

- Public / Private / Cluster 서브넷 각 3개
- Public RT 1개 / Private RT 3개 / Cluster RT 1개
- NAT Gateway 1개
- S3 Gateway Endpoint
- ECR API / DKR Interface Endpoint
- Security Group 세트
- EFS 1개 + Mount Target 3개
- 테스트 EC2 1개 + root 8GiB + 추가 5GiB
- Website / Logs S3 버킷

## State 관련

이 버전은 이전 구조를 오래 지원하기 위한 migration 코드가 아니라 현재 구조 자체를 기준으로 합니다.

이미 `moved`가 포함된 버전을 apply해서 state가 새 주소로 정리된 환경이라면 `moved` 삭제 후에도 보통 리소스 변경이 없어야 합니다. 하지만 state는 사용자 AWS 환경에 있으므로 실제 적용 전 `terraform plan` 확인이 필수입니다.

이번 작업 환경에는 Terraform CLI가 없어 실제 remote backend를 사용한 `terraform validate/plan`은 실행하지 못했습니다. User Data의 bash 문법과 파일 참조는 별도로 점검합니다.
