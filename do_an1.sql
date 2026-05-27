USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLyJollibee')
BEGIN
    DROP DATABASE QuanLyJollibee;
END
GO

CREATE DATABASE QuanLyJollibee;
GO

USE QuanLyJollibee;
GO

-- =====================================================
-- BẢNG NGƯỜI DÙNG
-- =====================================================
CREATE TABLE NguoiDung (
    IDNguoiDung INT PRIMARY KEY IDENTITY(1,1),
    TenDangNhap NVARCHAR(50) UNIQUE NOT NULL,
    MatKhauHash NVARCHAR(255) NOT NULL,
    HoTen NVARCHAR(100) NOT NULL,
    VaiTro INT NOT NULL,
    KichHoat BIT DEFAULT 1,
    NgayTao DATETIME DEFAULT GETDATE(),
    LanDangNhapCuoi DATETIME NULL,
    CONSTRAINT CK_VaiTro CHECK (VaiTro IN (1, 2, 3))
);
GO

-- =====================================================
-- BẢNG LOẠI SẢN PHẨM
-- =====================================================
CREATE TABLE LoaiSanPham (
    IDLoai INT PRIMARY KEY IDENTITY(1,1),
    TenLoai NVARCHAR(50) NOT NULL,
    KichHoat BIT DEFAULT 1
);
GO

-- =====================================================
-- BẢNG SẢN PHẨM
-- =====================================================
CREATE TABLE SanPham (
    IDSanPham INT PRIMARY KEY IDENTITY(1,1),
    MaSanPham NVARCHAR(20) UNIQUE NOT NULL,
    TenSanPham NVARCHAR(100) NOT NULL,
    IDLoai INT NULL,
    GiaBan DECIMAL(18,2) NOT NULL CHECK (GiaBan >= 0),
    SoLuongTon INT DEFAULT 0 CHECK (SoLuongTon >= 0),
    TonToiThieu INT DEFAULT 5 CHECK (TonToiThieu >= 0),
    DuongDanAnh NVARCHAR(255) NULL,
    KichHoat BIT DEFAULT 1,
    NgayTao DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (IDLoai) REFERENCES LoaiSanPham(IDLoai)
);
GO

-- =====================================================
-- BẢNG BÀN ĂN
-- =====================================================
CREATE TABLE BanAn (
    IDBan INT PRIMARY KEY IDENTITY(1,1),
    TenBan NVARCHAR(20) NOT NULL,
    TrangThai INT DEFAULT 0,
    CONSTRAINT CK_BanTrangThai CHECK (TrangThai IN (0, 1, 2))
);
GO

-- =====================================================
-- BẢNG HÓA ĐƠN
-- =====================================================
CREATE TABLE HoaDon (
    IDHoaDon INT PRIMARY KEY IDENTITY(1,1),
    MaHoaDon NVARCHAR(20) UNIQUE NOT NULL,
    IDKhachHang INT NULL,
    IDNhanVien INT NULL,
    NgayLap DATETIME DEFAULT GETDATE(),
    TongTien DECIMAL(18,2) NOT NULL DEFAULT 0,
    LoaiDon INT NOT NULL,
    IDBan INT NULL,
    PhuongThucThanhToan NVARCHAR(50) DEFAULT N'Tiền mặt',
    TrangThai INT DEFAULT 0,
    TrangThaiDon INT DEFAULT 0,  -- 0: Chờ xác nhận, 1: Đã xác nhận, 2: Đã thanh toán, 3: Đã hủy
    GhiChu NVARCHAR(500) NULL,
    GhiChuNhanVien NVARCHAR(500) NULL,
    FOREIGN KEY (IDKhachHang) REFERENCES NguoiDung(IDNguoiDung),
    FOREIGN KEY (IDNhanVien) REFERENCES NguoiDung(IDNguoiDung),
    FOREIGN KEY (IDBan) REFERENCES BanAn(IDBan),
    CONSTRAINT CK_HoaDon_LoaiBan CHECK (
        (LoaiDon = 1 AND IDBan IS NOT NULL) OR
        (LoaiDon IN (2, 3) AND IDBan IS NULL)
    ),
    CONSTRAINT CK_HoaDon_NguoiTao CHECK (
        (LoaiDon IN (1, 2) AND IDNhanVien IS NOT NULL AND IDKhachHang IS NULL) OR
        (LoaiDon = 3 AND IDKhachHang IS NOT NULL AND IDNhanVien IS NULL)
    )
);
GO

-- =====================================================
-- BẢNG CHI TIẾT HÓA ĐƠN
-- =====================================================
CREATE TABLE ChiTietHoaDon (
    IDChiTiet INT PRIMARY KEY IDENTITY(1,1),
    IDHoaDon INT NOT NULL,
    IDSanPham INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(18,2) NOT NULL,
    ThanhTien DECIMAL(18,2) NOT NULL,
    GhiChu NVARCHAR(200) NULL,
    FOREIGN KEY (IDHoaDon) REFERENCES HoaDon(IDHoaDon),
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)
);
GO

-- =====================================================
-- BẢNG LỊCH SỬ HOẠT ĐỘNG
-- =====================================================
CREATE TABLE LichSuHoatDong (
    IDLichSu INT PRIMARY KEY IDENTITY(1,1),
    NguoiThucHien NVARCHAR(50) NOT NULL,
    IDNguoiDung INT NULL,
    ThoiGian DATETIME DEFAULT GETDATE(),
    HanhDong NVARCHAR(50) NOT NULL,
    DoiTuong NVARCHAR(50) NOT NULL,
    IDDoiTuong INT NULL,
    ChiTiet NVARCHAR(500) NULL,
    DiaChiIP NVARCHAR(50) NULL,
    ThietBi NVARCHAR(200) NULL
);
GO

-- Index cho bảng LichSuHoatDong
CREATE INDEX IX_LichSuHoatDong_ThoiGian ON LichSuHoatDong(ThoiGian);
CREATE INDEX IX_LichSuHoatDong_NguoiThucHien ON LichSuHoatDong(NguoiThucHien);
CREATE INDEX IX_LichSuHoatDong_HanhDong ON LichSuHoatDong(HanhDong);
CREATE INDEX IX_LichSuHoatDong_DoiTuong ON LichSuHoatDong(DoiTuong);
GO

-- Index cho bảng HoaDon (tối ưu truy vấn đơn chờ)
CREATE INDEX IX_HoaDon_DonCho ON HoaDon(LoaiDon, TrangThaiDon, TrangThai);
-- Index bổ sung cho bảng ChiTietHoaDon
CREATE INDEX IX_ChiTietHoaDon_IDHoaDon ON ChiTietHoaDon(IDHoaDon);
CREATE INDEX IX_ChiTietHoaDon_IDSanPham ON ChiTietHoaDon(IDSanPham);
GO

