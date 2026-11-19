-- ============================================================================
-- DDL Script ERD Kelompok 8 - Tim Nvidia
-- Proyek: Sistem E-Katalog dan Lelang Pengadaan Pemerintah Daerah
-- ============================================================================

CREATE DATABASE IF NOT EXISTS db_ekatalog_etender
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_ekatalog_etender;

-- 1. Tabel pengguna
CREATE TABLE pengguna (
    id_pengguna INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    peran ENUM('admin_ukpbj', 'pejabat_pengadaan', 'vendor') NOT NULL,
    status_aktif BOOLEAN NOT NULL DEFAULT TRUE,
    dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Tabel vendor
CREATE TABLE vendor (
    id_vendor INT AUTO_INCREMENT PRIMARY KEY,
    id_pengguna INT NOT NULL UNIQUE,
    nama_perusahaan VARCHAR(150) NOT NULL,
    npwp VARCHAR(25) NOT NULL UNIQUE,
    nib VARCHAR(25) NOT NULL UNIQUE,
    alamat TEXT NOT NULL,
    no_telepon VARCHAR(20) NOT NULL,
    status_verifikasi ENUM('menunggu', 'terverifikasi', 'ditolak') NOT NULL DEFAULT 'menunggu',
    tanggal_terdaftar DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vendor_pengguna FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 3. Tabel kategori
CREATE TABLE kategori (
    id_kategori INT AUTO_INCREMENT PRIMARY KEY,
    nama_kategori VARCHAR(100) NOT NULL UNIQUE,
    deskripsi TEXT NULL
) ENGINE=InnoDB;

-- 4. Tabel produk_katalog
CREATE TABLE produk_katalog (
    id_produk INT AUTO_INCREMENT PRIMARY KEY,
    id_vendor INT NOT NULL,
    id_kategori INT NOT NULL,
    kode_produk VARCHAR(30) NOT NULL UNIQUE,
    nama_produk VARCHAR(150) NOT NULL,
    spesifikasi TEXT NOT NULL,
    satuan VARCHAR(30) NOT NULL,
    harga_tayang DECIMAL(15,2) NOT NULL,
    stok INT NOT NULL DEFAULT 0,
    status_tayang ENUM('draft', 'menunggu_verifikasi', 'tayang', 'nonaktif') NOT NULL DEFAULT 'draft',
    CONSTRAINT fk_produk_vendor FOREIGN KEY (id_vendor) REFERENCES vendor(id_vendor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_produk_kategori FOREIGN KEY (id_kategori) REFERENCES kategori(id_kategori)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 5. Tabel paket_tender
CREATE TABLE paket_tender (
    id_tender INT AUTO_INCREMENT PRIMARY KEY,
    id_pembuat INT NOT NULL,
    kode_tender VARCHAR(30) NOT NULL UNIQUE,
    nama_paket VARCHAR(150) NOT NULL,
    deskripsi_pekerjaan TEXT NOT NULL,
    pagu_anggaran DECIMAL(15,2) NOT NULL,
    waktu_buka DATETIME NOT NULL,
    waktu_tutup DATETIME NOT NULL,
    status_tender ENUM('draft', 'dibuka', 'evaluasi', 'selesai', 'batal') NOT NULL DEFAULT 'draft',
    CONSTRAINT fk_tender_pembuat FOREIGN KEY (id_pembuat) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 6. Tabel peserta_tender (Tabel Jembatan M:N paket_tender <-> vendor)
CREATE TABLE peserta_tender (
    id_peserta INT AUTO_INCREMENT PRIMARY KEY,
    id_tender INT NOT NULL,
    id_vendor INT NOT NULL,
    waktu_daftar DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_kualifikasi ENUM('terdaftar', 'lolos_kualifikasi', 'gugur') NOT NULL DEFAULT 'terdaftar',
    UNIQUE KEY uq_tender_vendor (id_tender, id_vendor),
    CONSTRAINT fk_peserta_tender FOREIGN KEY (id_tender) REFERENCES paket_tender(id_tender)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_peserta_vendor FOREIGN KEY (id_vendor) REFERENCES vendor(id_vendor)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 7. Tabel penawaran
CREATE TABLE penawaran (
    id_penawaran INT AUTO_INCREMENT PRIMARY KEY,
    id_peserta INT NOT NULL UNIQUE,
    nilai_penawaran DECIMAL(15,2) NOT NULL,
    waktu_kirim_server DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hash_integritas_waktu VARCHAR(64) NOT NULL,
    status_penawaran ENUM('terkirim', 'sah', 'gugur') NOT NULL DEFAULT 'terkirim',
    CONSTRAINT fk_penawaran_peserta FOREIGN KEY (id_peserta) REFERENCES peserta_tender(id_peserta)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 8. Tabel dokumen_penawaran
CREATE TABLE dokumen_penawaran (
    id_dokumen INT AUTO_INCREMENT PRIMARY KEY,
    id_penawaran INT NOT NULL,
    nama_file VARCHAR(255) NOT NULL,
    jenis_dokumen ENUM('administrasi', 'teknis', 'harga', 'lainnya') NOT NULL,
    path_storage VARCHAR(255) NOT NULL,
    checksum_sha256 VARCHAR(64) NOT NULL,
    iv_enkripsi VARCHAR(32) NOT NULL,
    ukuran_byte BIGINT NOT NULL,
    waktu_unggah DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dokumen_penawaran FOREIGN KEY (id_penawaran) REFERENCES penawaran(id_penawaran)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Tabel evaluasi_penawaran
CREATE TABLE evaluasi_penawaran (
    id_evaluasi INT AUTO_INCREMENT PRIMARY KEY,
    id_penawaran INT NOT NULL UNIQUE,
    id_evaluator INT NOT NULL,
    skor_administrasi DECIMAL(5,2) NOT NULL,
    skor_teknis DECIMAL(5,2) NOT NULL,
    skor_harga DECIMAL(5,2) NOT NULL,
    catatan_evaluasi TEXT NULL,
    status_rekomendasi ENUM('lulus', 'tidak_lulus', 'pemenang') NOT NULL,
    waktu_evaluasi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evaluasi_penawaran FOREIGN KEY (id_penawaran) REFERENCES penawaran(id_penawaran)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_evaluasi_evaluator FOREIGN KEY (id_evaluator) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 10. Tabel audit_log
CREATE TABLE audit_log (
    id_log BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_pengguna INT NULL,
    nama_tabel VARCHAR(50) NOT NULL,
    id_rekaman INT NULL,
    aksi ENUM('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'ACCESS_DENIED', 'TIME_TAMPER_ALERT') NOT NULL,
    data_lama JSON NULL,
    data_baru JSON NULL,
    ip_address VARCHAR(45) NOT NULL,
    waktu_aksi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_pengguna FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;
