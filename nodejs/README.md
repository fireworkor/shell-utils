# Node.js 运行环境

## 简介
Node.js 是一个基于 Chrome V8 引擎的 JavaScript 运行时，可以在服务器端运行 JavaScript。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 3000 | Express 默认 | Node.js 应用常用 |
| 8080 | 备用 | 通用端口 |

### 主要组件

- **node** - Node.js 运行时
- **npm** - 包管理器
- **npx** - 包执行器
- **yarn** - 替代包管理器
- **pm2** - 进程管理器
- **nodemon** - 开发热重载

### 访问入口

- **命令行**: `node -v`
- **REPL**: `node`
- **运行脚本**: `node app.js`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
node -v
npm -v
```

### 2. 配置 npm 源
```bash
npm config set registry https://registry.npmmirror.com
```

### 3. 安装常用工具
```bash
npm install -g yarn
npm install -g pm2
npm install -g nodemon
```

### 4. 创建第一个项目
```bash
mkdir myapp && cd myapp
npm init -y
npm install express
```

编辑 `app.js`（添加 Express 监听代码）:
```bash
node app.js
# 访问 http://localhost:3000
```

### 5. 使用 PM2 部署
```bash
pm2 start app.js --name myapp
pm2 startup
pm2 save
```

---

## 详细使用说明

### npm 常用命令
```bash
npm init
npm install <package>
npm install <package> --save-dev
npm install -g <package>
npm uninstall <package>
npm update
npm run <script>
```

### 进程管理（PM2）
```bash
pm2 start app.js
pm2 start app.js --name myapp
pm2 start app.js -i 4    # 4 个实例
pm2 list
pm2 show myapp
pm2 logs
pm2 restart myapp
pm2 stop myapp
pm2 delete myapp
pm2 startup
pm2 save
```

---

## 常见问题

### Q: npm 安装慢？
A: 配置国内镜像源

### Q: 端口被占用？
A: `lsof -i :3000`

### Q: 内存泄漏？
A: 使用 --inspect 调试

---

## 后续改进方向

1. TypeScript 集成
2. Docker 化
3. Nginx 反向代理
4. 日志管理（Winston、Pino）
5. 性能监控（PM2 Plus）
6. CI/CD 自动化部署

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
