# vsftpd (FTP 服务器)

## 安装

```bash
./ftp/ftp.sh
```

## 管理

使用 ftp-manage.sh 脚本进行配置和管理：

```bash
# 配置 FTP 服务（交互式）
./ftp/ftp-manage.sh config

# 添加 FTP 用户
./ftp/ftp-manage.sh add-user <用户名>

# 设置共享目录
./ftp/ftp-manage.sh set-share <路径>

# 查看服务状态
./ftp/ftp-manage.sh status

# 启动/停止/重启服务
./ftp/ftp-manage.sh start
./ftp/ftp-manage.sh stop
./ftp/ftp-manage.sh restart
```

## 端口

- 21 - FTP 控制端口
- 40000-40100 - FTP 被动模式数据端口

## 配置文件

- `/etc/vsftpd/vsftpd.conf` - vsftpd 主配置文件

## 说明

- 默认禁止匿名访问
- 用户默认被 chroot 到共享目录
- 支持被动模式访问
