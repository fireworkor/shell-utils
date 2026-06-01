# NFS (网络文件系统)

## 安装

```bash
./nfs/nfs.sh
```

## 管理

使用 nfs-manage.sh 脚本进行配置和管理：

```bash
# 配置 NFS 服务（交互式）
./nfs/nfs-manage.sh config

# 添加 NFS 共享导出
./nfs/nfs-manage.sh add-export <路径> <IP段>

# 移除 NFS 共享导出
./nfs/nfs-manage.sh remove-export <路径>

# 设置默认共享目录
./nfs/nfs-manage.sh set-share-path <路径>

# 列出所有共享导出
./nfs/nfs-manage.sh list-exports

# 显示当前挂载
./nfs/nfs-manage.sh show-mounts

# 查看服务状态
./nfs/nfs-manage.sh status

# 启动/停止/重启/重新加载服务
./nfs/nfs-manage.sh start
./nfs/nfs-manage.sh stop
./nfs/nfs-manage.sh restart
./nfs/nfs-manage.sh reload
```

## 端口

- 2049 - NFS 服务
- 111 - RPC Bind

## 配置文件

- `/etc/exports` - NFS 导出配置文件

## 客户端挂载

### Linux/Mac 客户端
```bash
# 挂载 NFS 共享
mount -t nfs 服务器IP:/data/nfs /mnt/nfs

# 开机自动挂载（编辑 /etc/fstab）
服务器IP:/data/nfs /mnt/nfs nfs defaults 0 0
```

### Windows 客户端
Windows 需要使用 NFS 客户端功能：
1. 在"启用或关闭 Windows 功能"中启用"NFS服务"
2. 使用 `mount 服务器IP:/data/nfs Z:` 命令挂载

## 导出参数说明

- `rw` - 读写权限
- `ro` - 只读权限
- `sync` - 同步写入
- `async` - 异步写入（性能更好，但数据安全性较低）
- `no_root_squash` - 保留 root 用户权限
- `root_squash` - root 用户映射为 anonymous（默认）
- `no_subtree_check` - 不检查子目录（性能更好）

## 说明

- 默认允许所有 IP 访问 (*)
- 默认共享权限：读写
- 支持多个共享导出
