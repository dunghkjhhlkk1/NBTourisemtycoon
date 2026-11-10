# Mô phỏng du lịch

VisitorController chạy bước cố định 0,1 giây và theo dõi trạng thái từng nhóm. Việc chọn dịch vụ cân nhắc nhu cầu, giá, đường đi, tải phục vụ, thời gian còn lại và ngân sách. Khách mua vé trước khi đi thuyền. Dữ liệu hồ sơ khách và dịch vụ nằm trong data/visitor_types.json và data/services.json.

TourServices quản lý công suất, hàng đợi và phiên phục vụ theo ID công trình. Phí dịch vụ được trừ một lần lúc nhận khách. TourEconomy ghi giao dịch, chi phí và tổng tiền từng ngày. Giao diện đọc số liệu từ mô phỏng. BoatController lấy tiến độ chuyến để vẽ thuyền đi và về.

Đơn vị giá là nghìn đồng. Quầy vé tính giá mỗi người, bến thuyền và nhà hàng cũng tính theo người, homestay tính theo phòng mỗi nhóm. Lương thu mỗi 60 giây mô phỏng. Mỗi bến hiện có một thuyền ba chỗ và một vị trí người chèo. Nhân viên ở công trình khác tăng số nhóm hoặc chỗ phục vụ. Tuyển và phân công là một thao tác. Khi đường về bị chặn hoàn toàn, nhóm được kết thúc với đánh giá thấp để tránh kẹt. Reset Demo khởi tạo lại toàn bộ phiên, dữ liệu phiên nằm trong bộ nhớ.

