# 基于 MySQL 的求职投递与面试流程管理系统（Mini ATS）  
whu本科数据库结课项目

演示视频地址：[数据库项目——基于 MySQL 的求职投递与面试流程管理系统（Mini ATS）-哔哩哔哩](https://b23.tv/zmqhEvz)
说明：因为听信了gpt的谗言，时间比较仓促，一天手搓，来不及做前端了

选题比较新颖（不是学校里常见的图书/外卖/物流三件套）

**star免费，但能让主包开心好久，支持伟大开源精神！！**

## 📖项目介绍
系统面向个人求职管理场景，覆盖公司、岗位、投递、面试与 Offer 全流程。

核心业务流程为：创建公司与岗位 → 新增投递 → 状态跟踪（投递/OA/面试/Offer）→ 安排面试 → 接受 Offer 并自动收束其他投递 → 统计分析（看板与漏斗）。

## 💻运行环境
- MySQL 9.3
- Python 3.11
- SQLAlchemy + PyMySQL  
（如遇 MySQL 9.3 认证报错，需安装 `cryptography`）

## 📂目录结构
- app.py：Python 命令行入口
- db.py：数据库连接与通用操作封装
- requirements.txt：依赖
- sql/
  - schema.sql：建表/索引/视图/触发器/存储过程
  - seed.sql：演示数据
  - demo_queries.sql：演示查询
  - concurrency_demo.sql：并发/事务演示
  - grant.sql：用户与权限

## 🚀启动
在 MySQL 命令行执行：
```sql
CREATE DATABASE IF NOT EXISTS mini_ats DEFAULT CHARSET utf8mb4;
USE mini_ats;
SOURCE D:/PostFiles/mini_ats/sql/schema.sql;
SOURCE D:/PostFiles/mini_ats/sql/seed.sql;
```

安装依赖：
```bash
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple cryptography
```

## ⚙核心功能
- 视图：看板/统计（v_app_dashboard、v_company_stats、v_funnel_user）
- 触发器：状态历史审计（application_status_history）
- 存储过程：安排面试/接受 Offer（sp_schedule_interview、sp_accept_offer）
- 事务与并发：唯一约束 + 过程内事务控制

## 💾备份
在 Windows CMD 执行（不是 mysql>）：
```bash
mysqldump -uroot -p --databases mini_ats --routines --triggers --events > mini_ats_backup.sql
dir mini_ats_backup.sql
```
