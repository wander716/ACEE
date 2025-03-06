## 网络架构设计
```bash

            Stub2(AS65102)
                    |
                    |                      
Stub1(AS65101)--Transit1  -- Transit2  --Stub5(AS65105)   
                (AS65001)   (AS65002)
                    |            |
                    |            |
            Stub3(AS65103)   Stub4(AS65104)


```
## 具体网络分配
### Stub AS
#### Stub Router
每个Stub AS内部有一个路由器容器，负责与Transit AS的路由器交换BGP路由。
每个Stub AS的路由器又有两个接口，一个连接到Transit网络，另一个连接到Stub内部网络
下面以docker-compose中的stub1为例
```bash
stub1_router:
    build: .
    networks:
      transit_net:
        ipv4_address: 10.254.0.101
      stub1_net:
        ipv4_address: 10.1.1.254
    volumes:
      - ./config/stub1/bird.conf:/etc/bird/bird.conf
    cap_add: ["NET_ADMIN"]
    privileged: true

```
由代码可知10.254.0.101是连接transit stub的接口，10.1.1.254是连接stub内各容器的接口。
其中volumes卷的配置是为了使用bird进行bgp路由配置

#### Stub Node
Stub Node是Stub AS内部的其他容器，这里我们使用了ubuntu容器，它们通过Stub Router再经过Transit中转来访问其他AS内的容器。


### Transit AS
#### Transit Router
Transit AS的路由器连接多个Stub AS，负责中转BGP流量。
这里以transit1为例
```bash
  transit1_router:
    build: .
    networks:
      transit_net:
        ipv4_address: 10.254.0.2
    volumes:
      - ./config/transit1/bird.conf:/etc/bird/bird.conf
    cap_add: ["NET_ADMIN"]
    privileged: true
```
上述代码说明了**10.254.0.2**是Transit Router在Transit网络中的ip地址
volumes为transit使用bird进行BGP路由配置

## BIRD（BIRD Internet Routing Daemon）
通过翻阅BIRD官网**https://bird.network.cz/**，我学习到BIRD用于互联网路由，也就是说它在互联网类型中的网络中充当动态路由器，从而实现在互联网中的各个IP之间互相转发数据包，从而实现网络结构。因为BIRD支持BGP（边界网关协议），因此对于在这里我们使用BIRD来搭建AS之间的连接。
#### 安装BIRD
我们在ubuntu容器中安装并使用BIRD，因此我们在dockerfile中使用RUN指令来安装BIRD
```bash
RUN apt-get update && \
    apt-get install -y bird
```
#### 运行BIRD
查阅官方资料中的用户手册我们得知，可以使用command-line options来自定义地运行BIRD，然后我们使用dockerfile中的CMD使得容器在运行的时候就自动启动BIRD服务
```bash
/// 指定/etc/bird/bird.conf为配置文件
CMD [ "bird", "-d", "-c", "/etc/bird/bird.conf" ]
```
#### BIRD BGP
##### 官方资料中的bgp protocol配置例子
```bash
protocol bgp {
        local as 65000;                      # Use a private AS number
        neighbor 198.51.100.130 as 64496;    # Our neighbor ...
        multihop;                            # ... which is connected indirectly
        export filter {                      # We use non-trivial export rules
                if source = RTS_STATIC then { # Export only static routes
                        # Assign our community
                        bgp_community.add((65000,64501));
                        # Artificially increase path length
                        # by advertising local AS number twice
                        if bgp_path ~ [= 65000 =] then
                                bgp_path.prepend(65000);
                        accept;
    
                reject;
        };
        import all;
        source address 198.51.100.14;   # Use a non-standard source address
}
```
从中我们学习到：
- local as  
指定本地AS号
- neighbor  
指定BGP邻居及其AS号
- export 
导出BGP路由
- import  
导入BGP路由
- filter  
可以自定义BGP允许导出或导入的路由信息

##### 接下来我们配置自己的BGP
###### 1. Stub的BGP配置
```bash

# Configure BIRD for stub1

# 设置 Router ID
router id 10.1.1.254;

# 定义BGP路由
protocol bgp {
    local as 65101;  
    neighbor 10.254.0.2 as 65001;  

    import filter {
    
        if net = 10.1.1.0/24 then accept;
        reject;  
    };
    export all;
}


```
这里我们指定了当前自治系统Stub1（AS65101），然后定义了BGP邻居，10.254.0.2，也就是连接到的Transit1路由器(AS65001)
我们使用import all和export all允许BGP邻居和本AS之间能够传送所有路由信息
在import filter函数中我们定义了BGP允许接收的路由信息，**if net = 10.1.1.0/24 then accept**表示允许从BGP邻居(Transit1路由器)导入10.1.1.0/24网段的路由，也就是说允许Stub1自己的子网流量通过，从而使得Stub1网络中的各个node节点能够通过Stub1路由器连接到Transit1
其他Stub的配置类似，不再赘述

###### 2. Transit的BGP配置
```bash
# Configure BIRD for transit1
# 设置 Router ID
router id 10.254.0.2;

# 连接到 10.254.0.3 (AS 65002)
protocol bgp transit2 {
    local as 65001;
    neighbor 10.254.0.3 as 65002;
    import all;
    export all;
}

# 连接到 10.254.0.101 (AS 65101)
protocol bgp stub1 {
    local as 65001;
    neighbor 10.254.0.101 as 65101;
    import filter{
    if(net = 10.1.1.0/24)
    then accept;
    reject;
    };
    export all;
}

# 连接到 10.254.0.102 (AS 65102)
protocol bgp stub2 {
    local as 65001;
    neighbor 10.254.0.102 as 65102;
    import filter{
        if(net = 10.1.2.0/24) then accept;
        reject;
    };
    export all;
}

# 连接到 10.254.0.103 (AS 65103)
protocol bgp stub3 {
    local as 65001;
    neighbor 10.254.0.103 as 65103;
    import filter{
        if(net = 10.1.3.0/24) then accept;
        reject;
    };
    export all;
}


```

我们给transit1路由器配置了四个bgp protocol，第一个bgp配置用于和transit2之间的连接。
后面三个bgp配用于和三个Stub路由器之间的路由信息交换。并且使用了import filter来精准地进行路由过滤，例如stub1 bgp只接收来自10.1.1.0/24，也就是Stub1的网络。