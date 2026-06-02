# Java 开发环境

## 简介
Java 是一门面向对象编程语言，不仅吸收了 C++ 语言的各种优点，还摒弃了 C++ 里难以理解的多继承、指针等概念。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8080 | Tomcat | Java Web 应用 |
| 9000 | JMX | Java 管理扩展 |

### 主要组件

- **java** - Java 运行时
- **javac** - Java 编译器
- **jar** - JAR 打包工具
- **javadoc** - 文档生成
- **jstack** - 线程分析
- **jmap** - 内存分析
- **jconsole** - 图形化监控

### 访问入口

- **命令行**: `java -version`
- **编译**: `javac Hello.java`
- **运行**: `java Hello`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
java -version
javac -version
echo $JAVA_HOME
```

### 2. 设置 JAVA_HOME
```bash
readlink -f $(which java) | sed 's:/bin/java::'
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

### 3. 安装 Maven
```bash
sudo apt install maven    # Ubuntu
sudo yum install maven    # CentOS
mvn -version
```

### 4. 第一个程序
```bash
cat > Hello.java << 'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
EOF
javac Hello.java
java Hello
```

---

## 详细使用说明

### 编译运行
```bash
javac MyApp.java
javac -d build/ src/com/example/*.java
java -cp . MyApp
java -cp .:lib/* MyApp
```

### JAR 打包
```bash
jar cf myapp.jar -C build/ .
java -jar myapp.jar
jar tf myapp.jar
```

### Maven 使用
```bash
mvn archetype:generate -DgroupId=com.example -DartifactId=myapp
mvn compile
mvn package
mvn clean
mvn test
```

### 性能调优
```bash
java -Xms512m -Xmx2g -jar myapp.jar
java -Xlog:gc* -jar myapp.jar
```

---

## 常见问题

### Q: JAVA_HOME 未设置？
A: 参考首次安装后必做设置的步骤 2

### Q: 类找不到？
A: 检查 -classpath 参数

### Q: OutOfMemoryError？
A: 调整 -Xmx 参数

---

## 后续改进方向

1. 构建工具（Gradle）
2. 微服务（Spring Boot）
3. 容器化（Docker + K8s）
4. 监控（Micrometer + Prometheus）
5. 性能分析（JProfiler）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
