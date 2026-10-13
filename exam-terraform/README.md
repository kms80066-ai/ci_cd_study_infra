# Terraform 실습: Nginx ASG/ALB + RDS MySQL + EKS + 점프박스

작업 디렉터리: `exam-terraform/` (원본 Terraform 루트와 별개).
이 프로젝트는 `local.tf`에서 설정값을 모아 모듈에 전달하는 local-first 방식.

## 구성
- ca-central-1 / AZ 1a, 1b
- VPC 10.90.0.0/16, Public 2 + Private 2 + Cluster Private 2
- Public/Private/Cluster Route Table 각 1개, NAT Gateway 1개
- Public Jumpbox: AL2023, t3.micro, gp3 10GiB, `std09-keypair`, SSM
- Private Nginx ASG: AL2023, Docker, t3.micro, gp3 10GiB, **최소 1 / 희망 2 / 최대 3**
- Public ALB HTTP 80 -> Private Nginx ASG HTTP 80
- Private RDS MySQL: db.t3.micro, 20GiB gp3, **관리자 `std09`**
  - Single AZ(기본값). `local.tf`의 `db_multi_az = true`로 Multi-AZ 선택 가능 (비용 증가)
  - RDS Proxy는 **미생성**: 아직 실제 DB 연결 애플리케이션이 없음
  - DB 비밀번호 AWS Secrets Manager 자동 관리, Public 접속 불가
- Private EKS Managed Node Group: t3.small, **최소 1 / 희망 2 / 최대 3**
  - EC2 태그명 `std09-exam-eks-worker-node`
- ASG EC2 태그명 `std09-exam-nginx-asg-ec2`
- FastAPI 및 모니터링 모듈 호출 없음. 기존 모니터링 폴더는 남아 있어도 실행되지 않음.

## 인바운드 보안
- Jumpbox EC2: SSH 22 (기본 VPC CIDR), HTTP 80/HTTPS 443 (VPC CIDR)
- Web EC2: SSH 22 (Jumpbox SG), HTTP 80/HTTPS 443 (ALB SG)
- EKS worker EC2: SSH 22 (Jumpbox SG), HTTP 80/HTTPS 443 (VPC CIDR)
  - 이전 EKS 실습의 노드 self-all 및 control-plane -> kubelet 10250 포함
  - AWS EKS cluster SG도 Node Launch Template에 같이 부착함
- ALB: 외부 HTTP 80/HTTPS 443. 실제 Listener는 HTTP 80만 존재 (443 사용에는 인증서/Listener 필요).
- RDS: SSH/HTTP/HTTPS 대상이 아니라 MySQL 3306만 Web/Jumpbox SG에서 접근.

> **점프박스 SSH 주의**: 기본 `local.tf`의 `ssh_allowed_cidr = local.vpc_cidr` 설정은 인터넷에서 SSH 접속을 열지 않음.
> SSM Session Manager로 접속하거나, 내 공인 IP를 확인한 뒤 `ssh_allowed_cidr = "x.x.x.x/32"`로 수정.
> 22번 포트를 전 세계(0.0.0.0/0)에 공개하지 말 것.
> 모든 EC2의 SSH 인증용 `std09-keypair`가 ca-central-1에 있어야 함.

## AWS 변경 주의사항 (기존 apply 사용자인 경우)
**이 변경은 반드시 새 Terraform plan을 생성해서 검토한 뒤 적용해야 함.**
- `db_username = "admin"` -> `"std09"`: RDS 교체(파괴 후 재생성)로 이어질 수 있음. 기존 데이터/스냅샷 확인 필수. 기존 코드에 `skip_final_snapshot = true`가 설정돼 있으므로, 데이터 보존이 필요하면 **절대로 바로 apply 하지 말 것**.
- 이미 생성된 EKS Managed Node Group에 Custom Launch Template을 처음 추가: 노드 그룹 재생성(또는 교체) 필요할 수 있고 일시 중단 가능. EKS Control Plane 자체와 Node Group은 다른 리소스임.
- ASG 설정 및 Launch Template 변경 후 현재 실행 중인 EC2의 Name 태그는 자동으로 바뀌지 않을 수 있음. 새로 생성되는 EC2는 수정된 태그를 사용.

## 실행 명령
```bash
cd ~/for_1014/exam-terraform
git status
git fetch origin
git pull --ff-only origin feature/terraform-exam-20261013
terraform init
terraform fmt -recursive
terraform validate
rm -f exam.tfplan
terraform plan -out=exam.tfplan
# "destroy", "replace" 포함 여부를 반드시 검토한 다음에만:
terraform apply exam.tfplan
```

## 검증
```bash
terraform output alb_url
terraform output rds_endpoint
terraform output eks_cluster_name
terraform output jumpbox_public_ip

aws eks update-kubeconfig --region ca-central-1 --name std09-exam-eks
kubectl get nodes -o wide
```

점프박스 SSM:
```bash
aws ssm start-session --target "$(aws ec2 describe-instances --region ca-central-1 --filters Name=tag:Name,Values=std09-exam-jumpbox Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].InstanceId' --output text)" --region ca-central-1
```

## 정리
```bash
terraform destroy
```
RDS, EKS, ALB, NAT, EC2 등은 유료. DB는 실습용으로 최종 스냅샷 없이 삭제되므로 데이터 주의.
