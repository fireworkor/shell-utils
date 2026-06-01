# =========================================
# Nginx 常用配置示例
# =========================================
# 这些配置文件示例用于参考，请根据实际情况修改
# 配置文件目录: /etc/nginx/conf.d/ 或 /etc/nginx/sites-available/
# =========================================

配置示例列表:
─────────────────────────────────────────

1. static-site.conf          - 静态网站配置
2. reverse-proxy.conf         - 反向代理配置
3. load-balancer.conf         - 负载均衡配置
4. ssl-site.conf              - HTTPS + SSL配置
5. php-fastcgi.conf           - PHP-FPM配置
6. wordpress.conf             - WordPress配置
7. nodejs-proxy.conf          - Node.js反向代理
8. cache.conf                 - 静态资源缓存配置
9. rate-limit.conf            - 限流配置
10. security.conf             - 安全加固配置
11. mirror.conf               - 流量复制配置（生产环境流量复制到测试环境）

─────────────────────────────────────────

使用方法:
# 将需要的配置复制到 /etc/nginx/conf.d/
# 修改 server_name, root, proxy_pass 等参数
# nginx -t && systemctl reload nginx
