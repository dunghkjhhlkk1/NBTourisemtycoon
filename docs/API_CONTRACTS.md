# API nội bộ V0.3

- GET /api/session cấp token demo trên loopback.
- GET /api/state trả doanh nghiệp, lô, cơ sở, hợp đồng, báo cáo, thị trường và sổ giao dịch gần nhất.
- POST /api/actions nhận key UUID, action, target và tùy lệnh có kind, x, y, value. Actions gồm lease, pay, renew, end, build, price, staff, upgrade và open.

State và actions yêu cầu Bearer token. Quy tắc nghiệp vụ bị vi phạm trả 409 kèm message. Retry cùng key và nội dung đã commit không tính tiền lần nữa. Server xác định chi phí, thời hạn và doanh thu.

