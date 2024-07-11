# Cogtive - Local ENV

Este projeto tem como objetivo automatizar o provisionamento de um cluster K3D com o uso de Terraform, configurando de forma simples todos os serviços necessários para trabalhar localmente.

# Conteúdo

- [Requisitos](#requisitos)
- [Setup](#setup)
- [Utilização](#utilização)
- [Como Contribuir](#como-contribuir)

## Requisitos

### Portas necessárias

This project uses some ports to control traffic between your local machine and k3d cluster, make sure the ports bellow are open:

- 80 - http 
- 443 - https
- 5432 - tcp postgres
- 5672 - tcp rabbitmq

### Docker

Instale o [Docker](https://www.docker.com/) no seu sistema operacional.

Obs: no Windows é necessário usar através do WSL2, com o Ubuntu 22.04 e operar via [Windows Terminal](https://apps.microsoft.com/detail/9n0dx20hk701?rtc=1&hl=pt-br&gl=BR).

### kubectl 

Instale o [kubectl](https://kubernetes.io/docs/tasks/tools/) ou habilite o Kubernetes no Docker Desktop.

### Terraform

Instale o [Terraform 1.5 ou superior](https://developer.hashicorp.com/terraform/install?product_intent=terraform) e garanta que o comando esteja disponível na variável PATH.

``` bash
$ terraform -v                                                                                                                        
Terraform v1.7.4
on linux_amd64
+ provider registry.terraform.io/alekc/kubectl v2.0.4
+ provider registry.terraform.io/gavinbunney/kubectl v1.14.0
+ provider registry.terraform.io/hashicorp/aws v5.41.0
+ provider registry.terraform.io/hashicorp/helm v2.10.1
+ provider registry.terraform.io/hashicorp/kubernetes v2.21.1
+ provider registry.terraform.io/hashicorp/null v3.2.2
+ provider registry.terraform.io/hashicorp/tls v4.0.4
```

### AZ CLI

Instale o AZ CLI [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) e garanta que o comando esteja disponível na variável PATH.

``` bash
$ az version  
{
  "azure-cli": "2.58.0",
  "azure-cli-core": "2.58.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
```
### K3D
Install [K3D](https://k3d.io/v5.6.0/#installation) 

``` bash
$  k3d --version                   

k3d version v5.6.0
k3s version v1.27.4-k3s1 (default)
```

## Setup

Because this project uses ECR and SecretsManager services from Comet Cash AWS DEV Account, you need to have an aws sso configured. 

To setups, follow these steps:

1. Configure a Profile for DEV account: 

``` bash
$ aws configure sso --profile cometcash-dev 

SSO session name (Recommended): (leave blank, press ENTER/RETURN)

SSO start URL []: https://cometcash.awsapps.com/start#/

SSO region []: us-east-1

There are X AWS accounts available to you. 
> Comet Cash Development, aws.dev@cometcash.com (063714734417)  

Select DeveloperAccess ROLE

CLI default client Region []: us-east-1

CLI default output format []: json

```

After finished sso setup, the token is valid for 12 hours, it is necessary to perform a new login after this period with this command:

``` bash
$ aws sso login --profile cometcash-dev  
```
2. Append the entries in hosts file:

``` bash
127.0.0.1 postgres.localhost
127.0.0.1 rabbitmq.localhost
127.0.0.1 api.localhost
127.0.0.1 services.localhost
127.0.0.1 redis.localhost
127.0.0.1 kong.localhost
```

## Utilização

In your favorite terminal with bash support (On Windows see about WSL), just run:

### Create K3D Cluster

``` bash
$ ./local-env create_cluster
``` 

This command creates a k3d cluster,  mount volumes ($HOME/k3d/) and map all ports

After cluster creation, you can perform kubectl commands on the k3d-local cluster context


### Deploy Services

This command pulls all docker images described in images.json file and runs a terraform apply inside the k3d-local cluter and applies all Comet Cash services including kong, redis, postgresql and rabbitmq.

``` bash
$ ./local-env deploy all
```

If need only deploy without pull and importing, just run without argument:

``` bash
$ ./local-env deploy 
```

If you need to only deploy importing new images, run:

``` bash
$ ./local-env deploy import
```

#### Check the services running inside cluster: 

``` bash

$ kubectl get pods -A

NAMESPACE             NAME                                        READY   STATUS      RESTARTS      AGE
kube-system           coredns-77ccd57875-crkh2                    1/1     Running     0             7m50s
kube-system           local-path-provisioner-957fdf8bc-ts678      1/1     Running     0             7m50s
kube-system           metrics-server-648b5df564-j765x             1/1     Running     0             7m50s
istio-system          istiod-7f47c7f7fb-tssv6                     1/1     Running     0             2m14s
......
```

Comet Cash services are within namespaces prefixed with cc-*  (cc means CometCash)

``` bash
$ kubectl get ns | grep cc-

cc-quote-service    Active   91s
cc-ramp-service     Active   91s
cc-sample-service   Active   91s
....
```

``` bash
$ kubectl get po -n cc-ramp-service

NAME                            READY   STATUS    RESTARTS   AGE
ramp-service-66fb4c69f4-27g45   2/2     Running   0          112s
```
#### Check kong on browser: 

http://kong.localhost

![alt text](./docs/image.png)

#### Check an endpoint through kong api gateway: 

http://api.localhost/sample/environment

![alt text](./docs/image-1.png)

#### Check an endpoint through istio service mesh

http://services.localhost/lsp-service/api

![alt text](./docs/swagger.png)

#### Check postgresql connection using dbeaver

![alt text](./docs/dbeaver-1.png)

#### Check Redis connection using 'Another Redis Desktop Manager'

![alt text](./docs/redis.png)

#### Check RabbitMQ Manager 

![alt text](./docs/rabbit.png)


### Delete cluster:

``` bash
$ ./local-env delete_cluster
```

### List of services

All docker images are listed in images.json.

The folder services contains all helm charts of these services.

To disable or enable services, just change the enabled flag.

By default, all available services are enabled.

## Como Contribuir

Para contribuir com este projeto, abra uma branch a partir da branch [main](https://dev.azure.com/cloudcogtive/COGTIVE%20-%20CICD/_git/local-env), implemente sua melhoria ou feature, e mande um Pull Request. 

Não esqueça de anexar a task no Pull Request e preencher uma descrição s