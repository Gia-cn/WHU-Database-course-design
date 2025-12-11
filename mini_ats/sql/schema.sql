CREATE DATABASE IF NOT EXISTS mini_ats
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE mini_ats;

-- 1) 用户
CREATE TABLE IF NOT EXISTS user_account (
  user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('USER','ADMIN') NOT NULL DEFAULT 'USER',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2) 公司
CREATE TABLE IF NOT EXISTS company (
  company_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL UNIQUE,
  city VARCHAR(60),
  industry VARCHAR(60),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3) 岗位
CREATE TABLE IF NOT EXISTS `position` (
  position_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  company_id BIGINT NOT NULL,
  title VARCHAR(120) NOT NULL,
  level VARCHAR(60),
  job_type ENUM('FULLTIME','INTERN','PARTTIME') NOT NULL DEFAULT 'INTERN',
  location VARCHAR(120),
  jd_url VARCHAR(255),
  status ENUM('OPEN','CLOSED') NOT NULL DEFAULT 'OPEN',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_position_company FOREIGN KEY (company_id) REFERENCES company(company_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_position_company(company_id),
  INDEX idx_position_title(title)
) ENGINE=InnoDB;

-- 4) 标签
CREATE TABLE IF NOT EXISTS tag (
  tag_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(40) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 5) 投递
CREATE TABLE IF NOT EXISTS application (
  application_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  position_id BIGINT NOT NULL,
  channel VARCHAR(60),
  applied_date DATE NOT NULL,
  current_status ENUM(
    'DRAFT',
    'APPLIED',
    'OA',
    'INTERVIEW_SCHEDULED',
    'INTERVIEWING',
    'OFFERED',
    'REJECTED',
    'WITHDRAWN',
    'CLOSED'
  ) NOT NULL DEFAULT 'APPLIED',
  resume_url VARCHAR(255),
  remark VARCHAR(255),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_app_user FOREIGN KEY (user_id) REFERENCES user_account(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_app_position FOREIGN KEY (position_id) REFERENCES `position`(position_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_app_user(user_id),
  INDEX idx_app_status(current_status),
  INDEX idx_app_applied_date(applied_date),
  UNIQUE KEY uq_user_position_date(user_id, position_id, applied_date)
) ENGINE=InnoDB;

-- 6) 投递-标签（M:N 中间表）
CREATE TABLE IF NOT EXISTS application_tag (
  application_id BIGINT NOT NULL,
  tag_id BIGINT NOT NULL,
  PRIMARY KEY (application_id, tag_id),
  CONSTRAINT fk_at_app FOREIGN KEY (application_id) REFERENCES application(application_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_at_tag FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
    ON DELETE RESTRICT,
  INDEX idx_at_tag(tag_id)
) ENGINE=InnoDB;

-- 7) 投递笔记
CREATE TABLE IF NOT EXISTS application_note (
  note_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  note_type ENUM('RESUME','OA','INTERVIEW','HR','OFFER','GENERAL') NOT NULL DEFAULT 'GENERAL',
  content TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_note_app FOREIGN KEY (application_id) REFERENCES application(application_id)
    ON DELETE CASCADE,
  INDEX idx_note_app(application_id)
) ENGINE=InnoDB;

-- 8) 状态历史（审计）
CREATE TABLE IF NOT EXISTS application_status_history (
  history_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  old_status ENUM(
    'DRAFT','APPLIED','OA','INTERVIEW_SCHEDULED','INTERVIEWING','OFFERED',
    'REJECTED','WITHDRAWN','CLOSED'
  ),
  new_status ENUM(
    'DRAFT','APPLIED','OA','INTERVIEW_SCHEDULED','INTERVIEWING','OFFERED',
    'REJECTED','WITHDRAWN','CLOSED'
  ) NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  changed_by BIGINT,
  reason VARCHAR(255),
  CONSTRAINT fk_hist_app FOREIGN KEY (application_id) REFERENCES application(application_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_hist_user FOREIGN KEY (changed_by) REFERENCES user_account(user_id)
    ON DELETE SET NULL,
  INDEX idx_hist_app(application_id),
  INDEX idx_hist_time(changed_at)
) ENGINE=InnoDB;

-- 9) 面试时间段
CREATE TABLE IF NOT EXISTS interview_slot (
  slot_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  interviewer VARCHAR(80) NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  room VARCHAR(60),
  UNIQUE KEY uq_interviewer_start(interviewer, start_time),
  CHECK (end_time > start_time),
  INDEX idx_slot_time(start_time, end_time)
) ENGINE=InnoDB;

-- 10) 面试：一个 slot 只能被一场面试占用
CREATE TABLE IF NOT EXISTS interview (
  interview_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  round_no INT NOT NULL,
  slot_id BIGINT NOT NULL,
  mode ENUM('ONLINE','ONSITE') NOT NULL DEFAULT 'ONLINE',
  result ENUM('PENDING','PASS','FAIL') NOT NULL DEFAULT 'PENDING',
  feedback VARCHAR(255),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_iv_app FOREIGN KEY (application_id) REFERENCES application(application_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_iv_slot FOREIGN KEY (slot_id) REFERENCES interview_slot(slot_id)
    ON DELETE RESTRICT,
  UNIQUE KEY uq_app_round(application_id, round_no),
  UNIQUE KEY uq_slot_unique(slot_id),
  INDEX idx_iv_app(application_id)
) ENGINE=InnoDB;

-- 11) Offer：投递-Offer 1:0..1
CREATE TABLE IF NOT EXISTS offer (
  offer_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL UNIQUE,
  salary_k INT,
  currency VARCHAR(10) DEFAULT 'CNY',
  location VARCHAR(120),
  offer_date DATE NOT NULL,
  decision ENUM('PENDING','ACCEPTED','DECLINED') NOT NULL DEFAULT 'PENDING',
  decided_at DATETIME,
  note VARCHAR(255),
  CONSTRAINT fk_offer_app FOREIGN KEY (application_id) REFERENCES application(application_id)
    ON DELETE CASCADE,
  INDEX idx_offer_date(offer_date)
) ENGINE=InnoDB;

