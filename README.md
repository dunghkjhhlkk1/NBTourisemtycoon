# Ninh Bình Tourism Tycoon V0.3

Mở http://localhost:8766/ khi API đang chạy. Cùng một origin phục vụ bản Web và API. Tạo cơ sở dữ liệu PostgreSQL riêng cho demo, đặt biến ConnectionStrings__Tourism rồi chạy từ thư mục backend:

    dotnet run --urls http://localhost:8766

Ứng dụng tự áp dụng EF migration và dữ liệu mẫu. Trong game, vào **Đất & Cơ sở**, thuê Nhà hàng Tràng An, rồi thuê lô A1 để xây cơ sở thứ hai. Xem **Doanh nghiệp** và **Thị trường**.

Mở project.godot trong Godot 4.7.2 để chạy bản editor. Dùng tham số `-- --offline-v02` khi chạy dự án từ dòng lệnh để mở sandbox V0.2.

- [Hướng dẫn V0.3](docs/V0.3_GDD.md)
- [Thiết lập và kiến trúc](docs/V0.3_TDD.md)
- [Kiểm thử](docs/V0.3_TEST_REPORT.md)
- [Kiểm kê asset](docs/ASSET_AUDIT.md)

