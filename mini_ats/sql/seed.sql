USE mini_ats;

INSERT INTO user_account(username, password_hash, role) VALUES
('orange', 'demo_hash', 'USER'),
('admin', 'demo_hash', 'ADMIN')
ON DUPLICATE KEY UPDATE username=username;

INSERT INTO company(name, city, industry) VALUES
('ByteDance', 'Beijing', 'Internet'),
('Tencent', 'Shenzhen', 'Internet'),
('Xiaomi', 'Beijing', 'Hardware')
ON DUPLICATE KEY UPDATE name=name;

INSERT INTO `position`(company_id, title, level, job_type, location, jd_url) VALUES
(1, 'Java Backend Intern', 'Intern', 'INTERN', 'Beijing', 'https://example.com/jd1'),
(2, 'Data Engineer Intern', 'Intern', 'INTERN', 'Shenzhen', 'https://example.com/jd2'),
(3, 'Backend Engineer', 'Junior', 'FULLTIME', 'Beijing', 'https://example.com/jd3');

INSERT INTO tag(name) VALUES
('内推'),('高优先级'),('需复盘'),('已跟进')
ON DUPLICATE KEY UPDATE name=name;

INSERT INTO application(user_id, position_id, channel, applied_date, current_status, resume_url, remark)
VALUES
(1, 1, 'referral', '2025-12-01', 'APPLIED', 'https://example.com/resumeA', 'first try'),
(1, 2, 'official', '2025-12-02', 'OA', 'https://example.com/resumeA', 'waiting'),
(1, 3, 'headhunter', '2025-12-03', 'APPLIED', 'https://example.com/resumeB', 'prepare');

INSERT IGNORE INTO application_tag(application_id, tag_id) VALUES
(1, 1), (1, 2),
(2, 3),
(3, 4);

INSERT INTO application_note(application_id, note_type, content) VALUES
(1, 'RESUME', '简历版本A，突出Java项目与数据库设计'),
(2, 'OA', 'OA题型：SQL+基础算法；需要复盘错题'),
(1, 'INTERVIEW', '准备自我介绍+项目亮点：事务/触发器/存储过程');

INSERT INTO interview_slot(interviewer, start_time, end_time, room)
VALUES('HR_A', '2025-12-12 10:00:00', '2025-12-12 10:30:00', 'Room-1')
ON DUPLICATE KEY UPDATE room=VALUES(room);

INSERT IGNORE INTO interview(application_id, round_no, slot_id, mode)
SELECT 1, 1, slot_id, 'ONLINE'
FROM interview_slot
WHERE interviewer='HR_A' AND start_time='2025-12-12 10:00:00';

INSERT INTO offer(application_id, salary_k, currency, location, offer_date, decision, note)
VALUES(1, 25, 'CNY', 'Beijing', '2025-12-20', 'PENDING', 'demo offer')
ON DUPLICATE KEY UPDATE note=VALUES(note);

UPDATE application SET current_status='INTERVIEW_SCHEDULED' WHERE application_id=1;