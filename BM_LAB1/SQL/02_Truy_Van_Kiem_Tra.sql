-- ====================================================================
-- HỌC PHẦN: AN TOÀN VÀ BẢO MẬT THÔNG TIN
-- BÀI THỰC HÀNH: LAB 1 - MÃ HÓA ĐỐI XỨNG CỔ ĐIỂN
-- SCRIPT 02: TRUY VẤN VÀ KIỂM TRA DỮ LIỆU LỊCH SỬ THAO TÁC
-- SINH VIÊN: NGUYỄN TRỌNG THỂ - MSSV: 1150080117
-- ====================================================================

USE [LAB1_MaHoaCoDien];
GO

-- 1. Xem 20 dòng lịch sử mới nhất (sắp xếp giảm dần theo id)
SELECT TOP (20) 
    id, 
    created_at AS thoi_gian, 
    algorithm AS thuat_toan, 
    operation AS thao_tac, 
    input_text AS dau_vao, 
    result_text AS ket_qua
FROM dbo.history 
ORDER BY id DESC;
GO

-- 2. Thống kê tổng số bản ghi thao tác đã ghi nhận
SELECT COUNT(*) AS tong_so_ban_ghi FROM dbo.history;
GO

-- 3. Thống kê số lần thực hiện theo từng thuật toán
SELECT 
    algorithm AS thuat_toan, 
    COUNT(*) AS so_lan_thuc_hien 
FROM dbo.history 
GROUP BY algorithm 
ORDER BY so_lan_thuc_hien DESC;
GO