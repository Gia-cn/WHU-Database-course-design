from db import fetch_all, exec_one, call_proc

def dashboard(uid: int):
    rows = fetch_all("""
        SELECT * FROM v_app_dashboard
        WHERE user_id = :uid
        ORDER BY updated_at DESC
    """, {"uid": uid})
    print("\n--- Dashboard ---")
    for r in rows:
        print(r)

def add_application(uid: int, pid: int, channel: str, applied_date: str):
    exec_one("""
        INSERT INTO application(user_id, position_id, channel, applied_date, current_status)
        VALUES(:uid, :pid, :ch, :dt, 'APPLIED')
    """, {"uid": uid, "pid": pid, "ch": channel, "dt": applied_date})
    print("OK: application inserted")

def schedule_interview(app_id: int, round_no: int, interviewer: str, start: str, end: str, room: str, mode: str):
    call_proc("sp_schedule_interview", [app_id, round_no, interviewer, start, end, room, mode])
    print("OK: interview scheduled (proc)")

def accept_offer(offer_id: int):
    call_proc("sp_accept_offer", [offer_id])
    print("OK: offer accepted (proc)")

def company_stats():
    rows = fetch_all("SELECT * FROM v_company_stats ORDER BY offered DESC, progressed DESC")
    print("\n--- Company Stats ---")
    for r in rows:
        print(r)

def show_history(app_id: int):
    rows = fetch_all("""
        SELECT history_id, old_status, new_status, changed_at, reason
        FROM application_status_history
        WHERE application_id = :aid
        ORDER BY changed_at DESC
    """, {"aid": app_id})
    print("\n--- Status History ---")
    for r in rows:
        print(r)

def main():
    while True:
        print("\n1 看板  2 新增投递  3 安排面试(存储过程)  4 接受Offer(存储过程)  5 公司统计  6 状态历史  0 退出")
        op = input("选择: ").strip()

        if op == "1":
            dashboard(int(input("user_id: ")))
        elif op == "2":
            add_application(
                int(input("user_id: ")),
                int(input("position_id: ")),
                input("channel: "),
                input("applied_date(YYYY-MM-DD): ")
            )
        elif op == "3":
            schedule_interview(
                int(input("application_id: ")),
                int(input("round_no: ")),
                input("interviewer: "),
                input("start_time(YYYY-MM-DD HH:MM:SS): "),
                input("end_time(YYYY-MM-DD HH:MM:SS): "),
                input("room: "),
                input("mode(ONLINE/ONSITE): ").strip().upper()
            )
        elif op == "4":
            accept_offer(int(input("offer_id: ")))
        elif op == "5":
            company_stats()
        elif op == "6":
            show_history(int(input("application_id: ")))
        elif op == "0":
            break
        else:
            print("无效输入")

if __name__ == "__main__":
    main()