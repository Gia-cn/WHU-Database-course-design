USE mini_ats;
-- 窗口A
CALL sp_schedule_interview(
  2, 4001, 'UNIQ_DEMO2',
  '2025-12-22 16:00:00','2025-12-22 16:30:00',
  'Room-9','ONLINE'
);
-- 窗口B
CALL sp_schedule_interview(
  3, 4001, 'UNIQ_DEMO2',
  '2025-12-22 16:00:00','2025-12-22 16:30:00',
  'Room-9','ONLINE'
);

-- 并发后验证
SELECT * FROM interview_slot WHERE interviewer='UNIQ_DEMO2';
SELECT application_id, round_no, slot_id
FROM interview
WHERE application_id IN (2,3) AND round_no=4001;
