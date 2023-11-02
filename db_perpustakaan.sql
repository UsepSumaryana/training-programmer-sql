-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 02, 2023 at 06:43 AM
-- Server version: 5.7.41
-- PHP Version: 7.4.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db_perpustakaan`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `list_peminjaman` (IN `p_id_anggota` INT)   begin
	SELECT 
	    p.id_peminjaman, 
	    p.id_buku,
	    b.judul,
	    p.tgl_pinjam,
	  	p.tgl_jatuh_tempo ,
	  	p.tgl_kembali
	FROM peminjaman p
	JOIN buku b ON p.id_buku = b.id_buku
	WHERE p.id_anggota = p_id_anggota
	ORDER BY p.tgl_pinjam DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_peminjaman` (IN `p_id_anggota` INT, IN `p_id_buku` INT, IN `p_tgl_pinjam` DATE, IN `p_lama_pinjam` INT, IN `p_keterangan` VARCHAR(100), OUT `p_error_msg` VARCHAR(100))   begin
	DECLARE v_stok INT;
  
	SELECT stok INTO v_stok
	FROM buku 
	WHERE id_buku = p_id_buku;

	IF v_stok = 0 THEN
    	SET p_error_msg = 'Stok buku yang diminta tidak tersedia';
	ELSE
		INSERT INTO peminjaman (id_anggota, id_buku, tgl_pinjam, tgl_jatuh_tempo, keterangan)
    	VALUES (p_id_anggota, p_id_buku, p_tgl_pinjam, DATE_ADD(p_tgl_pinjam, INTERVAL p_lama_pinjam DAY), p_keterangan);
   	END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `anggota`
--

