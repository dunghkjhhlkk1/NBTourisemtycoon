# Audit asset — Visual Prototype V0.1

Đã quét 100 PNG V2.1, 8 PNG V1 và 3 ảnh tham chiếu. ZIP cũ là bản lưu trữ trùng thế hệ. Bảng dưới ghi kích thước, alpha và bbox tại ngưỡng alpha 32. PASS là đạt kiểm tra tĩnh cho vai trò ghi trong tên. Kiểm tra này kết hợp số liệu với ảnh thu nhỏ trên nền xanh xám. Bbox chạm mép với tile là chủ ý của phép chiếu.

## Nhận xét

- Công trình V1, bến thuyền và quầy lưu niệm V2.1 được chọn. Hướng mặt tiền tương thích ở mức prototype. Độ rộng hiển thị và điểm neo được hiệu chỉnh theo từng loại. Kích thước PNG không đại diện cho kích thước trong thế giới.
- Bộ nhân vật có chênh tỷ lệ đầu và hướng nhìn. Prototype chuẩn hóa chiều cao hiển thị khoảng 33–39 px ở zoom 1 và dùng dáng tĩnh. Nhân vật đổi hướng đi theo lưới nhưng giữ góc sprite.
- Cây non, vách đá, sen và đạo cụ phải đặt scale riêng. Tán cây lớn và vách đá cao có thể che lối đi nên bố trí ở rìa.
- Các sprite sản xuất có nền alpha. Hai hàng rào gỗ có độ dày cọc và điểm ghép chưa đồng nhất. Xe đạp có góc cạnh bên rõ hơn các phương tiện còn lại. Các đường góc/giao và bờ sông góc thiếu biến thể hướng để dùng trực tiếp như autotile hoàn chỉnh.
- Ba ảnh concept có nền đặc và nhiều đối tượng, được loại khỏi gameplay.
- Lưới 48×48 dùng hai trục chiếu (72, -24) và (56, 40). Nền kết hợp các texture cỏ, nước, đường đá và bờ sông thật thành 36 cụm từ lưới. Không dùng ảnh cảnh tổng. Các cụm không phải bộ TileSet autotile để tái sử dụng cho map khác.

## MISSING

- Sprite cổng Tràng An riêng. Cảnh dùng lối vào bằng biển chỉ đường và đường lát đá.
- Sprite đi bộ và các hướng nhân vật. Thuyền thiếu hướng ngược và hướng cua.
- Tile đầu đường, ngã ba, hướng đường thẳng còn lại, các biến thể xoay cho góc đường và bờ sông.
- Bộ sprite UI riêng. Prototype dùng Control và theme GDScript.

## Danh mục

| Tệp | Nhóm | Kích thước | Mode / alpha | Bbox | Trạng thái | Dùng |
|---|---|---:|---|---|---|---|

