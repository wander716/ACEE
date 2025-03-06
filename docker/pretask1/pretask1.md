## 1. 使用dockerfile拉取镜像并建立一个新容器
### 使用dockerfile
```bash
///dockerfile
FROM ubuntu:latest
WORKDIR /root
# 创建 helloworld.txt 并写入 "hel"
RUN echo "helloworld" > helloworld.txt
CMD ["/bin/bash"]
```
## 2. 逐句分析每行语句的意义与作用
- FROM ubuntu:latest  
    - 这行指定基础镜像，这里使用的是ubuntu-latest，即最新版本的ubuntu官方镜像
    - FROM指令是Dockerfile必须的第一条指令，用于指定新镜像的基础环境
    
- WORKDIR /root
    - WORKDIR设置默认的工作目录，**/root**是Ubuntu系统root用户的主目录

- RUN echo "helloworld" > helloworld.txt
    - RUN 指令用于 在构建镜像时 运行命令，并将结果保存到最终的 Docker 镜像中。
    - echo "helloworld" 会输出 "helloworld" 字符串。
    - '>'符号 表示重定向，将 "helloworld" 写入 helloworld.txt 文件，如果文件不存在，则创建它。

- CMD ["/bin/bash"]
    - CMD 指令指定 容器启动后要执行的默认命令。
    - ["/bin/bash"] 让容器在启动时进入 bash 交互模式，等待用户输入命令。


## 3. Dockerfile还有哪些其他的语句以及其作用和意义
- LABEL  
添加元数据(标签)，通常用于作者信息或描述镜像内容
```bash
LABEL maintainer="your_email@example.com"
LABEL version="1.0"
LABEL description="This is a custom Ubuntu image"

```

- COPY  
从宿主机复制文件/目录到容器内，适用于本地文件。
```bash
COPY myscript.sh /root/

```
- ENV  
设置环境变量
```bash
ENV APP_ENV=production
`
```
- 端口
```bash
EXPOSE 8080

``
- VOLUME  
挂载卷
```bash
VOLUME ["/data"]

```

## 4. Dockerfile的意义，如何帮助实现Docker的各种功能
#### 定义和自动化构建Docker镜像
这一点是Dockerfile的最主要的作用，可以自定义地构建Docker镜像，而不是单一地用docker pull来简单地拉取镜像。自动化是指在构建好dockerfile后可以使用docker build即可完成部署
#### pipeline(流水线)式的构建镜像  
在拉取镜像后可以使用RUN指令进行一系列的操作，因此可以将镜像内的操作提取到原先的镜像配置中，因此有高可移植性
#### 简化Docker各种功能的实现过程
- FROM指令代替docker pull
- CMD指令代替docker run
- 同时包含了docker build功能

## 5. 运行项目
### docker build构建镜像
与用docker pull命令行直接拉取镜像，基于dockerfile的容器构建是使用docker build命令
```bash
docker build .
```
上述代码中，**.**表示当前目录，说明docker会自动根据当前目录下的dockerfile来构建镜像
### docker run运行容器
这点和不使用dockerfile而直接用docker pull拉取镜像一样，都需要docker run来构建镜像
```bash
docker un --name my_container my_image_name
```

## 6. docker基本指令
```bash
/// 使用dockerfile构建镜像
docker build .
/// 列出所有本地镜像 
docker images
/// 删除指定镜像
docker rmi my_image_name
/// 列出所有正在运行中的容器
docker ps
/// 列出所有容器
docker ps -a
/// 启动容器
docker start my_container
/// 停止容器
docker stop my_container
/// 删除容器
docker rm my_container
```