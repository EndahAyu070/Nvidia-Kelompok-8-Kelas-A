
-- =====================================================
-- PABW P20 - KELOMPOK 8 TIM NVIDIA
-- Sistem E-Katalog dan Lelang Pengadaan Pemerintah Daerah
-- Acuan utama: ERD P19
-- =====================================================

CREATE DATABASE IF NOT EXISTS db_ekatalog_etender
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE db_ekatalog_etender;


-- 1. PENGGUNA
CREATE TABLE pengguna (
    id_pengguna INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    peran ENUM(
        'admin_ukpbj',
        'pejabat_pengadaan',
        'vendor'
    ) NOT NULL,
    status_aktif BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_pengguna)
) ENGINE=InnoDB;


-- 2. KATEGORI
CREATE TABLE kategori (
    id_kategori INT NOT NULL AUTO_INCREMENT,
    nama_kategori VARCHAR(100) NOT NULL,
    deskripsi TEXT NULL,
    PRIMARY KEY (id_kategori)
) ENGINE=InnoDB;


-- 3. VENDOR
CREATE TABLE vendor (
    id_vendor INT NOT NULL AUTO_INCREMENT,
    id_pengguna INT NOT NULL,
    nama_perusahaan VARCHAR(150) NOT NULL,
    npwp VARCHAR(25) NOT NULL,
    nib VARCHAR(25) NOT NULL,
    alamat TEXT NOT NULL,
    status_verifikasi ENUM(
        'menunggu',
        'terverifikasi',
        'ditolak'
    ) NOT NULL DEFAULT 'menunggu',
    PRIMARY KEY (id_vendor),
    CONSTRAINT uq_vendor_pengguna UNIQUE (id_pengguna),
    CONSTRAINT fk_vendor_pengguna
        FOREIGN KEY (id_pengguna)
        REFERENCES pengguna(id_pengguna)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 4. PRODUK_KATALOG
CREATE TABLE produk_katalog (
    id_produk INT NOT NULL AUTO_INCREMENT,
    id_vendor INT NOT NULL,
    id_kategori INT NOT NULL,
    kode_produk VARCHAR(30) NOT NULL,
    nama_produk VARCHAR(150) NOT NULL,
    spesifikasi TEXT NOT NULL,
    harga_tayang DECIMAL(15,2) NOT NULL,
    stok INT NOT NULL DEFAULT 0,
    status_tayang ENUM(
        'draft',
        'menunggu_verifikasi',
        'tayang',
        'nonaktif'
    ) NOT NULL DEFAULT 'draft',
    PRIMARY KEY (id_produk),

    CONSTRAINT chk_produk_stok
        CHECK (stok >= 0),

    CONSTRAINT fk_produk_vendor
        FOREIGN KEY (id_vendor)
        REFERENCES vendor(id_vendor)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_produk_kategori
        FOREIGN KEY (id_kategori)
        REFERENCES kategori(id_kategori)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 5. PAKET_TENDER
CREATE TABLE paket_tender (
    id_tender INT NOT NULL AUTO_INCREMENT,
    id_pembuat INT NOT NULL,
    kode_tender VARCHAR(30) NOT NULL,
    nama_paket VARCHAR(150) NOT NULL,
    pagu_anggaran DECIMAL(15,2) NOT NULL,
    waktu_buka DATETIME NOT NULL,
    waktu_tutup DATETIME NOT NULL,
    status_tender ENUM(
        'draft',
        'dibuka',
        'evaluasi',
        'selesai',
        'batal'
    ) NOT NULL DEFAULT 'draft',
    PRIMARY KEY (id_tender),

    CONSTRAINT fk_tender_pembuat
        FOREIGN KEY (id_pembuat)
        REFERENCES pengguna(id_pengguna)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 6. PESERTA_TENDER
CREATE TABLE peserta_tender (
    id_peserta INT NOT NULL AUTO_INCREMENT,
    id_tender INT NOT NULL,
    id_vendor INT NOT NULL,
    waktu_daftar DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_kualifikasi ENUM(
        'terdaftar',
        'lolos_kualifikasi',
        'gugur'
    ) NOT NULL DEFAULT 'terdaftar',
    PRIMARY KEY (id_peserta),
    CONSTRAINT uq_tender_vendor
        UNIQUE (id_tender, id_vendor),

    CONSTRAINT fk_peserta_tender
        FOREIGN KEY (id_tender)
        REFERENCES paket_tender(id_tender)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_peserta_vendor
        FOREIGN KEY (id_vendor)
        REFERENCES vendor(id_vendor)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 7. PENAWARAN
CREATE TABLE penawaran (
    id_penawaran INT NOT NULL AUTO_INCREMENT,
    id_peserta INT NOT NULL,
    nilai_penawaran DECIMAL(15,2) NOT NULL,
    waktu_kirim_server DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hash_integritas_waktu VARCHAR(64) NOT NULL,
    status_penawaran ENUM(
        'terkirim',
        'sah',
        'gugur'
    ) NOT NULL DEFAULT 'terkirim',
    PRIMARY KEY (id_penawaran),
    CONSTRAINT uq_penawaran_peserta UNIQUE (id_peserta),

    CONSTRAINT fk_penawaran_peserta
        FOREIGN KEY (id_peserta)
        REFERENCES peserta_tender(id_peserta)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 8. DOKUMEN_PENAWARAN
CREATE TABLE dokumen_penawaran (
    id_dokumen INT NOT NULL AUTO_INCREMENT,
    id_penawaran INT NOT NULL,
    nama_file VARCHAR(255) NOT NULL,
    jenis_dokumen ENUM(
        'administrasi',
        'teknis',
        'harga',
        'lainnya'
    ) NOT NULL,
    path_storage VARCHAR(255) NOT NULL,
    checksum_sha256 VARCHAR(64) NOT NULL,
    iv_enkripsi VARCHAR(32) NOT NULL,
    ukuran_byte BIGINT NOT NULL,
    PRIMARY KEY (id_dokumen),

    CONSTRAINT fk_dokumen_penawaran
        FOREIGN KEY (id_penawaran)
        REFERENCES penawaran(id_penawaran)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 9. EVALUASI_PENAWARAN
CREATE TABLE evaluasi_penawaran (
    id_evaluasi INT NOT NULL AUTO_INCREMENT,
    id_penawaran INT NOT NULL,
    id_evaluator INT NOT NULL,
    skor_administrasi DECIMAL(5,2) NOT NULL,
    skor_teknis DECIMAL(5,2) NOT NULL,
    skor_harga DECIMAL(5,2) NOT NULL,
    status_rekomendasi ENUM(
        'lulus',
        'tidak_lulus',
        'pemenang'
    ) NOT NULL,
    PRIMARY KEY (id_evaluasi),
    CONSTRAINT uq_evaluasi_penawaran UNIQUE (id_penawaran),

    CONSTRAINT fk_evaluasi_penawaran
        FOREIGN KEY (id_penawaran)
        REFERENCES penawaran(id_penawaran)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_evaluasi_evaluator
        FOREIGN KEY (id_evaluator)
        REFERENCES pengguna(id_pengguna)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 10. AUDIT_LOG
CREATE TABLE audit_log (
    id_log INT NOT NULL AUTO_INCREMENT,
    id_pengguna INT NULL,
    nama_tabel VARCHAR(50) NOT NULL,
    id_rekaman INT NULL,
    aksi ENUM(
        'INSERT',
        'UPDATE',
        'DELETE',
        'LOGIN',
        'ACCESS_DENIED',
        'TIME_TAMPER_ALERT'
    ) NOT NULL,
    data_lama JSON NULL,
    data_baru JSON NULL,
    ip_address VARCHAR(45) NOT NULL,
    waktu_aksi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log),

    CONSTRAINT fk_audit_pengguna
        FOREIGN KEY (id_pengguna)
        REFERENCES pengguna(id_pengguna)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- PEMERIKSAAN
SHOW TABLES;
