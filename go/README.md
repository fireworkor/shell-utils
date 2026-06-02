# Go 编程语言

## 简介
Go（又称 Golang）是 Google 开发的一种静态强类型、编译型语言，有自动垃圾回收、并发机制简单等特性。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8080 | Web 应用 | 通用 HTTP |

### 主要组件

- **go** - Go 编译器
- **gofmt** - 代码格式化
- **go mod** - 依赖管理
- **go test** - 单元测试
- **go build** - 编译
- **go run** - 运行

### 访问入口

- **命令行**: `go version`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
go version
```

### 2. 配置 Go Modules
```bash
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.bashrc
source ~/.bashrc
```

### 3. 第一个项目
```bash
mkdir hello && cd hello
go mod init hello
# 创建 main.go
go run main.go
go build -o hello
./hello
```

---

## 详细使用说明

### 模块管理
```bash
go mod init myproject
go get github.com/gin-gonic/gin
go mod tidy
go mod download
```

### 构建运行
```bash
go run main.go
go build
go build -o myapp
go build -ldflags="-s -w" -o myapp
GOOS=linux GOARCH=amd64 go build -o myapp-linux
```

### 常用框架
```bash
go get -u github.com/gin-gonic/gin
# 编写 main.go 启动 Gin
```

---

## 常见问题

### Q: go get 失败？
A: 配置 GOPROXY 代理

### Q: 编译慢？
A: `go env -w GOCACHE=~/.cache/go-build`

### Q: 减小二进制？
A: `-ldflags="-s -w"` 和 UPX 压缩

---

## 后续改进方向

1. Web 框架（Gin、Echo、Fiber）
2. ORM（GORM、Ent）
3. 微服务（gRPC、go-kit）
4. 容器化（Docker + K8s）
5. 监控（Prometheus 客户端）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