-- Index bổ sung cho bảng HoaDon
CREATE INDEX IX_HoaDon_NgayLap ON HoaDon(NgayLap);
CREATE INDEX IX_HoaDon_IDNhanVien ON HoaDon(IDNhanVien);
CREATE INDEX IX_HoaDon_IDKhachHang ON HoaDon(IDKhachHang);
CREATE INDEX IX_HoaDon_TrangThai ON HoaDon(TrangThai);
GO

-- =====================================================
-- DỮ LIỆU MẪU
-- =====================================================
INSERT INTO LoaiSanPham (TenLoai, KichHoat) VALUES
(N'Gà rán', 1), (N'Burger', 1), (N'Cơm', 1), (N'Mì Ý', 1), (N'Nước uống', 1), (N'Tráng miệng', 1);
GO

INSERT INTO SanPham (MaSanPham, TenSanPham, IDLoai, GiaBan, SoLuongTon, TonToiThieu, DuongDanAnh, KichHoat) VALUES
(N'GA001', N'Gà rán giòn 1 miếng', 1, 35000, 100, 10, N'/Images/ga_ran_1.jpg', 1),
(N'GA002', N'Gà rán giòn 2 miếng', 1, 65000, 100, 10, N'/Images/ga_ran_2.jpg', 1),
(N'GA003', N'Gà cay Jollibee', 1, 39000, 80, 10, N'/Images/ga_cay.jpg', 1),
(N'BG001', N'Burger phô mai', 2, 45000, 80, 10, N'/Images/burger_phomai.jpg', 1),
(N'BG002', N'Burger gà sốt cay', 2, 49000, 75, 10, N'/Images/burger_cay.jpg', 1),
(N'BG003', N'Burger đặc biệt', 2, 65000, 60, 8, N'/Images/burger_dac_biet.jpg', 1),
(N'CM001', N'Cơm gà rán', 3, 55000, 90, 10, N'/Images/com_ga_ran.jpg', 1),
(N'CM002', N'Cơm gà sốt nấm', 3, 59000, 85, 10, N'/Images/com_ga_nam.jpg', 1),
(N'MI001', N'Mì Ý sốt bò', 4, 49000, 70, 8, N'/Images/mi_y_bo.jpg', 1),
(N'MI002', N'Mì Ý sốt kem', 4, 52000, 65, 8, N'E:\Đồ Án (1) - Copy\Đồ Án (1)\bin\Debug\image\cach-lam-my-y-sot-tom-pho-mai-don-gian-sieu-ngon--11-760x367.jpg', 1),
(N'NU001', N'Pepsi lon', 5, 12000, 300, 30, N'/Images/pepsi.jpg', 1),
(N'NU002', N'Trà đào', 5, 25000, 150, 15, N'/Images/tra_dao.jpg', 1),
(N'NU003', N'Cà phê sữa', 5, 22000, 120, 15, N'/Images/ca_phe_sua.jpg', 1),
(N'NU004', N'Cam vắt', 5, 30000, 80, 10, N'/Images/cam_vat.jpg', 1),
(N'TM001', N'Kem xoài', 6, 15000, 120, 15, N'/Images/kem_xoai.jpg', 1),
(N'TM002', N'Bánh flan', 6, 12000, 100, 12, N'/Images/banh_flan.jpg', 1);
GO

INSERT INTO BanAn (TenBan, TrangThai) VALUES
(N'Bàn 1', 0), (N'Bàn 2', 0), (N'Bàn 3', 0), (N'Bàn 4', 0),
(N'Bàn 5', 0), (N'Bàn 6', 0), (N'Bàn 7', 0), (N'Bàn 8', 0);
GO

INSERT INTO NguoiDung (TenDangNhap, MatKhauHash, HoTen, VaiTro, KichHoat, NgayTao) VALUES
(N'admin', N'123456', N'Quản trị viên', 1, 1, GETDATE()),
(N'NV1', N'123456', N'Nguyễn Văn An', 2, 1, GETDATE()),
(N'NV2', N'123456', N'Trần Thị Bình', 2, 1, GETDATE()),
(N'khach1', N'123456', N'Nguyễn Văn Dũng', 3, 1, GETDATE()),
(N'khach2', N'123456', N'Trần Thị Em', 3, 1, GETDATE());
GO

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Đăng nhập
DROP PROCEDURE IF EXISTS sp_DangNhap;
GO
CREATE PROCEDURE sp_DangNhap
    @TenDangNhap NVARCHAR(50),
    @MatKhau NVARCHAR(255)
AS
BEGIN
    SELECT IDNguoiDung, TenDangNhap, HoTen, VaiTro, KichHoat
    FROM NguoiDung
    WHERE TenDangNhap = @TenDangNhap AND MatKhauHash = @MatKhau AND KichHoat = 1;
END
GO

-- Đăng ký khách hàng
DROP PROCEDURE IF EXISTS sp_DangKyKhachHang;
GO
CREATE PROCEDURE sp_DangKyKhachHang
    @TenDangNhap NVARCHAR(50),
    @MatKhau NVARCHAR(255),
    @HoTen NVARCHAR(100),
    @KetQua INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM NguoiDung WHERE TenDangNhap = @TenDangNhap)
    BEGIN
        SET @KetQua = -1;
        RETURN;
    END
    
    INSERT INTO NguoiDung (TenDangNhap, MatKhauHash, HoTen, VaiTro, KichHoat)
    VALUES (@TenDangNhap, @MatKhau, @HoTen, 3, 1);
    
    SET @KetQua = SCOPE_IDENTITY();
END
GO

-- Đổi mật khẩu
DROP PROCEDURE IF EXISTS sp_DoiMatKhau;
GO
CREATE PROCEDURE sp_DoiMatKhau
    @IDNguoiDung INT,
    @MatKhauCu NVARCHAR(255),
    @MatKhauMoi NVARCHAR(255),
    @KetQua INT OUTPUT
AS
BEGIN
    DECLARE @MatKhauHienTai NVARCHAR(255);
    
    SELECT @MatKhauHienTai = MatKhauHash FROM NguoiDung WHERE IDNguoiDung = @IDNguoiDung;
    
    IF @MatKhauHienTai != @MatKhauCu
    BEGIN
        SET @KetQua = 0;
        RETURN;
    END
    
    UPDATE NguoiDung SET MatKhauHash = @MatKhauMoi WHERE IDNguoiDung = @IDNguoiDung;
    SET @KetQua = 1;
END
GO

-- Tạo hóa đơn (cho nhân viên)
DROP PROCEDURE IF EXISTS sp_TaoHoaDon;
GO
CREATE PROCEDURE sp_TaoHoaDon
    @IDKhachHang INT = NULL,
    @IDNhanVien INT = NULL,
    @LoaiDon INT,
    @IDBan INT = NULL,
    @PhuongThucThanhToan NVARCHAR(50),
    @MaHoaDon NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @MaHoaDon = 'HD' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');
    
    INSERT INTO HoaDon (MaHoaDon, IDKhachHang, IDNhanVien, NgayLap, TongTien, LoaiDon, IDBan, PhuongThucThanhToan, TrangThai, TrangThaiDon)
    VALUES (@MaHoaDon, @IDKhachHang, @IDNhanVien, GETDATE(), 0, @LoaiDon, @IDBan, @PhuongThucThanhToan, 0, 
            CASE WHEN @LoaiDon = 3 THEN 0 ELSE 1 END);
    
    SELECT SCOPE_IDENTITY() AS IDHoaDon;
