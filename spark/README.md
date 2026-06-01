# Spark

## 简介
Apache Spark 是用于大规模数据处理的统一分析引擎。

## 端口信息
- Master Web UI: 8080
- Worker Web UI: 8081 (默认)
- Application UI: 4040 (运行时)

## 使用命令

```bash
# 单机模式部署
bash spark.sh local

# Standalone 模式部署
bash spark.sh standalone

# 启动停止
bash spark.sh stop
bash spark.sh status
```

## 环境变量
```bash
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
```

## 常用命令
```bash
spark-shell          # Scala shell
spark-submit         # 提交作业
pyspark              # Python shell
```
