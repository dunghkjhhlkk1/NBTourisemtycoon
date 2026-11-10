# PostgreSQL

- Companies giữ vốn dạng numeric và chủ doanh nghiệp.
- Assets giữ ID, chủ đất, loại, vùng, ranh giới, giá thuê và đặt cọc.
- Facilities tham chiếu Assets, giữ chủ công trình, tọa độ, loại, giá, nhân viên, cấp và trạng thái.
- Leases tham chiếu Assets và Companies. Index có điều kiện bảo đảm mỗi tài sản có tối đa một hợp đồng Active.
- Ledger lưu giao dịch UUID, số tiền numeric, kỳ, mã tài sản và khóa chống lặp theo doanh nghiệp.
- Receipts giữ khóa yêu cầu và chữ ký nội dung để phát lại yêu cầu an toàn.
- Markets giữ kỳ đã xử lý và số liệu phân bổ gần nhất.

Business khóa giao dịch PostgreSQL để tuần tự hóa thị trường và lệnh thay đổi tài sản. Số dư, sổ cái và trạng thái nghiệp vụ commit cùng nhau. Migration đầu tiên nằm trong backend/Infrastructure/Initial.cs.

