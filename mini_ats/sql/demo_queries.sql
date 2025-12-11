USE mini_ats;

-- 条件查询与排序
SELECT * FROM application
WHERE user_id=1 AND current_status IN ('APPLIED','OA')
ORDER BY applied_date DESC;
-- 多表连接与分组统计
SELECT c.name AS company_name, COUNT(*) AS cnt
FROM application a
JOIN `position` p ON a.position_id=p.position_id
JOIN company c ON p.company_id=c.company_id
GROUP BY c.name
ORDER BY cnt DESC;

-- 1.投递看板
SELECT * FROM v_app_dashboard WHERE user_id=1;
-- 2.公司统计
SELECT * FROM v_company_stats;
-- 3.漏斗统计
SELECT * FROM v_funnel_user;


-- 1.触发器列表
SHOW TRIGGERS;
-- 2.触发器效果
UPDATE application SET current_status='OA' WHERE application_id=3;
SELECT * FROM application_status_history ORDER BY changed_at DESC;

-- 1.存储过程列表
SHOW PROCEDURE STATUS WHERE Db='mini_ats';
-- 2.调用存储过程
CALL sp_schedule_interview(
  2, 9001, 'HR_SHOT',
  '2025-12-24 10:00:00','2025-12-24 10:30:00',
  'Room-1','ONLINE'
);

-- 用户与权限
-- 在 MySQL 命令行执行：SOURCE D:/PostFiles/mini_ats/sql/grand.sql;
SELECT user, host 
FROM mysql.user 
WHERE user IN ('ats_admin','ats_app');