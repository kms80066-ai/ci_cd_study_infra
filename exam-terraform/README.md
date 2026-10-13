# Terraform 과제 - Nginx ASG/ALB + RDS MySQL + EKS

기준: 기존 `ci_cd_study_infra` 프로젝트의 모듈화 / local-first 구성.
**원본 프로젝트와 별개 디렉터리이므로 반드시 `exam-terraform/`에서 실행.**

## 아키텍처

- Region: ca-central-1 / Owner: std09
- VPC: 10.90.0.0/16, 2개 AZ (1a, 1b)
- Public: 10.90.1.0/24, 10.90.2.0/24 — ALB, NAT
- Private: 10.90.11.0/24, 10.90.12.0/24 — Nginx ASG, RDS MySQL
- Cluster Private: 10.90.21.0/24, 10.90.22.0/24 — EKS Control Plane ENI/Worker Nodes
- 라우팅 테이블은 Public/Private/Cluster 각 1개. NAT Gateway는 실습 비용 절감용으로 1개.
- Nginx: AL2023, t3.micro, 10GiB gp3, Docker Hub의 `nginx:stable-alpine` 이미지 자동 실행
- ALB → Target Group(80) → private ASG EC2(80)
- RDS MySQL: db.t3.micro / 20GiB gp3 / 비공개 / 자동 생성된 비밀번호를 AWS Secrets Manager에서 관리
- EKS: 독립 클러스터, cluster private subnet에 t3.small Managed Node Group 1대
- CloudWatch: ASG/ALB/RDS 대시보드, RDS CPU 알람(알림 전송은 없음)
- **FastAPI 없음**. Nginx와 RDS는 따로 생성되며 실제 DB 쿼리 연동은 하지 않음.
- **Grafana 미구성**: 노션의 추가 4번 요구사항. 운영 방식/인증 방식 결정 후 추가할 부분.

## 디렉터리

```text
exam-terraform/
  provider.tf
  local.tf
  main.tf
  output.tf
  modules/
    network/      # VPC + 6 subnets + RT 3 + IGW + NAT
    security/     # ALB/Web/RDS security groups
    web/          # Launch Template + Docker Nginx + ASG + ALB
    rds/          # RDS MySQL + DB Subnet Group
    eks/          # EKS Cluster + Managed Node Group
    monitoring/   # CloudWatch Dashboard + Alarm
```

## 실행 전

1. AWS CLI 자격 증명과 ca-central-1 권한 확인 (`aws sts get-caller-identity`).
2. EKS, RDS, NAT, ALB 및 EC2 생성 권한과 AWS 서비스 할당량 확인.
3. `local.tf`의 AZ, CIDR 및 인스턴스 설정 확인.
4. 이 디렉터리에서 Terraform 실행. **기존 `ci_cd_study_infra` 루트에서 실행하지 않기.**
5. 별도 백엔드 설정 없음: **tfstate는 작업 디렉터리에 로컬 저장**. 안전하게 보관하고 GitHub에 올리지 않기.

```bash
cd exam-terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=exam.tfplan
terraform apply exam.tfplan
```

## 검증

```bash
terraform output alb_url
terraform output rds_endpoint
terraform output eks_cluster_name

aws autoscaling describe-auto-scaling-groups --region ca-central-1 --auto-scaling-group-names std09-exam-nginx-asg
aws rds describe-db-instances --region ca-central-1 --db-instance-identifier std09-exam-mysql
aws eks describe-cluster --region ca-central-1 --name std09-exam-eks
aws eks update-kubeconfig --region ca-central-1 --name std09-exam-eks
kubectl get nodes
```

- ALB 주소를 웹 브라우저에서 열면 Nginx 기본 환영 페이지가 보여야 함.
- ALB Target Group 대상 상태가 `healthy`인지 확인.
- EC2가 Docker 이미지를 가져오려면 NAT를 통한 외부 통신이 필요.
- RDS는 DB 인스턴스만 만들어진 상태. 인터넷에서 MySQL 접속 불가.
- MySQL 비밀번호는 `terraform output rds_master_secret_arn`으로 ARN을 확인한 뒤 권한이 있으면 Secrets Manager에서 조회. Git 저장소에 기록하지 않기.

## 종료 (비용 주의)

```bash
terraform destroy
```

EKS Control Plane, Node EC2, NAT Gateway/EIP, ALB, RDS, EC2, CloudWatch 등이 비용을 발생시킴.
실습 후 삭제 전 필요한 데이터가 없는지 확인. RDS는 실습용이므로 최종 스냅샷 없이 삭제되도록 설정함.

## 참고

- 10.13 노션 요구사항 중 4번 CloudWatch/Grafana: 현재 CloudWatch 기본 지표만 포함, Grafana 자체는 구축하지 않음.
- ASG와 EKS Managed Node Group은 **서로 다른** 오토 스케일링 구성.
- CIDR이 이미 사용 중인 VPC와 중복되는지 확인.
- AWS 실제 `apply`는 실행하지 않았음. `terraform init/validate/plan`으로 환경 검증 후 적용할 것.

