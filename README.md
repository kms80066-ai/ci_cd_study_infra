# Terraform 실습 1~3번 - Local 중심 구조

이 버전은 현재 정상 동작한 1~3번 구성을 유지하면서, 다음 수업의 4·5·6번을 계속 추가하기 쉽도록 구조를 다시 정리한 버전입니다.

## 1. 이번 구조의 가장 중요한 규칙

### 루트에서는 `local.tf`가 설정판입니다

직접 바꾸는 값은 루트 `local.tf`에서 찾습니다.

- `local.owner`
- `local.key_name`
- `local.region`
- `local.azs`
- `local.vpc_cidr`
- `local.cluster_name`
- `local.test_ec2_subnet_key`
- `local.subnet_map`

루트의 `variable.tf`와 `terraform.tfvars`는 사용하지 않습니다.

### 모듈 안에서는 `variable.tf -> local.tf -> resource` 순서입니다

모듈은 바깥에서 값을 받아야 하므로 `variable.tf` 자체는 필요합니다. 대신 `var.xxx`는 각 모듈의 `local.tf`에서만 받아 정리합니다.

예:

```hcl
# modules/network/local.tf
locals {
  vpc_cidr   = var.vpc_cidr
  tag_header = var.tag_header
}
```

실제 리소스에서는 이렇게 사용합니다.

```hcl
resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
}
```

따라서 공부할 때는 다음 순서로 보면 됩니다.

1. 루트 `local.tf`: 내가 정한 값
2. 루트 `main.tf`: 모듈끼리 연결
3. 각 모듈 `variable.tf`: 모듈 입구
4. 각 모듈 `local.tf`: 받은 값을 정리
5. 각 리소스 파일: `local.xxx`를 사용해 AWS 리소스 생성
6. 각 모듈 `output.tf`: 다음 모듈로 내보낼 값

`data`는 AWS에서 기존 정보를 조회하는 Terraform 기능이라 없앨 수 없습니다. 대신 조회 결과를 실제 코드에서 여러 번 직접 쓰지 않고 `local` 이름으로 받아 사용합니다.

## 2. 현재 구성

| 항목 | 설정 |
|---|---|
| 리전 / AZ | ca-central-1 / a, b, d |
| VPC | 10.0.0.0/16 |
| Public | 10.0.1.0/24 ~ 10.0.3.0/24 |
| Private | 10.0.11.0/24 ~ 10.0.13.0/24 |
| Cluster | 10.0.21.0/24 ~ 10.0.23.0/24 |
| Route Table | Public 1 / Private 3 / Cluster 1 |
| NAT Gateway | public1a에 1개 |
| Endpoint | S3 / ECR API / ECR DKR |
| EFS | 1개 + Private a/b/d Mount Target 3개 |
| 테스트 EC2 | public1a 기본, t3.nano, Ubuntu 24.04 |
| S3 | Website / Logs 버킷 |
| EKS 준비 | Cluster / Node SG까지만 생성 |

## 3. `moved` 블록은 제거했습니다

이 버전에는 다음과 같은 state 이전용 코드가 없습니다.

```hcl
moved {
  ...
}
```

현재 구조 자체를 기준으로 공부하고 앞으로 확장하기 위한 코드만 남겼습니다.

중요: 이미 이전 버전에서 `terraform apply`를 정상 완료했다면 현재 state에는 단일 `aws_route_table.cluster` 주소가 기록되어 있을 가능성이 높습니다. 이 경우 `moved`를 지워도 보통 추가 변경은 생기지 않습니다. 그래도 반드시 적용 전 `terraform plan`에서 생성/삭제가 새로 잡히지 않는지 확인합니다.

## 4. Network를 다음 수업까지 확장하기 쉽게 정리한 부분

`modules/network/local.tf`에서 서브넷을 먼저 세 종류로 나눕니다.

```hcl
local.public_subnets
local.private_subnets
local.cluster_subnets
```

그래서 `route.tf`에서는 복잡한 조건식을 반복하지 않고 각 그룹을 바로 사용합니다.

- Public Route Table: 1개
- Private Route Table: AZ별 3개
- Cluster Route Table: 1개

다음 수업에서 새로운 서비스가 Public / Private / Cluster 중 어디에 들어가는지만 판단하면 기존 output을 연결하면 됩니다.

## 5. 다음 4·5·6번을 추가할 때의 규칙

새 설정값이 필요하면 먼저 루트 `local.tf`에 추가합니다.

새 서비스가 독립적인 역할이면 `modules/<새이름>` 폴더를 만들고 다음 네 파일을 기본으로 둡니다.

```text
modules/<새이름>/
  variable.tf
  local.tf
  main.tf
  output.tf
```

AWS 기존 정보를 조회해야 할 때만 `data.tf`를 추가합니다.

루트 `main.tf` 아래에는 새 `module` 블록을 추가하고, 기존 리소스 ID가 필요하면 `module.network.xxx`, `module.security.xxx` 같은 output을 연결합니다.

즉 앞으로도 구조가 바뀌지 않습니다.

```text
설정값        -> root local.tf
모듈 연결     -> root main.tf
모듈 입력     -> module variable.tf
모듈 내부정리 -> module local.tf
AWS 생성      -> module main.tf / 역할별 tf
결과 전달     -> module output.tf
```

## 6. Backend는 예외입니다

`backend.tf`의 S3 backend 설정에는 `local.xxx`를 사용할 수 없습니다. Terraform이 backend를 먼저 초기화하기 때문입니다. 따라서 이 파일의 값은 직접 적혀 있는 것이 정상입니다.

## 7. 실행 전 확인

이미 현재 환경이 정상 동작한 상태이므로 새 구조를 적용하기 전에 먼저 plan만 확인합니다.

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

가장 중요한 것은 `terraform plan` 결과입니다.

- 기존 리소스의 대량 destroy/create가 없으면 정상
- 단순 코드 정리이므로 가능하면 `No changes`가 가장 좋음
- 예상하지 않은 삭제/재생성이 보이면 바로 apply하지 않음

그 다음에만:

```powershell
terraform apply
```

## 8. EC2 확인

```powershell
terraform output -raw instance_public_ip
ssh -i "std09-keypair.pem" ubuntu@출력된공인IP
```

EC2 안에서:

```bash
sudo cloud-init status --wait
aws --version
sudo docker --version
sudo docker compose version
findmnt /mnt/efs
lsblk
```

## 9. 이번 버전에서 유지한 것

이미 정상 동작한 AWS 구성 자체는 함부로 바꾸지 않았습니다.

- VPC / Subnet CIDR
- NAT Gateway 1개
- Route Table 수와 연결 방식
- S3 / ECR Endpoint
- EFS
- 테스트 EC2와 EBS
- Security Group 규칙
- S3 Website / Logs 버킷
- Backend 경로

바꾼 것은 주로 **코드를 읽는 방식과 설정값을 놓는 위치**입니다.