END
GO

-- Tạo đơn hàng chờ (cho khách hàng - KHÔNG trừ tồn kho)
DROP PROCEDURE IF EXISTS sp_TaoDonHangCho;
GO
CREATE PROCEDURE sp_TaoDonHangCho
    @IDKhachHang INT,
    @LoaiDon INT = 3,
    @PhuongThucThanhToan NVARCHAR(50) = N'Tiền mặt',
    @MaHoaDon NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @MaHoaDon = 'OD' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');
    
    INSERT INTO HoaDon (MaHoaDon, IDKhachHang, IDNhanVien, NgayLap, TongTien, LoaiDon, IDBan, PhuongThucThanhToan, TrangThai, TrangThaiDon)
    VALUES (@MaHoaDon, @IDKhachHang, NULL, GETDATE(), 0, @LoaiDon, NULL, @PhuongThucThanhToan, 0, 0);
    
    SELECT SCOPE_IDENTITY() AS IDHoaDon;
END
GO

-- Thêm chi tiết vào đơn hàng chờ
DROP PROCEDURE IF EXISTS sp_ThemChiTietDonCho;
GO
CREATE PROCEDURE sp_ThemChiTietDonCho
    @IDHoaDon INT,
    @IDSanPham INT,
    @SoLuong INT,
    @GhiChu NVARCHAR(200) = NULL
AS
BEGIN
    DECLARE @DonGia DECIMAL(18,2);
    DECLARE @ThanhTien DECIMAL(18,2);
    DECLARE @TenSanPham NVARCHAR(100);
    
    SELECT @DonGia = GiaBan, @TenSanPham = TenSanPham
    FROM SanPham WHERE IDSanPham = @IDSanPham;
    
    SET @ThanhTien = @DonGia * @SoLuong;
    
    INSERT INTO ChiTietHoaDon (IDHoaDon, IDSanPham, SoLuong, DonGia, ThanhTien, GhiChu)
    VALUES (@IDHoaDon, @IDSanPham, @SoLuong, @DonGia, @ThanhTien, @GhiChu);
    
    UPDATE HoaDon 
    SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = @IDHoaDon)
    WHERE IDHoaDon = @IDHoaDon;
    
    SELECT @ThanhTien AS ThanhTien;
END
GO

-- Lấy danh sách đơn chờ xác nhận
DROP PROCEDURE IF EXISTS sp_LayDonChoXacNhan;
GO
CREATE PROCEDURE sp_LayDonChoXacNhan
AS
BEGIN
    SELECT 
        hd.IDHoaDon,
        hd.MaHoaDon,
        hd.NgayLap,
        FORMAT(hd.NgayLap, 'dd/MM/yyyy HH:mm') AS NgayLapText,
        hd.TongTien,
        FORMAT(hd.TongTien, 'N0') AS TongTienFormat,
        ISNULL(kh.HoTen, N'Khách vãng lai') AS TenKhachHang,
        kh.TenDangNhap,
        (SELECT COUNT(*) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS SoLuongMon
    FROM HoaDon hd
    LEFT JOIN NguoiDung kh ON hd.IDKhachHang = kh.IDNguoiDung
    WHERE hd.LoaiDon = 3 
      AND hd.TrangThaiDon = 0
      AND hd.TrangThai = 0
    ORDER BY hd.NgayLap ASC
END
GO

-- Xác nhận đơn hàng (nhân viên duyệt - trừ tồn kho)
-- ✅ ĐÃ SỬA: KHÔNG cập nhật IDNhanVien để tránh vi phạm CHECK constraint
DROP PROCEDURE IF EXISTS sp_XacNhanDonHang;
GO
CREATE PROCEDURE sp_XacNhanDonHang
    @IDHoaDon INT,
    @IDNhanVien INT,
    @GhiChu NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM HoaDon WHERE IDHoaDon = @IDHoaDon AND LoaiDon = 3 AND TrangThaiDon = 0)
        BEGIN
            RAISERROR(N'Đơn hàng không tồn tại hoặc đã được xác nhận trước đó!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra tồn kho trước khi xác nhận
        IF EXISTS (
            SELECT 1 FROM ChiTietHoaDon ct
            INNER JOIN SanPham sp ON ct.IDSanPham = sp.IDSanPham
            WHERE ct.IDHoaDon = @IDHoaDon AND sp.SoLuongTon < ct.SoLuong
        )
        BEGIN
            RAISERROR(N'Một số sản phẩm trong đơn hàng đã hết hoặc không đủ số lượng!', 16, 1);
            RETURN;
        END
        
        -- ✅ SỬA: KHÔNG cập nhật IDNhanVien
        UPDATE HoaDon 
        SET TrangThaiDon = 1,
            GhiChuNhanVien = @GhiChu
        WHERE IDHoaDon = @IDHoaDon;
        
        -- Trừ tồn kho
        UPDATE sp
        SET sp.SoLuongTon = sp.SoLuongTon - ct.SoLuong
        FROM SanPham sp
        INNER JOIN ChiTietHoaDon ct ON sp.IDSanPham = ct.IDSanPham
        WHERE ct.IDHoaDon = @IDHoaDon;
        
        COMMIT TRANSACTION;
        
        SELECT @IDHoaDon AS IDHoaDon;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Từ chối/Hủy đơn hàng
-- ✅ ĐÃ SỬA: KHÔNG cập nhật IDNhanVien để tránh vi phạm CHECK constraint
DROP PROCEDURE IF EXISTS sp_TuChoiDonHang;
GO
CREATE PROCEDURE sp_TuChoiDonHang
    @IDHoaDon INT,
    @IDNhanVien INT,
    @LyDo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM HoaDon WHERE IDHoaDon = @IDHoaDon AND LoaiDon = 3 AND TrangThaiDon = 0)
    BEGIN
        RAISERROR(N'Đơn hàng không tồn tại hoặc đã được xử lý!', 16, 1);
        RETURN;
    END
    
    -- ✅ SỬA: KHÔNG cập nhật IDNhanVien
    UPDATE HoaDon 
    SET TrangThaiDon = 3,
        GhiChuNhanVien = @LyDo
    WHERE IDHoaDon = @IDHoaDon;
    
    SELECT @IDHoaDon AS IDHoaDon;
END
GO

