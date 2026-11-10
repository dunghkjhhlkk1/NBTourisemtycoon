# Đánh giá Visual Prototype V0.1

## Asset đã dùng

| Nhóm | Số nguồn | Vai trò |
|---|---:|---|
| Công trình | 5 | Quầy vé, nhà hàng, homestay, bến thuyền, quầy lưu niệm |
| Nhân vật | 7 | Các mẫu khách khác nhau, tối đa 8 khách hiện diện |
| Phương tiện | 2 | Thuyền trống và thuyền có mái |
| Thiên nhiên | 10 | Cây, tre, bụi, đá rêu, sen và lá |
| Đạo cụ | 4 | Biển chỉ đường, chậu hoa, đèn và ghế |
| Địa hình | 10 | 4 sprite đá vôi và 6 tile nguồn để ghép nền |

[Audit asset](ASSET_AUDIT.md) ghi tên tệp, kích thước, alpha và trạng thái của 111 ảnh nguồn.

[Ảnh chụp cảnh Quản lý từ bản Godot đang chạy](prototype-preview.png)

## Nhận xét từ bản dựng

- **Tỷ lệ.** Từng loại công trình có độ rộng hiển thị và footprint trong `data/buildings.json`. Khách hiển thị cao khoảng 35–38 px ở zoom 1 và nhỏ ở chế độ Toàn cảnh. Chế độ Chi tiết phù hợp để so sánh nét viền, cây và dáng nhân vật. Điểm neo được cân theo mép alpha của từng công trình. Chân đế vẽ sẵn vẫn có thể lệch footprint logic và vị trí lối đi ở một số công trình.
- **Góc camera.** Bản đồ giữ một phép chiếu cố định. Các mái nhà nhìn chung tương thích trong cảnh thử, nhưng độ dốc cạnh mái và độ cao nhìn từ trên xuống thay đổi giữa các PNG. Nhân vật và thuyền giữ hướng sprite trong lúc di chuyển. Thuyền chạy một chiều, mờ khi quay lại đầu tuyến, không xoay sprite.
- **Địa hình.** Bản dựng dùng 36 cụm ảnh, mỗi cụm gồm 8 × 8 ô, với lưới 48 × 48 cho đường, nước và footprint. Sông và đường ghép từ texture nguồn. Đã sửa chấm đen ở mép tile bằng lấy mẫu trong vùng màu hợp lệ và dùng ranh giới pixel nguyên. Có thể xây trên đường thử để kiểm tra đổi tuyến. Tuyến khách chỉ dùng các ô đường.
- **Transparency.** PNG được chọn có kênh alpha thật. Không thấy viền trắng lớn ở ảnh chụp Godot. Chế độ Toàn cảnh làm các nét mảnh như đèn và khách nhỏ khó nhận ra.
- **Asset cần làm lại.** Ưu tiên cổng Tràng An, tile đầu đường và ngã ba, các hướng đường và bờ sông, sprite thuyền đổi hướng, bộ đi bộ của nhân vật, và hàng rào gỗ có đầu nối chuẩn. Xe đạp nhìn nghiêng hơn các phương tiện cùng bộ nên chưa dùng. Ba ảnh tham chiếu dùng để duyệt phong cách.
- **Quy chuẩn đợt sau.** Chốt hai trục chiếu và tỷ lệ world theo một thước mẫu chung. Lưu footprint, điểm neo chân đế và vị trí cửa riêng cho từng sprite. Kiểm tra alpha trên hai nền tương phản, thu nhỏ ở ba mức zoom và ghép thử các biến thể tile trước khi duyệt.

## Phạm vi kiểm thử

- **Godot 4.7.2 headless.** Script kiểm tra khởi tạo 5 công trình, chọn theo alpha, kiểm tra giới hạn và overlap, bến thuyền cần bờ, thay tuyến khi có vật cản, báo hết tuyến, xóa để khôi phục tuyến, preview và hủy, waypoint nước, chế độ zoom và số khách.
- **Godot desktop.** Đã khởi chạy Compatibility trên Intel UHD Graphics 610 ở 1280 × 760. Kiểm tra từ viewport bằng sự kiện nhập gồm chọn công trình, mở menu, preview đỏ trên nước và xanh trên đất, đặt và xóa bằng nút, cuộn zoom, kéo chuột giữa và Home. Hai mẫu ngắn ghi 59 và 75 FPS trên desktop.
- **Web.** Đã tạo gói PCK bằng preset Web, lắp với mẫu Web single-thread chính thức 4.7.2 và kiểm tra máy chủ cục bộ trả tệp WASM. Godot .NET trên máy chặn xuất Web trực tiếp, nên gói PCK và mẫu runtime được ghép riêng. Chromium bị chặn khi tạo IPC trên Windows. Trình duyệt trong ứng dụng cũng không mở được tab kiểm thử. Chưa xác nhận game khởi động hoặc tương tác trong trình duyệt, chưa có FPS Web hay số liệu mobile.
- **Chi phí tải.** PCK khoảng 16 MB và WebAssembly khoảng 39,5 MB trước nén HTTP. Nền dùng 36 sprite theo cụm, khách giới hạn ở 8 và tìm tuyến lại khi có thay đổi xây dựng. Cần đo thời gian tải và frame time bằng trình duyệt thật trước khi chốt hiệu năng.
