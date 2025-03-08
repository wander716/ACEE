# Implementation
## step1. 使用dockerfile构建镜像
```bash
# 使用 Ubuntu 22.04 基础镜像
FROM ubuntu:latest

# 安装 SSH 和其他必要环境
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    iputils-ping \
    && mkdir /var/run/sshd

# 创建 SSH 用户并设置密码
RUN useradd -m -s /bin/bash dockeruser \
    && echo 'dockeruser:password' | chpasswd \
    && adduser dockeruser sudo


# 设置工作目录
WORKDIR /home/dockeruser

# 打开 SSH 端口
EXPOSE 22

# 启动 SSH 服务
CMD ["/usr/sbin/sshd", "-D"]

```

## step2. 使用docker-compose.yml构建容器
```bash

version: '3.8'

services:
  # 创建 20 个 Ubuntu 容器
  container1:
    image: ubuntu:latest
    container_name: ubuntu-container1  #从镜像ubuntu:latest中pull一个container，并命名为ubuntu-container1
    build:
      context: .  #若目录中含有dockerfile，则从dockerfile中创建container，即使用FROM方法
    tty: true
    networks:
      - my_network  #连接自定义网络
    ports:
      - "2221:22"  # 为容器 1 映射 SSH 端口，将容器内部的端口绑定到宿主机的端口2221:22，从而实现外部访问。
    volumes:
      - ./data:/data

  container2:
    image: ubuntu:latest
    container_name: ubuntu-container2
    build:
      context: .
    tty: true
    networks:
      - my_network
    ports:
      - "2222:22"  # 为容器 2 映射 SSH 端口
    volumes:
      - ./data:/data

  container3:
    image: ubuntu:latest
    container_name: ubuntu-container3
    build:
      context: .
    tty: true
    networks:
      - my_network
    ports:
      - "2223:22"  # 为容器 3 映射 SSH 端口
    volumes:
      - ./data:/data



networks:
  my_network:
    driver: bridge  # 创建自定义网络，使容器位于该网络中，可以互相 ping 和 ssh


```

## step3. 运行docker compose，即实现build功能（FROM）
```bash
docker-compose up --build

```

## step4. ssh访问容器
```bash
ssh dockeruser@localhost -p 2221

```

## step5. 容器之间ssh互相访问
```bash
ssh dockeruser@ubuntu-container2

```



# Hint

## 1. 要实现容器之间的互联需要什么
## 基本原理
Docker提供了**bridge**(默认)，**host**, **overlay**等多种网络模式，最常见的是bridge(桥接网络)

## 使用docker run
```bash
///创建一个自定义网络
docker network create mynetwork
///运行容器并加入该网络
docker run -d --name container1 --network mynetwork nginx
docker run -d --name container2 --network mynetwork busybox sleep 3600
///用ping来测试容器之间的通信
docker exec -it container2 sh
ping container1
```

## 使用docker compose(适用于多容器应用)
```bash
///构建network
networks:
  my_network:
    driver: bridge  # 创建自定义网络，容器将位于该网络中，可以互相 ping 和 ssh

///使用此network
container1:
  image: ubuntu:latest
  container_name: ubuntu-container1
  build:
    context: .
  tty: true
  networks:
      - my_network
```

## 2. 怎样通过Docker Compose和Dockerfile使得每个容器带有ssh服务
- 使用Dockerfile在镜像安装的时候通过RUN指令来安装OpenSSH服务器并启动
```bash
# 使用 Ubuntu 作为基础镜像
FROM ubuntu:latest

# 安装 SSH 服务和其他依赖
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    iputils-ping \
    && mkdir /var/run/sshd

# 创建 SSH 用户并设置密码
RUN useradd -m -s /bin/bash dockeruser \
    && echo 'dockeruser:123456' | chpasswd \
    && adduser dockeruser sudo


# 开放 SSH 端口
EXPOSE 22
# 启动 SSH 服务
CMD ["/usr/sbin/sshd", "-D"]

```
- 在docker-compose.yml文件中构建并指定networks，并分配ports
- 运行容器  

```bash
docker-compose up -d
```
