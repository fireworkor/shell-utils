# Samba (文件共享服务)

## 安装

```bash
./samba/samba.sh
```

## 管理

使用 samba-manage.sh 脚本进行配置和管理：

```bash
# 配置 Samba 服务（交互式）
./samba/samba-manage.sh config

# 添加 Samba 用户
./samba/samba-manage.sh add-user <用户名>

# 设置共享目录
./samba/samba-manage.sh set-share-path <路径>

# 添加新的共享
./samba/samba-manage.sh add-share <共享名>

# 列出所有共享
./samba/samba-manage.sh list-shares

# 查看服务状态
./samba/samba-manage.sh status

# 启动/停止/重启服务
./samba/samba-manage.sh start
./samba/samba-manage.sh stop
./samba/samba-manage.sh restart
```

## 端口

- 139 - NetBIOS 会话服务
- 445 - SMB over TCP

## 配置文件

- `/etc/samba/smb.conf` - Samba 主配置文件

## 访问方式

### Windows
```
\\服务器IP\data
```

### Linux/Mac
```bash
smbclient //服务器IP/data -U 用户名
# 或者挂载
mount -t cifs //服务器IP/data /mnt/share -o username=用户名
```

## 说明

- 默认共享组：sambashare
- 默认共享名：data
- 用户需要同时是系统用户和 Samba 用户