-- =========================
-- 视图（3个）
-- =========================
CREATE OR REPLACE VIEW v_app_dashboard AS
SELECT
  a.application_id,
  a.user_id,
  c.name AS company_name,
  p.title AS position_title,
  a.channel,
  a.applied_date,
  a.current_status,
  a.updated_at
FROM application a
JOIN `position` p ON a.position_id = p.position_id
JOIN company c ON p.company_id = c.company_id;

CREATE OR REPLACE VIEW v_funnel_user AS
SELECT
  user_id,
  SUM(current_status='APPLIED') AS cnt_applied,
  SUM(current_status='OA') AS cnt_oa,
  SUM(current_status IN ('INTERVIEW_SCHEDULED','INTERVIEWING')) AS cnt_interview,
  SUM(current_status='OFFERED') AS cnt_offered,
  SUM(current_status='REJECTED') AS cnt_rejected
FROM application
GROUP BY user_id;

CREATE OR REPLACE VIEW v_company_stats AS
SELECT
  c.company_id,
  c.name AS company_name,
  COUNT(*) AS total_apps,
  SUM(a.current_status IN ('INTERVIEW_SCHEDULED','INTERVIEWING','OFFERED')) AS progressed,
  SUM(a.current_status='OFFERED') AS offered,
  SUM(a.current_status='REJECTED') AS rejected
FROM application a
JOIN `position` p ON a.position_id=p.position_id
JOIN company c ON p.company_id=c.company_id
GROUP BY c.company_id, c.name;

-- =========================
-- 触发器（2个）
-- =========================
DELIMITER $$

CREATE TRIGGER trg_app_status_history
AFTER UPDATE ON application
FOR EACH ROW
BEGIN
  IF NEW.current_status <> OLD.current_status THEN
    INSERT INTO application_status_history(application_id, old_status, new_status, changed_by, reason)
    VALUES (NEW.application_id, OLD.current_status, NEW.current_status, NEW.user_id, 'status updated');
  END IF;
END$$

CREATE TRIGGER trg_interview_push_status
AFTER INSERT ON interview
FOR EACH ROW
BEGIN
  UPDATE application
  SET current_status = CASE
    WHEN current_status IN ('APPLIED','OA','INTERVIEW_SCHEDULED') THEN 'INTERVIEWING'
    ELSE current_status
  END
  WHERE application_id = NEW.application_id;
END$$

DELIMITER ;

-- =========================
-- 存储过程（3个）
-- =========================
DELIMITER $$

CREATE PROCEDURE sp_submit_application(
  IN p_user_id BIGINT,
  IN p_position_id BIGINT,
  IN p_channel VARCHAR(60),
  IN p_applied_date DATE,
  IN p_resume_url VARCHAR(255),
  IN p_remark VARCHAR(255)
)
BEGIN
  INSERT INTO application(user_id, position_id, channel, applied_date, current_status, resume_url, remark)
  VALUES(p_user_id, p_position_id, p_channel, p_applied_date, 'APPLIED', p_resume_url, p_remark);
END$$

CREATE PROCEDURE sp_schedule_interview(
  IN p_application_id BIGINT,
  IN p_round_no INT,
  IN p_interviewer VARCHAR(80),
  IN p_start DATETIME,
  IN p_end DATETIME,
  IN p_room VARCHAR(60),
  IN p_mode VARCHAR(10)
)
BEGIN
  DECLARE v_slot_id BIGINT;

  START TRANSACTION;

  SELECT slot_id INTO v_slot_id
  FROM interview_slot
  WHERE interviewer = p_interviewer AND start_time = p_start
  FOR UPDATE;

  IF v_slot_id IS NULL THEN
    INSERT INTO interview_slot(interviewer, start_time, end_time, room)
    VALUES(p_interviewer, p_start, p_end, p_room);
    SET v_slot_id = LAST_INSERT_ID();
  END IF;

  INSERT INTO interview(application_id, round_no, slot_id, mode)
  VALUES(p_application_id, p_round_no, v_slot_id,
         CASE WHEN p_mode='ONSITE' THEN 'ONSITE' ELSE 'ONLINE' END);

  UPDATE application
  SET current_status = 'INTERVIEW_SCHEDULED'
  WHERE application_id = p_application_id
    AND current_status IN ('APPLIED','OA','INTERVIEWING');

  COMMIT;
END$$

CREATE PROCEDURE sp_accept_offer(
  IN p_offer_id BIGINT
)
BEGIN
  DECLARE v_app_id BIGINT;
  DECLARE v_user_id BIGINT;

  START TRANSACTION;

  SELECT application_id INTO v_app_id
  FROM offer
  WHERE offer_id = p_offer_id
  FOR UPDATE;

  SELECT user_id INTO v_user_id
  FROM application
  WHERE application_id = v_app_id
  FOR UPDATE;

  UPDATE offer
  SET decision='ACCEPTED', decided_at=NOW()
  WHERE offer_id = p_offer_id AND decision='PENDING';

  UPDATE application
  SET current_status='CLOSED'
  WHERE application_id = v_app_id;

  UPDATE application
  SET current_status='CLOSED'
  WHERE user_id = v_user_id AND application_id <> v_app_id
    AND current_status NOT IN ('REJECTED','WITHDRAWN','CLOSED');

  COMMIT;
END$$

DELIMITER ;