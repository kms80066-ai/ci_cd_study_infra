# 이번 재구성에서 바뀐 핵심

1. `modules/network/route.tf`의 `moved` 블록을 삭제했습니다.
2. 루트의 `owner`, `key_name`, `region`, `azs`, `vpc_cidr`, EC2 서브넷 선택을 `local.tf`에 모았습니다.
3. 루트 `variable.tf`, `terraform.tfvars.example`을 제거했습니다.
4. 모든 하위 모듈에 `local.tf` 패턴을 적용했습니다.
5. 하위 모듈의 `var.xxx`는 `local.tf`에서만 받고, 실제 리소스 파일에서는 `local.xxx`를 사용하도록 정리했습니다.
6. `data`가 필요한 Compute/Endpoints는 조회 결과를 local로 받아 리소스에서 사용합니다.
7. Network에서 `public_subnets`, `private_subnets`, `cluster_subnets`를 local로 미리 분리해 `route.tf`를 단순화했습니다.
8. 기존 합의사항인 `non_public_cidrs`, `non_public_route_table_ids` 이름은 유지했습니다.
9. Terraform resource 블록 35개의 type/name은 이전 정리본과 동일합니다.
10. 다음 4·5·6번은 `root local.tf -> root main.tf -> module variable/local/main/output` 패턴으로 추가할 수 있게 README에 규칙을 적었습니다.

## 적용 전에 꼭 확인할 것

현재 AWS 환경은 이미 이전 코드로 apply되어 있으므로 먼저 아래까지만 실행합니다.

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

`plan`에서 예상하지 않은 destroy/create가 보이지 않는 것을 확인한 뒤에만 apply합니다.
