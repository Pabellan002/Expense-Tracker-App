-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 21, 2025 at 12:57 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `expense_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `tbl_categories`
--

CREATE TABLE `tbl_categories` (
  `category_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `type` enum('income','expense') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_categories`
--

INSERT INTO `tbl_categories` (`category_id`, `name`, `type`, `created_at`) VALUES
(1, 'Salary', 'income', '2025-03-04 14:55:43'),
(2, 'Business', 'income', '2025-03-04 14:55:43'),
(3, 'Investment', 'income', '2025-03-04 14:55:43'),
(4, 'Food', 'expense', '2025-03-04 14:55:43'),
(5, 'Transportation', 'expense', '2025-03-04 14:55:43'),
(6, 'Shopping', 'expense', '2025-03-04 14:55:43'),
(7, 'Bills', 'expense', '2025-03-04 14:55:43'),
(8, 'Entertainment', 'expense', '2025-03-04 14:55:43');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_payment_methods`
--

CREATE TABLE `tbl_payment_methods` (
  `method_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_payment_methods`
--

INSERT INTO `tbl_payment_methods` (`method_id`, `name`, `created_at`) VALUES
(1, 'Cash', '2025-03-04 14:55:43'),
(2, 'Bank Transfer', '2025-03-04 14:55:43'),
(3, 'Credit Card', '2025-03-04 14:55:43'),
(4, 'GCash', '2025-03-04 14:55:43'),
(5, 'Maya', '2025-03-04 14:55:43');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_subcategories`
--

CREATE TABLE `tbl_subcategories` (
  `subcategory_id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `name` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_subcategories`
--

INSERT INTO `tbl_subcategories` (`subcategory_id`, `category_id`, `name`, `created_at`) VALUES
(1, 1, 'Regular Salary', '2025-03-04 14:55:43'),
(2, 1, 'Overtime', '2025-03-04 14:55:43'),
(3, 1, 'Bonus', '2025-03-04 14:55:43'),
(4, 2, 'Sales', '2025-03-04 14:55:43'),
(5, 2, 'Services', '2025-03-04 14:55:43'),
(6, 3, 'Stocks', '2025-03-04 14:55:43'),
(7, 3, 'Crypto', '2025-03-04 14:55:43'),
(8, 4, 'Groceries', '2025-03-04 14:55:43'),
(9, 4, 'Restaurant', '2025-03-04 14:55:43'),
(10, 5, 'Fuel', '2025-03-04 14:55:43'),
(11, 5, 'Public Transport', '2025-03-04 14:55:43'),
(12, 6, 'Clothes', '2025-03-04 14:55:43'),
(13, 6, 'Electronics', '2025-03-04 14:55:43'),
(14, 7, 'Electricity', '2025-03-04 14:55:43'),
(15, 7, 'Water', '2025-03-04 14:55:43'),
(16, 7, 'Internet', '2025-03-04 14:55:43'),
(17, 8, 'Movies', '2025-03-04 14:55:43'),
(18, 8, 'Games', '2025-03-04 14:55:43');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_transactions`
--

CREATE TABLE `tbl_transactions` (
  `transaction_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` enum('income','expense') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `category_id` int(11) NOT NULL,
  `subcategory_id` int(11) DEFAULT NULL,
  `payment_method_id` int(11) NOT NULL,
  `note` text DEFAULT NULL,
  `transaction_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_transactions`
--

INSERT INTO `tbl_transactions` (`transaction_id`, `user_id`, `type`, `amount`, `category_id`, `subcategory_id`, `payment_method_id`, `note`, `transaction_date`, `created_at`, `updated_at`) VALUES
(160, 6, 'income', 1000.00, 1, 1, 1, 'budget this month', '2025-03-06', '2025-03-06 13:45:07', '2025-03-06 13:45:07'),
(161, 6, 'expense', 500.00, 4, 8, 1, 'kaon', '2025-03-06', '2025-03-06 13:45:20', '2025-03-06 13:45:20'),
(162, 6, 'income', 10000.00, 1, 1, 2, 'hahah', '2025-03-13', '2025-03-13 01:02:48', '2025-03-13 01:02:48'),
(164, 6, 'income', 5000.00, 1, 1, 3, '', '2025-03-21', '2025-03-21 09:30:01', '2025-03-21 09:30:01'),
(165, 6, 'expense', 5000.00, 5, 10, 2, '', '2025-03-21', '2025-03-21 09:30:36', '2025-03-21 09:30:36'),
(166, 7, 'income', 2000.00, 1, 1, 1, 'qwdqw', '2025-03-21', '2025-03-21 09:34:33', '2025-03-21 09:34:33'),
(167, 7, 'expense', 1100.00, 4, 8, 1, 'fqwqfw', '2025-03-21', '2025-03-21 09:34:44', '2025-03-21 09:34:44'),
(168, 8, 'income', 2000.00, 2, 4, 1, 'vkkbkh', '2025-03-21', '2025-03-21 10:29:11', '2025-03-21 10:29:11'),
(169, 8, 'expense', 1000.00, 5, 10, 1, 'vjkv', '2025-03-21', '2025-03-21 10:29:21', '2025-03-21 10:29:21'),
(170, 8, 'income', 1000.00, 1, 1, 2, 'jv u', '2025-03-21', '2025-03-21 10:53:07', '2025-03-21 10:53:07'),
(171, 8, 'expense', 500.00, 5, 10, 1, '', '2025-03-21', '2025-03-21 10:53:23', '2025-03-21 10:53:23'),
(172, 8, 'income', 500.00, 1, 2, 4, 'hdsh', '2025-03-21', '2025-03-21 10:55:37', '2025-03-21 10:55:37');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_users`
--

CREATE TABLE `tbl_users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `gender` enum('male','female','other') NOT NULL,
  `profile_image` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_users`
--

INSERT INTO `tbl_users` (`user_id`, `username`, `password`, `created_at`, `first_name`, `middle_name`, `last_name`, `gender`, `profile_image`) VALUES
(6, 'kitz234', '$2y$10$mWo8vIFNDrXRAtUDR1bypesS.8ofhJm702y.Ml2ILF7N8VX6dHk2i', '2025-03-06 13:44:39', 'romeo', 'montes', 'pabellan', 'male', NULL),
(7, 'chui234', '$2y$10$V.yIKWkErE.OXKRofcromulhuPYfw0JyfYzuEPI0k03AdTdYnH.ci', '2025-03-21 09:34:16', 'Romeo', 'Montes', 'Pabellan', 'male', NULL),
(8, 'kram234', '$2y$10$V7A4fYMBqa0FvDmfME0hPuoDGRVPzjL2D0X8fFFoFVxtHVB.LM3ai', '2025-03-21 09:49:36', 'kram', 'montes', 'pabellan', 'male', 'uploads/67dd4a101c24e.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_wallet_balances`
--

CREATE TABLE `tbl_wallet_balances` (
  `user_id` int(11) NOT NULL,
  `payment_method_id` int(11) NOT NULL,
  `balance` decimal(15,2) DEFAULT 0.00,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_wallet_balances`
--

INSERT INTO `tbl_wallet_balances` (`user_id`, `payment_method_id`, `balance`, `updated_at`) VALUES
(6, 1, 500.00, '2025-03-06 13:45:20'),
(6, 2, 5000.00, '2025-03-21 09:30:36'),
(6, 3, 5000.00, '2025-03-21 09:30:01'),
(7, 1, 900.00, '2025-03-21 09:34:44'),
(8, 1, 500.00, '2025-03-21 10:53:23'),
(8, 2, 1000.00, '2025-03-21 10:53:07'),
(8, 4, 500.00, '2025-03-21 10:55:37');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tbl_categories`
--
ALTER TABLE `tbl_categories`
  ADD PRIMARY KEY (`category_id`);

--
-- Indexes for table `tbl_payment_methods`
--
ALTER TABLE `tbl_payment_methods`
  ADD PRIMARY KEY (`method_id`);

--
-- Indexes for table `tbl_subcategories`
--
ALTER TABLE `tbl_subcategories`
  ADD PRIMARY KEY (`subcategory_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `tbl_transactions`
--
ALTER TABLE `tbl_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `subcategory_id` (`subcategory_id`),
  ADD KEY `payment_method_id` (`payment_method_id`);

--
-- Indexes for table `tbl_users`
--
ALTER TABLE `tbl_users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `tbl_wallet_balances`
--
ALTER TABLE `tbl_wallet_balances`
  ADD PRIMARY KEY (`user_id`,`payment_method_id`),
  ADD KEY `fk_wallet_payment` (`payment_method_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tbl_categories`
--
ALTER TABLE `tbl_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tbl_payment_methods`
--
ALTER TABLE `tbl_payment_methods`
  MODIFY `method_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tbl_subcategories`
--
ALTER TABLE `tbl_subcategories`
  MODIFY `subcategory_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `tbl_transactions`
--
ALTER TABLE `tbl_transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=173;

--
-- AUTO_INCREMENT for table `tbl_users`
--
ALTER TABLE `tbl_users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tbl_subcategories`
--
ALTER TABLE `tbl_subcategories`
  ADD CONSTRAINT `tbl_subcategories_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `tbl_categories` (`category_id`);

--
-- Constraints for table `tbl_transactions`
--
ALTER TABLE `tbl_transactions`
  ADD CONSTRAINT `tbl_transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `tbl_users` (`user_id`),
  ADD CONSTRAINT `tbl_transactions_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `tbl_categories` (`category_id`),
  ADD CONSTRAINT `tbl_transactions_ibfk_3` FOREIGN KEY (`subcategory_id`) REFERENCES `tbl_subcategories` (`subcategory_id`),
  ADD CONSTRAINT `tbl_transactions_ibfk_4` FOREIGN KEY (`payment_method_id`) REFERENCES `tbl_payment_methods` (`method_id`);

--
-- Constraints for table `tbl_wallet_balances`
--
ALTER TABLE `tbl_wallet_balances`
  ADD CONSTRAINT `fk_wallet_payment` FOREIGN KEY (`payment_method_id`) REFERENCES `tbl_payment_methods` (`method_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_wallet_user` FOREIGN KEY (`user_id`) REFERENCES `tbl_users` (`user_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
