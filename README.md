# Projeto Terraform VPC para EKS

## Introdução

Este projeto utiliza Terraform para provisionar uma infraestrutura de rede (VPC) na AWS, pronta para receber clusters Kubernetes (EKS) ou outras aplicações em nuvem. O objetivo é criar uma base de rede segura, escalável e de fácil manutenção, seguindo boas práticas de arquitetura AWS.

## Estrutura do Projeto
```
    terraform-vpc/
    ├── main.tf 
    ├── variables.tf
    ├── outputs.tf 
    ├── terraform.tfvars 
    ├── modules/ 
    │ └── vpc/ 
    │ ├── main.tf 
    │ ├── variables.tf 
    │ ├── outputs.tf
```

- **main.tf**: Chama o módulo VPC e define o provider.
- **variables.tf**: Declara as variáveis usadas no projeto.
- **outputs.tf**: Exporta os principais IDs de recursos criados.
- **terraform.tfvars**: Define os valores das variáveis para o ambiente.
- **modules/vpc/**: Implementação do módulo reutilizável para criação da VPC e seus componentes.

## Recursos Criados

- **VPC**: Rede isolada para todos os recursos AWS.
- **Subnets Públicas e Privadas**: Permitem separar recursos que precisam de acesso externo dos que ficam isolados.
- **Internet Gateway**: Necessário para dar acesso à internet às subnets públicas.
- **NAT Gateway**: Permite que recursos em subnets privadas acessem a internet de forma segura.
- **Elastic IP (EIP)**: IP público fixo para o NAT Gateway.
- **Route Tables e Associações**: Controlam o roteamento do tráfego entre subnets, internet e NAT.
- **Tags de Ambiente**: Todos os recursos recebem a tag `Environment` para facilitar o gerenciamento e identificação.

## Por que cada recurso é necessário?

- **VPC**: Isola e organiza a rede dos seus recursos na AWS.
- **Subnets Públicas**: Hospedam recursos que precisam ser acessados de fora da VPC (ex: Load Balancers).
- **Subnets Privadas**: Hospedam recursos internos, como bancos de dados ou nodes privados do EKS, aumentando a segurança.
- **Internet Gateway**: Permite que recursos em subnets públicas acessem a internet.
- **NAT Gateway + EIP**: Permite que recursos em subnets privadas façam requisições para a internet (ex: baixar atualizações), sem ficarem expostos.
- **Route Tables**: Garantem que o tráfego seja roteado corretamente entre subnets, internet e NAT.
- **Tags**: Facilitam a organização, automação e controle de custos na AWS.

---

**Observação:**  
Esta estrutura modular permite fácil reutilização e integração com outros projetos Terraform, especialmente para clusters EKS e workloads modernos.

---

## Comandos para criar e destruir os recursos

```sh
# Inicializar o Terraform (executar apenas uma vez no início)
terraform init

# Visualizar o plano de execução
terraform plan

# Aplicar as mudanças e criar a infraestrutura
terraform apply

# Destruir todos os recursos criados
terraform destroy
```

# log de criação 

    Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

    Outputs:

    private_subnet_ids = [
    "subnet-027adc7f939b20e1d",
    "subnet-07de815b354a970f1",
    ]
    public_subnet_ids = [
    "subnet-0560da61477904327",
    "subnet-083d8ac6b9bc3d4ae",
    ]
    vpc_id = "vpc-0e764bf02c51fb00e"

# log destruir os recursos


    module.vpc.aws_route_table_association.private[1]: Destroying... [id=rtbassoc-04e461f92f4dded34]
    module.vpc.aws_route_table_association.public[1]: Destroying... [id=rtbassoc-0f0dec891e9cb7656]
    module.vpc.aws_route_table_association.public[0]: Destroying... [id=rtbassoc-0e52a3a6081ec821d]
    module.vpc.aws_route_table_association.private[0]: Destroying... [id=rtbassoc-03c68f506c0ee13a3]
    module.vpc.aws_route_table_association.public[1]: Destruction complete after 1s
    module.vpc.aws_route_table_association.private[1]: Destruction complete after 1s
    module.vpc.aws_route_table_association.private[0]: Destruction complete after 1s
    module.vpc.aws_route_table_association.public[0]: Destruction complete after 1s
    module.vpc.aws_route_table.public: Destroying... [id=rtb-0a6a7ea2b7df57173]
    module.vpc.aws_subnet.private[0]: Destroying... [id=subnet-027adc7f939b20e1d]
    module.vpc.aws_route_table.private[0]: Destroying... [id=rtb-07985f72133a2834c]
    module.vpc.aws_subnet.private[1]: Destroying... [id=subnet-07de815b354a970f1]
    module.vpc.aws_subnet.private[1]: Destruction complete after 1s
    module.vpc.aws_subnet.private[0]: Destruction complete after 1s
    module.vpc.aws_route_table.private[0]: Destruction complete after 1s
    module.vpc.aws_nat_gateway.this[0]: Destroying... [id=nat-0c2763f47de9e2a92]
    module.vpc.aws_route_table.public: Destruction complete after 1s
    module.vpc.aws_nat_gateway.this[0]: Still destroying... [id=nat-0c2763f47de9e2a92, 10s elapsed]
    module.vpc.aws_nat_gateway.this[0]: Still destroying... [id=nat-0c2763f47de9e2a92, 20s elapsed]
    module.vpc.aws_nat_gateway.this[0]: Still destroying... [id=nat-0c2763f47de9e2a92, 30s elapsed]
    module.vpc.aws_nat_gateway.this[0]: Still destroying... [id=nat-0c2763f47de9e2a92, 40s elapsed]
    module.vpc.aws_nat_gateway.this[0]: Still destroying... [id=nat-0c2763f47de9e2a92, 50s elapsed]
    module.vpc.aws_nat_gateway.this[0]: Destruction complete after 52s
    module.vpc.aws_subnet.public[1]: Destroying... [id=subnet-083d8ac6b9bc3d4ae]
    module.vpc.aws_subnet.public[0]: Destroying... [id=subnet-0560da61477904327]
    module.vpc.aws_eip.nat[0]: Destroying... [id=eipalloc-00f22823eb8dd7ae2]
    module.vpc.aws_subnet.public[0]: Destruction complete after 1s
    module.vpc.aws_subnet.public[1]: Destruction complete after 1s
    module.vpc.aws_eip.nat[0]: Destruction complete after 1s
    module.vpc.aws_internet_gateway.this: Destroying... [id=igw-0ac43fc3715ed21f9]
    module.vpc.aws_internet_gateway.this: Destruction complete after 1s
    module.vpc.aws_vpc.this: Destroying... [id=vpc-0e764bf02c51fb00e]
    module.vpc.aws_vpc.this: Destruction complete after 1s

    Destroy complete! Resources: 14 destroyed.