| `game/assets/buildings/commercial/building_bicycle_rental.png` | buildings | 512×512 | RGBA / 0–255 | [20, 104, 491, 408] | PASS | — |
| `game/assets/buildings/commercial/building_boat_station_lv1.png` | buildings | 1024×1024 | RGBA / 0–255 | [42, 108, 983, 915] | PASS | Có |
| `game/assets/buildings/commercial/building_bungalow.png` | buildings | 512×512 | RGBA / 0–255 | [20, 48, 491, 464] | PASS | — |
| `game/assets/buildings/commercial/building_coffee_shop_lv1.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 143, 983, 881] | PASS | — |
| `game/assets/buildings/commercial/building_drink_stall.png` | buildings | 512×512 | RGBA / 0–255 | [20, 91, 491, 420] | PASS | — |
| `game/assets/buildings/commercial/building_ecolodge.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 277, 983, 746] | PASS | — |
| `game/assets/buildings/commercial/building_food_court.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 315, 983, 709] | PASS | — |
| `game/assets/buildings/commercial/building_grocery_shop.png` | buildings | 512×512 | RGBA / 0–255 | [20, 130, 491, 381] | PASS | — |
| `game/assets/buildings/commercial/building_handicraft_shop.png` | buildings | 512×512 | RGBA / 0–255 | [20, 72, 491, 440] | PASS | — |
| `game/assets/buildings/commercial/building_laundry_service.png` | buildings | 512×512 | RGBA / 0–255 | [20, 103, 491, 408] | PASS | — |
| `game/assets/buildings/commercial/building_local_food_stall.png` | buildings | 512×512 | RGBA / 0–255 | [20, 41, 491, 470] | PASS | — |
| `game/assets/buildings/commercial/building_market_stall.png` | buildings | 512×512 | RGBA / 0–255 | [20, 124, 491, 388] | PASS | — |
| `game/assets/buildings/commercial/building_motorbike_rental.png` | buildings | 512×512 | RGBA / 0–255 | [20, 107, 491, 405] | PASS | — |
| `game/assets/buildings/commercial/building_photo_service.png` | buildings | 512×512 | RGBA / 0–255 | [20, 32, 491, 480] | PASS | — |
| `game/assets/buildings/commercial/building_small_guesthouse.png` | buildings | 1024×1024 | RGBA / 0–255 | [77, 41, 947, 983] | PASS | — |
| `game/assets/buildings/commercial/building_souvenir_shop.png` | buildings | 512×512 | RGBA / 0–255 | [20, 109, 491, 403] | PASS | Có |
| `game/assets/buildings/commercial/building_specialty_shop.png` | buildings | 512×512 | RGBA / 0–255 | [90, 20, 422, 491] | PASS | — |
| `game/assets/buildings/commercial/building_ticket_office_large.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 309, 983, 714] | PASS | — |
| `game/assets/buildings/commercial/building_tour_guide_office.png` | buildings | 512×512 | RGBA / 0–255 | [34, 20, 477, 491] | PASS | — |
| `game/assets/buildings/commercial/building_tourism_information.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 205, 983, 818] | PASS | — |
| `game/assets/buildings/infrastructure/building_bus_stop.png` | buildings | 512×512 | RGBA / 0–255 | [20, 67, 491, 444] | PASS | — |
| `game/assets/buildings/infrastructure/building_event_pavilion.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 135, 982, 889] | PASS | — |
| `game/assets/buildings/infrastructure/building_first_aid_post.png` | buildings | 512×512 | RGBA / 0–255 | [20, 39, 491, 473] | PASS | — |
| `game/assets/buildings/infrastructure/building_maintenance_house.png` | buildings | 512×512 | RGBA / 0–255 | [20, 85, 491, 427] | PASS | — |
| `game/assets/buildings/infrastructure/building_medical_station.png` | buildings | 512×512 | RGBA / 0–255 | [20, 106, 491, 405] | PASS | — |
| `game/assets/buildings/infrastructure/building_parking_large.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 267, 983, 757] | PASS | — |
| `game/assets/buildings/infrastructure/building_parking_small.png` | buildings | 512×512 | RGBA / 0–255 | [20, 107, 491, 405] | PASS | — |
| `game/assets/buildings/infrastructure/building_power_station.png` | buildings | 512×512 | RGBA / 0–255 | [20, 77, 491, 435] | PASS | — |
| `game/assets/buildings/infrastructure/building_public_toilet.png` | buildings | 512×512 | RGBA / 0–255 | [20, 117, 491, 395] | PASS | — |
| `game/assets/buildings/infrastructure/building_security_station.png` | buildings | 512×512 | RGBA / 0–255 | [20, 79, 491, 433] | PASS | — |
| `game/assets/buildings/infrastructure/building_shuttle_station.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 243, 983, 780] | PASS | — |
| `game/assets/buildings/infrastructure/building_staff_rest_house.png` | buildings | 512×512 | RGBA / 0–255 | [20, 106, 491, 406] | PASS | — |
| `game/assets/buildings/infrastructure/building_visitor_center.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 254, 983, 770] | PASS | — |
| `game/assets/buildings/infrastructure/building_waste_collection.png` | buildings | 512×512 | RGBA / 0–255 | [20, 104, 491, 407] | PASS | — |
| `game/assets/buildings/infrastructure/building_water_supply.png` | buildings | 512×512 | RGBA / 0–255 | [20, 115, 491, 396] | PASS | — |
| `game/assets/characters/character_hotel_receptionist_idle.png` | characters | 256×256 | RGBA / 0–255 | [100, 17, 155, 236] | PASS | — |
| `game/assets/characters/character_restaurant_chef_idle.png` | characters | 256×256 | RGBA / 0–255 | [79, 18, 176, 236] | PASS | — |
| `game/assets/characters/character_restaurant_waiter_idle.png` | characters | 256×256 | RGBA / 0–255 | [62, 13, 194, 236] | PASS | — |
| `game/assets/characters/character_security_guard_idle.png` | characters | 256×256 | RGBA / 0–255 | [82, 11, 174, 236] | PASS | — |
| `game/assets/characters/character_tour_guide_idle.png` | characters | 256×256 | RGBA / 0–255 | [63, 15, 192, 236] | PASS | — |
| `game/assets/characters/character_tourist_backpacker_idle.png` | characters | 256×256 | RGBA / 0–255 | [75, 12, 181, 236] | PASS | Có |
| `game/assets/characters/character_tourist_elderly_female_idle.png` | characters | 256×256 | RGBA / 0–255 | [93, 31, 163, 236] | PASS | Có |
| `game/assets/characters/character_tourist_elderly_male_idle.png` | characters | 256×256 | RGBA / 0–255 | [90, 26, 166, 236] | PASS | Có |
| `game/assets/characters/character_tourist_female_02_idle.png` | characters | 256×256 | RGBA / 0–255 | [86, 24, 169, 236] | PASS | Có |
| `game/assets/characters/character_tourist_male_02_idle.png` | characters | 256×256 | RGBA / 0–255 | [89, 18, 166, 236] | PASS | Có |
| `game/assets/nature/nature_bamboo_cluster.png` | nature | 512×512 | RGBA / 0–255 | [51, 29, 461, 490] | PASS | Có |
| `game/assets/nature/nature_banana_tree.png` | nature | 512×512 | RGBA / 0–255 | [20, 81, 491, 430] | PASS | — |
| `game/assets/nature/nature_bush_flower_pink.png` | nature | 512×512 | RGBA / 0–255 | [20, 108, 491, 404] | PASS | — |
| `game/assets/nature/nature_bush_flower_yellow.png` | nature | 512×512 | RGBA / 0–255 | [20, 140, 491, 372] | PASS | Có |
| `game/assets/nature/nature_bush_green.png` | nature | 512×512 | RGBA / 0–255 | [20, 135, 491, 376] | PASS | Có |
| `game/assets/nature/nature_flowering_tree.png` | nature | 512×512 | RGBA / 0–255 | [20, 96, 491, 415] | PASS | Có |
| `game/assets/nature/nature_lily_pad_cluster.png` | nature | 512×512 | RGBA / 0–255 | [20, 100, 491, 411] | PASS | Có |
| `game/assets/nature/nature_lotus_pink.png` | nature | 512×512 | RGBA / 0–255 | [20, 40, 491, 472] | PASS | Có |
| `game/assets/nature/nature_palm_tree.png` | nature | 512×512 | RGBA / 0–255 | [130, 20, 382, 491] | PASS | — |
| `game/assets/nature/nature_rock_medium.png` | nature | 512×512 | RGBA / 0–255 | [61, 20, 451, 491] | PASS | — |
| `game/assets/nature/nature_rock_mossy.png` | nature | 512×512 | RGBA / 0–255 | [20, 151, 491, 360] | PASS | Có |
| `game/assets/nature/nature_rock_small.png` | nature | 512×512 | RGBA / 0–255 | [20, 70, 491, 441] | PASS | — |
| `game/assets/nature/nature_tree_large_01.png` | nature | 512×512 | RGBA / 0–255 | [20, 123, 491, 389] | PASS | Có |
| `game/assets/nature/nature_tree_large_02.png` | nature | 512×512 | RGBA / 0–255 | [105, 20, 407, 491] | PASS | Có |
| `game/assets/nature/nature_tree_small.png` | nature | 512×512 | RGBA / 0–255 | [148, 20, 363, 491] | PASS | Có |
| `game/assets/props/prop_direction_sign.png` | props | 512×512 | RGBA / 0–255 | [89, 20, 423, 491] | PASS | Có |
| `game/assets/props/prop_flower_pot.png` | props | 512×512 | RGBA / 0–255 | [118, 20, 393, 491] | PASS | Có |
| `game/assets/props/prop_information_board.png` | props | 512×512 | RGBA / 0–255 | [20, 46, 491, 466] | PASS | — |
| `game/assets/props/prop_life_jacket_stack.png` | props | 512×512 | RGBA / 0–255 | [20, 30, 491, 481] | PASS | — |
| `game/assets/props/prop_market_umbrella.png` | props | 512×512 | RGBA / 0–255 | [84, 20, 427, 491] | PASS | — |
| `game/assets/props/prop_picnic_table.png` | props | 512×512 | RGBA / 0–255 | [20, 74, 491, 438] | PASS | — |
| `game/assets/props/prop_stone_bench.png` | props | 512×512 | RGBA / 0–255 | [20, 104, 491, 407] | PASS | — |
| `game/assets/props/prop_stone_bridge_small.png` | props | 512×512 | RGBA / 0–255 | [20, 107, 491, 404] | PASS | — |
| `game/assets/props/prop_stone_fence.png` | props | 512×512 | RGBA / 0–255 | [20, 128, 491, 384] | PASS | — |
| `game/assets/props/prop_street_lamp.png` | props | 512×512 | RGBA / 0–255 | [185, 20, 327, 491] | PASS | Có |
| `game/assets/props/prop_trash_bin.png` | props | 512×512 | RGBA / 0–255 | [109, 20, 403, 491] | PASS | — |
| `game/assets/props/prop_wooden_bench.png` | props | 512×512 | RGBA / 0–255 | [20, 109, 491, 402] | PASS | Có |
| `game/assets/props/prop_wooden_bridge_small.png` | props | 512×512 | RGBA / 0–255 | [20, 127, 491, 385] | PASS | — |
| `game/assets/props/prop_wooden_fence_corner.png` | props | 512×512 | RGBA / 0–255 | [20, 126, 491, 385] | NEEDS_FIX | — |
| `game/assets/props/prop_wooden_fence_straight.png` | props | 512×512 | RGBA / 0–255 | [119, 167, 392, 345] | NEEDS_FIX | — |
| `game/assets/terrain/terrain_dirt_01.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | — |
| `game/assets/terrain/terrain_dirt_02.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | — |
| `game/assets/terrain/terrain_dirt_path_corner.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | NEEDS_FIX | — |
| `game/assets/terrain/terrain_dirt_path_straight.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | — |
| `game/assets/terrain/terrain_grass_01.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | Có |
| `game/assets/terrain/terrain_grass_02.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | Có |
| `game/assets/terrain/terrain_limestone_cliff_large.png` | terrain | 512×512 | RGBA / 0–255 | [40, 20, 471, 491] | PASS | Có |
| `game/assets/terrain/terrain_limestone_cliff_medium.png` | terrain | 512×512 | RGBA / 0–255 | [20, 38, 491, 473] | PASS | Có |
| `game/assets/terrain/terrain_limestone_cliff_small.png` | terrain | 512×512 | RGBA / 0–255 | [20, 108, 491, 404] | PASS | Có |
| `game/assets/terrain/terrain_limestone_rock_cluster.png` | terrain | 512×512 | RGBA / 0–255 | [20, 79, 491, 432] | PASS | Có |
| `game/assets/terrain/terrain_rice_field_golden.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | — |
| `game/assets/terrain/terrain_rice_field_green.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | — |
| `game/assets/terrain/terrain_riverbank_inner_corner.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | NEEDS_FIX | — |
| `game/assets/terrain/terrain_riverbank_outer_corner.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | NEEDS_FIX | — |
| `game/assets/terrain/terrain_riverbank_straight.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | Có |
| `game/assets/terrain/terrain_stone_path_corner.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | NEEDS_FIX | — |
| `game/assets/terrain/terrain_stone_path_cross.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | Có |
| `game/assets/terrain/terrain_stone_path_straight.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | — |
| `game/assets/terrain/terrain_water_01.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | Có |
| `game/assets/terrain/terrain_water_02.png` | terrain | 256×128 | RGBA / 0–255 | [1, 0, 255, 128] | PASS | Có |
| `game/assets/vehicles/vehicle_electric_shuttle.png` | vehicles | 512×512 | RGBA / 0–255 | [20, 68, 491, 443] | PASS | — |
| `game/assets/vehicles/vehicle_service_cart.png` | vehicles | 512×512 | RGBA / 0–255 | [20, 27, 491, 485] | PASS | — |
| `game/assets/vehicles/vehicle_small_bus.png` | vehicles | 512×512 | RGBA / 0–255 | [20, 82, 491, 430] | PASS | — |
| `game/assets/vehicles/vehicle_tourist_bicycle.png` | vehicles | 512×512 | RGBA / 0–255 | [20, 62, 491, 449] | NEEDS_FIX | — |
| `game/assets/vehicles/vehicle_tourist_boat_with_canopy.png` | vehicles | 512×512 | RGBA / 0–255 | [20, 133, 491, 379] | PASS | Có |
| `production_v1/building_homestay_lv1.png` | buildings | 1024×1024 | RGBA / 0–255 | [87, 41, 936, 983] | PASS | Có |
| `production_v1/building_restaurant_lv1.png` | buildings | 1024×1024 | RGBA / 0–255 | [41, 92, 983, 932] | PASS | Có |
| `production_v1/building_ticket_booth_lv1.png` | buildings | 512×512 | RGBA / 0–255 | [20, 38, 491, 473] | PASS | Có |
| `production_v1/character_boat_operator_idle.png` | characters | 256×256 | RGBA / 0–255 | [85, 16, 171, 236] | PASS | — |
| `production_v1/character_ticket_staff_idle.png` | characters | 256×256 | RGBA / 0–255 | [95, 16, 161, 236] | PASS | — |
| `production_v1/character_tourist_female_idle.png` | characters | 256×256 | RGBA / 0–255 | [79, 16, 177, 236] | PASS | Có |
| `production_v1/character_tourist_male_idle.png` | characters | 256×256 | RGBA / 0–255 | [84, 16, 171, 236] | PASS | Có |
| `production_v1/vehicle_tourist_boat_empty.png` | vehicles | 512×512 | RGBA / 0–255 | [20, 152, 491, 359] | PASS | Có |
| `style reference 1.png` | reference | 2172×724 | RGB / 255–255 | [0, 0, 2172, 724] | NEEDS_FIX | — |
| `style reference 2.png` | reference | 1672×941 | RGB / 255–255 | [0, 0, 1672, 941] | NEEDS_FIX | — |
| `style reference 3.png` | reference | 1774×887 | RGB / 255–255 | [0, 0, 1774, 887] | NEEDS_FIX | — |