-- Lịch sử đơn hàng theo khách hàng (đầy đủ)
DROP PROCEDURE IF EXISTS sp_LichSuDonHangKhachHang;
GO
CREATE PROCEDURE sp_LichSuDonHangKhachHang
    @IDKhachHang INT,
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SELECT 
        hd.IDHoaDon,
        hd.MaHoaDon,
        hd.NgayLap,
        FORMAT(hd.NgayLap, 'dd/MM/yyyy HH:mm') AS NgayLapText,
        hd.TongTien,
        FORMAT(hd.TongTien, 'N0') AS TongTienFormat,
        CASE hd.LoaiDon
            WHEN 1 THEN N'Ăn tại bàn'
            WHEN 2 THEN N'Mang về'
            WHEN 3 THEN N'Tự order'
        END AS LoaiDonText,
        CASE hd.TrangThaiDon
            WHEN 0 THEN N'Chờ xác nhận'
            WHEN 1 THEN N'Đã xác nhận'
            WHEN 2 THEN N'Đã thanh toán'
            WHEN 3 THEN N'Đã hủy'
        END AS TrangThaiDonText,
        ISNULL(nv.HoTen, N'Chưa có NV') AS TenNhanVien,
        (SELECT COUNT(*) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS SoLuongMon
    FROM HoaDon hd
    LEFT JOIN NguoiDung nv ON hd.IDNhanVien = nv.IDNguoiDung
    WHERE hd.IDKhachHang = @IDKhachHang
      AND (@TuNgay IS NULL OR CAST(hd.NgayLap AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(hd.NgayLap AS DATE) <= @DenNgay)
    ORDER BY hd.NgayLap DESC
END
GO

-- Đếm số đơn chờ xác nhận (dùng cho badge thông báo)
DROP PROCEDURE IF EXISTS sp_DemDonChoXacNhan;
GO
CREATE PROCEDURE sp_DemDonChoXacNhan
AS
BEGIN
    SELECT COUNT(*) AS SoLuong
    FROM HoaDon 
    WHERE LoaiDon = 3 AND TrangThaiDon = 0 AND TrangThai = 0;
END
GO

-- =====================================================
-- CÁC STORED PROCEDURES KHÁC
-- =====================================================

-- Thêm chi tiết hóa đơn (cho nhân viên - có trừ tồn kho)
DROP PROCEDURE IF EXISTS sp_ThemChiTietHoaDon;
GO
CREATE PROCEDURE sp_ThemChiTietHoaDon
    @IDHoaDon INT,
    @IDSanPham INT,
    @SoLuong INT,
    @GhiChu NVARCHAR(200) = NULL
AS
BEGIN
    DECLARE @DonGia DECIMAL(18,2);
    DECLARE @ThanhTien DECIMAL(18,2);
    DECLARE @TonKhoHienTai INT;
    DECLARE @TenSanPham NVARCHAR(100);
    
    SELECT @DonGia = GiaBan, @TonKhoHienTai = SoLuongTon, @TenSanPham = TenSanPham
    FROM SanPham WHERE IDSanPham = @IDSanPham;
    
    IF @TonKhoHienTai < @SoLuong
    BEGIN
        RAISERROR(N'Sản phẩm %s không đủ hàng! Còn lại %d sản phẩm.', 16, 1, @TenSanPham, @TonKhoHienTai);
        RETURN;
    END
    
    SET @ThanhTien = @DonGia * @SoLuong;
    
    INSERT INTO ChiTietHoaDon (IDHoaDon, IDSanPham, SoLuong, DonGia, ThanhTien, GhiChu)
    VALUES (@IDHoaDon, @IDSanPham, @SoLuong, @DonGia, @ThanhTien, @GhiChu);
    
    UPDATE SanPham SET SoLuongTon = SoLuongTon - @SoLuong WHERE IDSanPham = @IDSanPham;
    
    UPDATE HoaDon 
    SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = @IDHoaDon)
    WHERE IDHoaDon = @IDHoaDon;
    
    SELECT @ThanhTien AS ThanhTien;
END
GO

-- Hoàn tất thanh toán
DROP PROCEDURE IF EXISTS sp_HoanTatThanhToan;
GO
CREATE PROCEDURE sp_HoanTatThanhToan
    @IDHoaDon INT,
    @PhuongThucThanhToan NVARCHAR(50)
AS
BEGIN
    DECLARE @LoaiDon INT;
    DECLARE @IDBan INT;
    
    UPDATE HoaDon SET PhuongThucThanhToan = @PhuongThucThanhToan, TrangThai = 1, TrangThaiDon = 2
    WHERE IDHoaDon = @IDHoaDon;
    
    SELECT @LoaiDon = LoaiDon, @IDBan = IDBan FROM HoaDon WHERE IDHoaDon = @IDHoaDon;
    
    IF @LoaiDon = 1 AND @IDBan IS NOT NULL
    BEGIN
        UPDATE BanAn SET TrangThai = 2 WHERE IDBan = @IDBan;
    END
    
    SELECT @IDHoaDon AS IDHoaDon;
END
GO

-- Dọn bàn
DROP PROCEDURE IF EXISTS sp_DonBan;
GO
CREATE PROCEDURE sp_DonBan
    @IDBan INT
AS
BEGIN
    UPDATE BanAn SET TrangThai = 0 WHERE IDBan = @IDBan;
    SELECT @IDBan AS IDBan;
END
GO

-- Lấy danh sách sản phẩm
DROP PROCEDURE IF EXISTS sp_LayDanhSachSanPham;
GO
CREATE PROCEDURE sp_LayDanhSachSanPham
AS
BEGIN
    SELECT sp.IDSanPham, sp.MaSanPham, sp.TenSanPham, lsp.TenLoai, sp.GiaBan, sp.SoLuongTon, sp.DuongDanAnh
    FROM SanPham sp
    LEFT JOIN LoaiSanPham lsp ON sp.IDLoai = lsp.IDLoai
    WHERE sp.KichHoat = 1 AND sp.SoLuongTon > 0
    ORDER BY lsp.TenLoai, sp.TenSanPham;
END
GO

-- Tìm kiếm sản phẩm
DROP PROCEDURE IF EXISTS sp_TimKiemSanPham;
GO
CREATE PROCEDURE sp_TimKiemSanPham
    @TuKhoa NVARCHAR(100)
AS
BEGIN
    SELECT sp.IDSanPham, sp.MaSanPham, sp.TenSanPham, lsp.TenLoai, sp.GiaBan, sp.SoLuongTon, sp.DuongDanAnh
    FROM SanPham sp
    LEFT JOIN LoaiSanPham lsp ON sp.IDLoai = lsp.IDLoai
    WHERE sp.KichHoat = 1 AND sp.SoLuongTon > 0
      AND (sp.TenSanPham LIKE N'%' + @TuKhoa + '%' OR sp.MaSanPham LIKE '%' + @TuKhoa + '%')
    ORDER BY sp.TenSanPham;
END
GO

-- Top sản phẩm bán chạy
DROP PROCEDURE IF EXISTS sp_TopSanPhamBanChay;
GO
CREATE PROCEDURE sp_TopSanPhamBanChay
    @Top INT = 5
AS
BEGIN
    SELECT TOP (@Top) sp.IDSanPham, sp.MaSanPham, sp.TenSanPham,
        ISNULL(SUM(ct.SoLuong), 0) AS SoLuongBan,
        ISNULL(SUM(ct.ThanhTien), 0) AS DoanhThu
    FROM SanPham sp
    LEFT JOIN ChiTietHoaDon ct ON sp.IDSanPham = ct.IDSanPham
    LEFT JOIN HoaDon hd ON ct.IDHoaDon = hd.IDHoaDon AND hd.TrangThai = 1
    WHERE sp.KichHoat = 1
    GROUP BY sp.IDSanPham, sp.MaSanPham, sp.TenSanPham
    HAVING ISNULL(SUM(ct.SoLuong), 0) > 0
    ORDER BY SoLuongBan DESC;
END
GO

-- Cảnh báo sắp hết hàng
DROP PROCEDURE IF EXISTS sp_CanhBaoSapHetHang;
GO
CREATE PROCEDURE sp_CanhBaoSapHetHang
AS
BEGIN
    SELECT IDSanPham, MaSanPham, TenSanPham, SoLuongTon, TonToiThieu,
        CASE 
            WHEN SoLuongTon <= 0 THEN N'HẾT HÀNG'
            WHEN SoLuongTon <= TonToiThieu THEN N'SẮP HẾT'
            ELSE N'BÌNH THƯỜNG'
        END AS TrangThai
    FROM SanPham
    WHERE KichHoat = 1 AND SoLuongTon <= TonToiThieu
    ORDER BY SoLuongTon ASC;
END
GO

-- Báo cáo doanh thu
DROP PROCEDURE IF EXISTS sp_BaoCaoDoanhThu;
GO
CREATE PROCEDURE sp_BaoCaoDoanhThu
    @TuNgay DATE,
    @DenNgay DATE
AS
BEGIN
    SELECT 
        CAST(NgayLap AS DATE) AS Ngay,
        FORMAT(CAST(NgayLap AS DATE), 'dd/MM/yyyy') AS NgayText,
        COUNT(IDHoaDon) AS SoDon,
        ISNULL(SUM(TongTien), 0) AS DoanhThu,
        ISNULL(AVG(TongTien), 0) AS TrungBinhDon,
        ISNULL(MAX(TongTien), 0) AS DonCaoNhat,
        ISNULL(MIN(TongTien), 0) AS DonThapNhat
    FROM HoaDon
    WHERE NgayLap >= @TuNgay AND NgayLap <= DATEADD(day, 1, @DenNgay) AND TrangThai = 1
    GROUP BY CAST(NgayLap AS DATE)
    ORDER BY Ngay DESC;
END
GO

-- Lấy danh sách bàn
DROP PROCEDURE IF EXISTS sp_LayDanhSachBan;
GO
CREATE PROCEDURE sp_LayDanhSachBan
AS
BEGIN
    SELECT IDBan, TenBan, TrangThai FROM BanAn ORDER BY IDBan;
END
GO

-- Lịch sử đơn hàng theo nhân viên
DROP PROCEDURE IF EXISTS sp_LichSuDonHangTheoNhanVien;
GO
CREATE PROCEDURE sp_LichSuDonHangTheoNhanVien
    @IDNhanVien INT,
    @Ngay DATE = NULL
AS
BEGIN
    IF @Ngay IS NULL SET @Ngay = CAST(GETDATE() AS DATE);
    
    SELECT IDHoaDon, MaHoaDon, NgayLap, TongTien, LoaiDon, PhuongThucThanhToan
    FROM HoaDon
    WHERE IDNhanVien = @IDNhanVien AND CAST(NgayLap AS DATE) = @Ngay AND TrangThai = 1
    ORDER BY NgayLap DESC;
END
GO

-- Lịch sử đơn hàng theo khách hàng (cũ)
DROP PROCEDURE IF EXISTS sp_LichSuDonHangTheoKhachHang;
GO
CREATE PROCEDURE sp_LichSuDonHangTheoKhachHang
    @IDKhachHang INT
AS
BEGIN
    SELECT IDHoaDon, MaHoaDon, NgayLap, TongTien, LoaiDon, PhuongThucThanhToan
    FROM HoaDon
    WHERE IDKhachHang = @IDKhachHang AND TrangThai = 1
    ORDER BY NgayLap DESC;
END
GO

-- Thống kê nhân viên
DROP PROCEDURE IF EXISTS sp_ThongKeNhanVien;
GO
CREATE PROCEDURE sp_ThongKeNhanVien
    @IDNhanVien INT,
    @TuNgay DATE,
    @DenNgay DATE
AS
BEGIN
    SELECT 
        COUNT(hd.IDHoaDon) AS SoDonHoanThanh,
        ISNULL(SUM(hd.TongTien), 0) AS TongDoanhThu,
        ISNULL(AVG(hd.TongTien), 0) AS TrungBinhDon
    FROM HoaDon hd
    WHERE hd.IDNhanVien = @IDNhanVien
      AND hd.NgayLap >= @TuNgay
      AND hd.NgayLap <= DATEADD(day, 1, @DenNgay)
      AND hd.TrangThai = 1;
END
GO

-- Chi tiết hóa đơn
DROP PROCEDURE IF EXISTS sp_ChiTietHoaDon;
GO
CREATE PROCEDURE sp_ChiTietHoaDon
    @IDHoaDon INT
AS
BEGIN
    SELECT 
        hd.MaHoaDon, hd.NgayLap, 
        CASE hd.LoaiDon 
            WHEN 1 THEN N'Ăn tại bàn'
            WHEN 2 THEN N'Mang về'
            WHEN 3 THEN N'Tự order'
        END AS TenLoaiDon,
        hd.PhuongThucThanhToan, hd.TongTien, hd.GhiChu,
        ISNULL(nd.HoTen, N'Khách vãng lai') AS TenNhanVien,
        ct.IDSanPham, sp.MaSanPham, sp.TenSanPham, ct.SoLuong, ct.DonGia, ct.ThanhTien, ct.GhiChu AS GhiChuCT
    FROM HoaDon hd
    LEFT JOIN NguoiDung nd ON hd.IDNhanVien = nd.IDNguoiDung
    LEFT JOIN ChiTietHoaDon ct ON hd.IDHoaDon = ct.IDHoaDon
    LEFT JOIN SanPham sp ON ct.IDSanPham = sp.IDSanPham
    WHERE hd.IDHoaDon = @IDHoaDon;
END
GO

-- =====================================================
-- STORED PROCEDURES CHO LỊCH SỬ HOẠT ĐỘNG
-- =====================================================

-- Thêm lịch sử hoạt động
DROP PROCEDURE IF EXISTS sp_ThemLichSuHoatDong;
GO
CREATE PROCEDURE sp_ThemLichSuHoatDong
    @NguoiThucHien NVARCHAR(50),
    @IDNguoiDung INT = NULL,
    @HanhDong NVARCHAR(50),
    @DoiTuong NVARCHAR(50),
    @IDDoiTuong INT = NULL,
    @ChiTiet NVARCHAR(500) = NULL,
    @DiaChiIP NVARCHAR(50) = NULL,
    @ThietBi NVARCHAR(200) = NULL
AS
BEGIN
    INSERT INTO LichSuHoatDong (NguoiThucHien, IDNguoiDung, ThoiGian, HanhDong, DoiTuong, IDDoiTuong, ChiTiet, DiaChiIP, ThietBi)
    VALUES (@NguoiThucHien, @IDNguoiDung, GETDATE(), @HanhDong, @DoiTuong, @IDDoiTuong, @ChiTiet, @DiaChiIP, @ThietBi);
    
    SELECT SCOPE_IDENTITY() AS IDLichSu;
END
GO

-- Lấy danh sách lịch sử hoạt động
DROP PROCEDURE IF EXISTS sp_LayLichSuHoatDong;
GO
CREATE PROCEDURE sp_LayLichSuHoatDong
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL,
    @HanhDong NVARCHAR(50) = NULL,
    @NguoiThucHien NVARCHAR(50) = NULL,
    @DoiTuong NVARCHAR(50) = NULL,
    @Top INT = 1000
AS
BEGIN
    SELECT TOP (@Top)
        ls.IDLichSu,
        ls.NguoiThucHien,
        ls.IDNguoiDung,
        ls.ThoiGian,
        FORMAT(ls.ThoiGian, 'dd/MM/yyyy HH:mm:ss') AS ThoiGianText,
        ls.HanhDong,
        ls.DoiTuong,
        ls.IDDoiTuong,
        ls.ChiTiet,
        ls.DiaChiIP,
        ls.ThietBi,
        ISNULL(nd.HoTen, ls.NguoiThucHien) AS TenNguoiDung
    FROM LichSuHoatDong ls
    LEFT JOIN NguoiDung nd ON ls.IDNguoiDung = nd.IDNguoiDung
    WHERE (@TuNgay IS NULL OR CAST(ls.ThoiGian AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(ls.ThoiGian AS DATE) <= @DenNgay)
      AND (@HanhDong IS NULL OR ls.HanhDong = @HanhDong)
      AND (@NguoiThucHien IS NULL OR ls.NguoiThucHien LIKE N'%' + @NguoiThucHien + '%')
      AND (@DoiTuong IS NULL OR ls.DoiTuong = @DoiTuong)
    ORDER BY ls.ThoiGian DESC
END
GO

-- Thống kê lịch sử hoạt động
DROP PROCEDURE IF EXISTS sp_ThongKeLichSuHoatDong;
GO
CREATE PROCEDURE sp_ThongKeLichSuHoatDong
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SELECT COUNT(*) AS TongSo FROM LichSuHoatDong
    WHERE (@TuNgay IS NULL OR CAST(ThoiGian AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(ThoiGian AS DATE) <= @DenNgay);
    
    SELECT HanhDong, COUNT(*) AS SoLuong
    FROM LichSuHoatDong
    WHERE (@TuNgay IS NULL OR CAST(ThoiGian AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(ThoiGian AS DATE) <= @DenNgay)
    GROUP BY HanhDong
    ORDER BY SoLuong DESC;
    
    SELECT TOP 10 NguoiThucHien, COUNT(*) AS SoLuong
    FROM LichSuHoatDong
    WHERE (@TuNgay IS NULL OR CAST(ThoiGian AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(ThoiGian AS DATE) <= @DenNgay)
    GROUP BY NguoiThucHien
    ORDER BY SoLuong DESC;
END
GO

-- =====================================================
-- VIEWS
-- =====================================================

-- View 1: Hóa đơn trong ngày
CREATE OR ALTER VIEW vw_HoaDonTrongNgay AS
SELECT 
    hd.MaHoaDon,
    FORMAT(hd.NgayLap, 'dd/MM/yyyy HH:mm:ss') AS NgayLap,
    CASE hd.LoaiDon 
        WHEN 1 THEN N'Ăn tại bàn'
        WHEN 2 THEN N'Mang về'
        WHEN 3 THEN N'Tự order'
    END AS LoaiDon,
    ISNULL(nd.HoTen, N'Khách vãng lai') AS NhanVien,
    ISNULL(b.TenBan, N'Không có bàn') AS Ban,
    FORMAT(hd.TongTien, 'N0') AS TongTien,
    hd.PhuongThucThanhToan,
    hd.GhiChu
FROM HoaDon hd
LEFT JOIN NguoiDung nd ON hd.IDNhanVien = nd.IDNguoiDung
LEFT JOIN BanAn b ON hd.IDBan = b.IDBan
WHERE CAST(hd.NgayLap AS DATE) = CAST(GETDATE() AS DATE)
  AND hd.TrangThai = 1;
GO

-- View 2: Hóa đơn trong tháng
CREATE OR ALTER VIEW vw_HoaDonTrongThang AS
SELECT 
    FORMAT(hd.NgayLap, 'dd/MM/yyyy') AS Ngay,
    hd.MaHoaDon,
    FORMAT(hd.NgayLap, 'dd/MM/yyyy HH:mm:ss') AS ThoiGian,
    CASE hd.LoaiDon 
        WHEN 1 THEN N'Ăn tại bàn'
        WHEN 2 THEN N'Mang về'
        WHEN 3 THEN N'Tự order'
    END AS LoaiDon,
    ISNULL(nd.HoTen, N'Khách vãng lai') AS NhanVien,
    ISNULL(b.TenBan, N'Không có bàn') AS Ban,
    hd.TongTien,
    FORMAT(hd.TongTien, 'N0') AS TongTienFormat,
    hd.PhuongThucThanhToan
FROM HoaDon hd
LEFT JOIN NguoiDung nd ON hd.IDNhanVien = nd.IDNguoiDung
LEFT JOIN BanAn b ON hd.IDBan = b.IDBan
WHERE YEAR(hd.NgayLap) = YEAR(GETDATE())
  AND MONTH(hd.NgayLap) = MONTH(GETDATE())
  AND hd.TrangThai = 1;
GO

-- View 3: Thông tin sản phẩm
CREATE OR ALTER VIEW vw_ThongTinSanPham AS
SELECT 
    sp.MaSanPham,
    sp.TenSanPham,
    ISNULL(lsp.TenLoai, N'Chưa phân loại') AS DanhMuc,
    FORMAT(sp.GiaBan, 'N0') AS GiaBan,
    sp.SoLuongTon AS TonKho,
    CASE 
        WHEN sp.SoLuongTon <= 0 THEN N'HẾT HÀNG'
        WHEN sp.SoLuongTon <= sp.TonToiThieu THEN N'SẮP HẾT'
        ELSE N'CÒN HÀNG'
    END AS TrangThai
FROM SanPham sp
LEFT JOIN LoaiSanPham lsp ON sp.IDLoai = lsp.IDLoai
WHERE sp.KichHoat = 1;
GO

-- View 4: Top sản phẩm bán chạy
CREATE OR ALTER VIEW vw_TopSanPhamBanChayFull AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(ct.SoLuong) DESC) AS XepHang,
    sp.MaSanPham,
    sp.TenSanPham,
    ISNULL(lsp.TenLoai, N'Chưa phân loại') AS DanhMuc,
    sp.GiaBan,
    FORMAT(sp.GiaBan, 'N0') AS GiaBanFormat,
    ISNULL(SUM(ct.SoLuong), 0) AS SoLuongDaBan,
    ISNULL(SUM(ct.ThanhTien), 0) AS DoanhThu,
    FORMAT(ISNULL(SUM(ct.ThanhTien), 0), 'N0') AS DoanhThuFormat
FROM SanPham sp
LEFT JOIN LoaiSanPham lsp ON sp.IDLoai = lsp.IDLoai
LEFT JOIN ChiTietHoaDon ct ON sp.IDSanPham = ct.IDSanPham
LEFT JOIN HoaDon hd ON ct.IDHoaDon = hd.IDHoaDon AND hd.TrangThai = 1
WHERE sp.KichHoat = 1
GROUP BY sp.MaSanPham, sp.TenSanPham, lsp.TenLoai, sp.GiaBan;
GO

-- View 5: Tất cả hóa đơn
CREATE OR ALTER VIEW vw_AllHoaDon AS
SELECT 
    hd.IDHoaDon,
    hd.MaHoaDon,
    hd.NgayLap,
    FORMAT(hd.NgayLap, 'dd/MM/yyyy') AS Ngay,
    FORMAT(hd.NgayLap, 'dd/MM/yyyy HH:mm:ss') AS ThoiGian,
    FORMAT(hd.NgayLap, 'yyyy') AS Nam,
    FORMAT(hd.NgayLap, 'MM') AS Thang,
    FORMAT(hd.NgayLap, 'dd') AS NgayTrongThang,
    DATEPART(quarter, hd.NgayLap) AS Quy,
    CASE DATEPART(dw, hd.NgayLap)
        WHEN 1 THEN N'Chủ nhật'
        WHEN 2 THEN N'Thứ 2'
        WHEN 3 THEN N'Thứ 3'
        WHEN 4 THEN N'Thứ 4'
        WHEN 5 THEN N'Thứ 5'
        WHEN 6 THEN N'Thứ 6'
        WHEN 7 THEN N'Thứ 7'
    END AS Thu,
    CASE hd.LoaiDon 
        WHEN 1 THEN N'Ăn tại bàn'
        WHEN 2 THEN N'Mang về'
        WHEN 3 THEN N'Tự order'
    END AS LoaiDon,
    ISNULL(nd.HoTen, N'Khách vãng lai') AS NhanVien,
    nd.TenDangNhap AS TenDangNhapNV,
    ISNULL(kh.HoTen, N'Khách vãng lai') AS KhachHang,
    ISNULL(b.TenBan, N'Không có bàn') AS Ban,
    hd.TongTien,
    FORMAT(hd.TongTien, 'N0') AS TongTienFormat,
    hd.PhuongThucThanhToan,
    CASE hd.TrangThai 
        WHEN 0 THEN N'Chưa thanh toán'
        WHEN 1 THEN N'Đã thanh toán'
    END AS TrangThai,
    CASE hd.TrangThaiDon
        WHEN 0 THEN N'Chờ xác nhận'
        WHEN 1 THEN N'Đã xác nhận'
        WHEN 2 THEN N'Đã thanh toán'
        WHEN 3 THEN N'Đã hủy'
    END AS TrangThaiDonText,
    hd.GhiChu,
    (SELECT COUNT(*) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS SoLuongMatHang,
    (SELECT SUM(SoLuong) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS TongSoLuongSanPham
FROM HoaDon hd
LEFT JOIN NguoiDung nd ON hd.IDNhanVien = nd.IDNguoiDung
LEFT JOIN NguoiDung kh ON hd.IDKhachHang = kh.IDNguoiDung
LEFT JOIN BanAn b ON hd.IDBan = b.IDBan
WHERE hd.TrangThai = 1;
GO

-- View 6: Đơn chờ xác nhận (dễ hiển thị)
CREATE OR ALTER VIEW vw_DonChoXacNhan AS
SELECT 
    hd.IDHoaDon,
    hd.MaHoaDon,
    FORMAT(hd.NgayLap, 'dd/MM/yyyy HH:mm') AS ThoiGian,
    ISNULL(kh.HoTen, N'Khách vãng lai') AS KhachHang,
    kh.TenDangNhap,
    hd.TongTien,
    FORMAT(hd.TongTien, 'N0') AS TongTienFormat,
    (SELECT STRING_AGG(CONCAT(sp.TenSanPham, ' x ', ct.SoLuong), ', ') 
     FROM ChiTietHoaDon ct 
     INNER JOIN SanPham sp ON ct.IDSanPham = sp.IDSanPham
     WHERE ct.IDHoaDon = hd.IDHoaDon) AS ChiTietMonAn,
    (SELECT COUNT(*) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS SoLuongMon
FROM HoaDon hd
LEFT JOIN NguoiDung kh ON hd.IDKhachHang = kh.IDNguoiDung
WHERE hd.LoaiDon = 3 AND hd.TrangThaiDon = 0 AND hd.TrangThai = 0;
GO

-- =====================================================
-- FUNCTION: Đếm số đơn chờ (dùng cho badge)
-- =====================================================
DROP FUNCTION IF EXISTS fn_DemDonChoXacNhan;
GO
CREATE FUNCTION fn_DemDonChoXacNhan()
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    
    SELECT @Count = COUNT(*) 
    FROM HoaDon 
    WHERE LoaiDon = 3 AND TrangThaiDon = 0 AND TrangThai = 0;
    
    RETURN @Count;
END
GO

-- =====================================================
-- KIỂM TRA
-- =====================================================
SELECT 'Bảng NguoiDung' AS TenBang, COUNT(*) AS SoLuong FROM NguoiDung
UNION ALL SELECT 'LoaiSanPham', COUNT(*) FROM LoaiSanPham
UNION ALL SELECT 'SanPham', COUNT(*) FROM SanPham
UNION ALL SELECT 'BanAn', COUNT(*) FROM BanAn
UNION ALL SELECT 'HoaDon', COUNT(*) FROM HoaDon
UNION ALL SELECT 'ChiTietHoaDon', COUNT(*) FROM ChiTietHoaDon
UNION ALL SELECT 'LichSuHoatDong', COUNT(*) FROM LichSuHoatDong;
GO

SELECT N'Tạo database QuanLyJollibee thành công!' AS KetQua;
SELECT N'Số lượng bàn: ' + CAST(COUNT(*) AS NVARCHAR) FROM BanAn;
SELECT N'Số lượng sản phẩm: ' + CAST(COUNT(*) AS NVARCHAR) FROM SanPham;
SELECT N'Số lượng người dùng: ' + CAST(COUNT(*) AS NVARCHAR) FROM NguoiDung;
GO

SELECT * FROM NguoiDung;
GO

-- Kiểm tra số đơn chờ (ban đầu = 0)
SELECT dbo.fn_DemDonChoXacNhan() AS SoDonChoXacNhan;
GO

-- =====================================================
-- VIEW DOANH THU
-- =====================================================
CREATE OR ALTER VIEW vw_DoanhThu AS
SELECT 
    -- Thời gian
    hd.IDHoaDon,
    hd.NgayLap,
    CAST(hd.NgayLap AS DATE) AS Ngay,
    YEAR(hd.NgayLap) AS Nam,
    MONTH(hd.NgayLap) AS Thang,
    FORMAT(hd.NgayLap, 'MM/yyyy') AS ThangNam,
    DATEPART(QUARTER, hd.NgayLap) AS Quy,
    CASE DATEPART(WEEKDAY, hd.NgayLap)
        WHEN 1 THEN N'Chủ nhật' WHEN 2 THEN N'Thứ 2'
        WHEN 3 THEN N'Thứ 3' WHEN 4 THEN N'Thứ 4'
        WHEN 5 THEN N'Thứ 5' WHEN 6 THEN N'Thứ 6'
        WHEN 7 THEN N'Thứ 7'
    END AS Thu,
    
    -- Đơn hàng
    hd.MaHoaDon,
    CASE hd.LoaiDon 
        WHEN 1 THEN N'Ăn tại bàn' WHEN 2 THEN N'Mang về' WHEN 3 THEN N'Tự order'
    END AS LoaiDon,
    
    -- Nhân viên & khách hàng
    ISNULL(nv.HoTen, N'Không có NV') AS TenNhanVien,
    CASE WHEN hd.IDKhachHang IS NULL THEN N'Khách vãng lai' ELSE N'Thành viên' END AS LoaiKhachHang,
    ISNULL(kh.HoTen, N'Khách vãng lai') AS TenKhachHang,
    
    -- Tài chính
    hd.TongTien,
    hd.PhuongThucThanhToan,
    
    -- Số lượng món
    (SELECT COUNT(*) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS SoLuongMon,
    (SELECT SUM(SoLuong) FROM ChiTietHoaDon WHERE IDHoaDon = hd.IDHoaDon) AS TongSoLuongSanPham,
    
    -- Phân khúc
    CASE 
        WHEN hd.TongTien < 50000 THEN N'Dưới 50k'
        WHEN hd.TongTien < 100000 THEN N'50k-100k'
        WHEN hd.TongTien < 200000 THEN N'100k-200k'
        ELSE N'Trên 200k'
    END AS KhungGia

FROM HoaDon hd
LEFT JOIN NguoiDung nv ON hd.IDNhanVien = nv.IDNguoiDung
LEFT JOIN NguoiDung kh ON hd.IDKhachHang = kh.IDNguoiDung
WHERE hd.TrangThai = 1;
GO

-- =====================================================
-- THÊM DỮ LIỆU HÓA ĐƠN
-- =====================================================

-- Xóa dữ liệu cũ
DELETE FROM ChiTietHoaDon;
DELETE FROM HoaDon;
GO

-- Reset identity
DBCC CHECKIDENT ('HoaDon', RESEED, 0);
DBCC CHECKIDENT ('ChiTietHoaDon', RESEED, 0);
GO

-- Thêm hóa đơn
INSERT INTO HoaDon (MaHoaDon, IDKhachHang, IDNhanVien, NgayLap, TongTien, LoaiDon, IDBan, PhuongThucThanhToan, TrangThai, TrangThaiDon)
VALUES
('HD240401', NULL, 2, '2026-04-01 11:30:00', 0, 1, 1, N'Tiền mặt', 1, 2),
('HD240402', NULL, 2, '2026-04-05 18:00:00', 0, 1, 2, N'Chuyển khoản', 1, 2),
('HD240404', NULL, 2, '2026-04-15 19:30:00', 0, 1, 3, N'Tiền mặt', 1, 2),
('HD240405', NULL, 3, '2026-04-20 11:00:00', 0, 1, 4, N'Chuyển khoản', 1, 2),
('HD240501', NULL, 2, '2026-05-01 12:00:00', 0, 1, 1, N'Tiền mặt', 1, 2),
('HD240403', NULL, 3, '2026-04-10 12:15:00', 0, 2, NULL, N'Tiền mặt', 1, 2),
('HD240406', NULL, 2, '2026-04-25 20:00:00', 0, 2, NULL, N'Tiền mặt', 1, 2);
GO

-- Thêm chi tiết hóa đơn
INSERT INTO ChiTietHoaDon (IDHoaDon, IDSanPham, SoLuong, DonGia, ThanhTien)
VALUES
(1, 1, 2, 35000, 70000), (1, 5, 1, 65000, 65000), (1, 11, 2, 12000, 24000), (1, 13, 2, 22000, 44000), (1, 8, 1, 59000, 59000),
(2, 3, 2, 39000, 78000), (2, 7, 1, 55000, 55000), (2, 12, 2, 25000, 50000), (2, 15, 1, 15000, 15000),
(3, 2, 1, 65000, 65000), (3, 11, 1, 12000, 12000), (3, 13, 1, 22000, 22000),
(4, 4, 2, 45000, 90000), (4, 6, 1, 65000, 65000), (4, 8, 2, 59000, 118000), (4, 9, 1, 49000, 49000), (4, 14, 3, 30000, 90000), (4, 16, 2, 12000, 24000),
(5, 1, 1, 35000, 35000), (5, 5, 1, 65000, 65000), (5, 12, 1, 25000, 25000),
(6, 3, 3, 39000, 117000), (6, 7, 2, 55000, 110000), (6, 11, 2, 12000, 24000), (6, 14, 2, 30000, 60000),
(7, 1, 2, 35000, 70000), (7, 4, 1, 45000, 45000), (7, 10, 1, 52000, 52000), (7, 12, 1, 25000, 25000), (7, 15, 2, 15000, 30000);
GO

-- Cập nhật tổng tiền cho từng hóa đơn
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 1) WHERE IDHoaDon = 1;
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 2) WHERE IDHoaDon = 2;
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 3) WHERE IDHoaDon = 3;
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 4) WHERE IDHoaDon = 4;
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 5) WHERE IDHoaDon = 5;
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 6) WHERE IDHoaDon = 6;
UPDATE HoaDon SET TongTien = (SELECT SUM(ThanhTien) FROM ChiTietHoaDon WHERE IDHoaDon = 7) WHERE IDHoaDon = 7;
GO

-- Kiểm tra
SELECT * FROM vw_DoanhThu ORDER BY NgayLap;
GO