CREATE TABLE `anggota` (
  `id_anggota` int(11) NOT NULL,
  `nama` varchar(128) DEFAULT NULL,
  `tgl_lahir` date DEFAULT NULL,
  `alamat` varchar(256) DEFAULT NULL,
  `email` varchar(64) DEFAULT NULL,
  `no_hp` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `anggota`
--

INSERT INTO `anggota` (`id_anggota`, `nama`, `tgl_lahir`, `alamat`, `email`, `no_hp`) VALUES
(1, 'Egan Jacobowicz', '2023-05-08', 'Suite 84', 'ejacobowicz0@hatena.ne.jp', '1551346086'),
(2, 'Rafi Scurr', '2023-09-28', 'Room 855', 'rscurr1@moonfruit.com', '5235933840'),
(3, 'Eduard Ledgerton', '2023-07-12', '11th Floor', 'eledgerton0@businessweek.com', '3765741222'),
(4, 'Imojean Milazzo', '2000-01-24', 'Room 1328', 'imilazzo1@bandcamp.com', '5731756128'),
(5, 'Garik Faber', '2000-12-12', 'Suite 39', 'gfaber2@webs.com', '7189813552'),
(6, 'Ellie Mauditt', '2000-09-11', 'Room 573', 'emauditt3@soundcloud.com', '7763356217'),
(7, 'Collie Cattlow', '2000-01-22', 'Suite 85', 'ccattlow4@istockphoto.com', '6143357154');

-- --------------------------------------------------------

--
-- Table structure for table `buku`
--

CREATE TABLE `buku` (
  `id_buku` int(11) NOT NULL,
  `judul` varchar(256) DEFAULT NULL,
  `pengarang` varchar(256) DEFAULT NULL,
  `stok` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `buku`
--

INSERT INTO `buku` (`id_buku`, `judul`, `pengarang`, `stok`) VALUES
(1, 'Day of the Crows, The (Le jour des corneilles)', 'Maribel Kerwick', 0),
(2, 'Kiki', 'Tito Hallifax', 1),
(3, 'Man Is Not a Bird (Covek nije tica)', 'Florida Reddie', 3),
(4, 'You\'re Next', 'Steffie Lisciandri', 4),
(5, 'Esther Kahn', 'Jonell Castanho', 5);

--
-- Triggers `buku`
--
DELIMITER $$
CREATE TRIGGER `trigger_update_stok` AFTER UPDATE ON `buku` FOR EACH ROW begin
	
	if old.stok > new.stok then
		set @stok_diff = old.stok - new.stok;
		set @keterangan = 'Pengurangan Stok';
	elseif old.stok < new.stok then
		set @stok_diff = new.stok - old.stok;
		set @keterangan = 'Penambahan Stok';
	end if;
	
	insert
		into log_buku(
			id_buku,
			tgl_log,
			perubahan_stok,
			keterangan
		)
		values (
			new.id_buku,
			current_date(),
			@stok_diff,
			@keterangan
		);
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `log_buku`
--

CREATE TABLE `log_buku` (
  `log_id` int(11) NOT NULL,
  `id_buku` int(11) DEFAULT NULL,
  `tgl_log` timestamp NULL DEFAULT NULL,
  `perubahan_stok` int(11) DEFAULT NULL,
  `keterangan` varchar(512) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `log_buku`
--

INSERT INTO `log_buku` (`log_id`, `id_buku`, `tgl_log`, `perubahan_stok`, `keterangan`) VALUES
(1, 2, '2023-11-01 17:00:00', 5, 'Penambahan Stok'),
(2, 2, '2023-11-01 17:00:00', 3, 'Pengurangan Stok'),
(3, 2, '2023-11-01 17:00:00', 1, 'Pengurangan Stok');

-- --------------------------------------------------------

--
-- Table structure for table `peminjaman`
--

CREATE TABLE `peminjaman` (
  `id_peminjaman` int(11) NOT NULL,
  `id_anggota` int(11) NOT NULL,
  `id_buku` int(11) NOT NULL,
  `tgl_pinjam` date DEFAULT NULL,
  `tgl_jatuh_tempo` date DEFAULT NULL,
  `tgl_kembali` date DEFAULT NULL,
  `keterangan` varchar(512) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `peminjaman`
--

INSERT INTO `peminjaman` (`id_peminjaman`, `id_anggota`, `id_buku`, `tgl_pinjam`, `tgl_jatuh_tempo`, `tgl_kembali`, `keterangan`) VALUES
(1, 1, 1, '2022-01-31', '2022-12-19', '2023-03-26', 'Person outside car inj in clsn w pick-up truck nontraf, init'),
(2, 2, 1, '2023-03-18', '2022-04-10', '2023-03-06', 'Encounter for supervision of normal pregnancy'),
(3, 3, 2, '2023-05-13', '2022-12-17', '2023-11-02', 'Disp fx of body of hamate bone, right wrist, init'),
(4, 4, 3, '2023-03-03', '2022-03-06', '2023-06-28', 'Burn of right eye and adnexa, part unspecified'),
(5, 5, 5, '2022-11-01', '2022-08-26', '2023-10-14', 'Contact with crocodile'),
(6, 6, 4, '2021-12-08', '2022-06-01', '2022-10-31', 'Non-prs chronic ulcer of unsp thigh w necrosis of muscle'),
(7, 7, 3, '2022-01-06', '2022-09-06', '2022-11-13', 'Legal intervnt w injury by handgun, bystand injured, subs'),
(8, 1, 2, '2022-05-07', '2022-04-05', '2023-11-02', 'Nondisp avulsion fracture of unsp ischium, init for opn fx'),
(9, 2, 1, '2023-06-21', '2022-11-05', '2022-11-08', 'Unsp fracture of left wrs/hnd, subs for fx w routn heal'),
(10, 3, 4, '2021-12-31', '2022-09-19', '2023-06-17', 'Functional disorders of polymorphonuclear neutrophils'),
(11, 1, 2, '2023-02-01', '2023-02-08', '2023-11-02', 'Pinjam buku novel'),
(66, 1, 2, '2023-02-11', '2023-02-18', '2023-11-02', 'Pinjam buku lagi'),
(68, 3, 2, '2023-01-11', '2023-02-18', NULL, 'Tes pinjam buku baru'),
(69, 1, 2, '2023-02-11', '2023-02-18', NULL, 'Pinjam buku lagi');

--
-- Triggers `peminjaman`
--
DELIMITER $$
CREATE TRIGGER `trigger_peminjaman_buku` AFTER INSERT ON `peminjaman` FOR EACH ROW UPDATE buku SET stok = stok - 1 WHERE id_buku = NEW.id_buku
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trigger_pengembalian_buku` AFTER UPDATE ON `peminjaman` FOR EACH ROW BEGIN
  IF NEW.tgl_kembali IS NOT NULL AND OLD.tgl_kembali IS NULL THEN
    UPDATE buku SET stok = stok + 1 WHERE id_buku = NEW.id_buku;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `summary_peminjaman_anggota`
-- (See below for the actual view)
--
CREATE TABLE `summary_peminjaman_anggota` (
`id_anggota` int(11)
,`nama` varchar(128)
,`tgl_lahir` date
,`alamat` varchar(256)
,`email` varchar(64)
,`no_hp` varchar(20)
,`jumlah_peminjaman` bigint(21)
,`jumlah_dipinjam` decimal(23,0)
,`jumlah_dikembalikan` decimal(23,0)
);

-- --------------------------------------------------------

--
-- Structure for view `summary_peminjaman_anggota`
--
DROP TABLE IF EXISTS `summary_peminjaman_anggota`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `summary_peminjaman_anggota`  AS SELECT `a`.`id_anggota` AS `id_anggota`, `a`.`nama` AS `nama`, `a`.`tgl_lahir` AS `tgl_lahir`, `a`.`alamat` AS `alamat`, `a`.`email` AS `email`, `a`.`no_hp` AS `no_hp`, count(`p`.`id_peminjaman`) AS `jumlah_peminjaman`, sum((case when isnull(`p`.`tgl_kembali`) then 1 else 0 end)) AS `jumlah_dipinjam`, sum((case when (`p`.`tgl_kembali` is not null) then 1 else 0 end)) AS `jumlah_dikembalikan` FROM (`peminjaman` `p` join `anggota` `a` on((`p`.`id_anggota` = `a`.`id_anggota`))) GROUP BY `a`.`id_anggota``id_anggota`  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `anggota`
--
ALTER TABLE `anggota`
  ADD PRIMARY KEY (`id_anggota`),
  ADD KEY `id_anggota` (`id_anggota`);

--
-- Indexes for table `buku`
--
ALTER TABLE `buku`
  ADD PRIMARY KEY (`id_buku`),
  ADD KEY `id_buku` (`id_buku`);

--
-- Indexes for table `log_buku`
--
ALTER TABLE `log_buku`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `log_id` (`log_id`),
  ADD KEY `id_buku` (`id_buku`);

--
-- Indexes for table `peminjaman`
--
ALTER TABLE `peminjaman`
  ADD PRIMARY KEY (`id_peminjaman`),
  ADD KEY `id_peminjaman` (`id_peminjaman`),
  ADD KEY `id_anggota` (`id_anggota`),
  ADD KEY `id_buku` (`id_buku`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `anggota`
--
ALTER TABLE `anggota`
  MODIFY `id_anggota` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `buku`
--
ALTER TABLE `buku`
  MODIFY `id_buku` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `log_buku`
--
ALTER TABLE `log_buku`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `peminjaman`
--
ALTER TABLE `peminjaman`
  MODIFY `id_peminjaman` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=70;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
