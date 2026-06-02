# Python 编程语言

## 简介
Python 是一个高层次的结合了解释性、编译性、互动性和面向对象的脚本语言，具有简洁的语法和强大的标准库。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8000 | 开发服务器 | `python -m http.server` |

### 主要组件

- **python3** - Python 3 解释器
- **pip3** - 包管理工具
- **venv** - 虚拟环境模块
- **idle** - 集成开发环境
- **pytest** - 测试框架（需安装）

### 访问入口

- **命令行**: `python3 --version`
- **REPL**: `python3`
- **脚本执行**: `python3 script.py`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
python3 --version
pip3 --version
```

### 2. 配置 pip 源（国内推荐）
```bash
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
```

### 3. 创建虚拟环境
```bash
python3 -m venv myproject_env
source myproject_env/bin/activate
pip install requests flask
deactivate
```

### 4. 升级 pip
```bash
pip3 install --upgrade pip
```

### 5. 安装常用工具
```bash
pip3 install requests flask django fastapi uvicorn pytest
```

---

## 详细使用说明

### pip 使用

```bash
pip3 install package_name
pip3 install package_name==1.0.0
pip3 freeze > requirements.txt
pip3 install -r requirements.txt
pip3 install --upgrade package_name
pip3 uninstall package_name
```

### 虚拟环境
```bash
python3 -m venv myenv
source myenv/bin/activate
deactivate
```

### 常用 Web 框架
```bash
# Flask
pip3 install flask
python3 -m flask run --host=0.0.0.0 --port=5000

# FastAPI
pip3 install fastapi uvicorn
uvicorn main:app --host=0.0.0.0 --port=8000
```

---

## 常见问题

### Q: pip 安装慢？
A: 更换国内源

### Q: 虚拟环境激活失败？
A: 检查 source 路径

### Q: 模块找不到？
A: 确认虚拟环境已激活

---

## 后续改进方向

1. 包管理工具（Poetry、PDM）
2. 类型检查（mypy）
3. 代码格式化（black、isort）
4. 性能分析（cProfile、py-spy）
5. 文档生成（Sphinx）
6. 依赖安全（safety、pip-audit）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
