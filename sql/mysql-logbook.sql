SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

CREATE DATABASE IF NOT EXISTS `logbook` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `logbook`;

DROP TABLE IF EXISTS `alerts`;
CREATE TABLE `alerts` (
  `alert_id` int(10) UNSIGNED NOT NULL,
  `entry_id` int(10) UNSIGNED NOT NULL,
  `date` datetime NOT NULL,
  `alertdestination` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

TRUNCATE TABLE `alerts`;
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `category_id` int(10) UNSIGNED NOT NULL,
  `title` text NOT NULL,
  `description` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

TRUNCATE TABLE `categories`;
INSERT INTO `categories` (`category_id`, `title`, `description`) VALUES
(1, 'WLAN', 'Alles ohne Kabel'),
(2, 'Routing', 'L3'),
(3, 'Server', NULL);

DROP TABLE IF EXISTS `entries`;
CREATE TABLE `entries` (
  `entry_id` int(10) UNSIGNED NOT NULL,
  `edate` datetime NOT NULL,
  `title` text NOT NULL,
  `description` text NOT NULL,
  `author` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

TRUNCATE TABLE `entries`;
INSERT INTO `entries` (`entry_id`, `edate`, `title`, `description`, `author`) VALUES
(1, '2016-12-28 14:55:45', 'WLAN kaputtgemacht', 'Aber hallo.', 'CF');

DROP TABLE IF EXISTS `entry2categories`;
CREATE TABLE `entry2categories` (
  `entry_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

TRUNCATE TABLE `entry2categories`;
INSERT INTO `entry2categories` (`entry_id`, `category_id`) VALUES
(1, 1),
(1, 2);

DROP TABLE IF EXISTS `settings`;
CREATE TABLE `settings` (
  `setting` varchar(32) NOT NULL,
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

TRUNCATE TABLE `settings`;

ALTER TABLE `alerts`
  ADD PRIMARY KEY (`alert_id`),
  ADD KEY `logentry_id` (`entry_id`);

ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`);

ALTER TABLE `entries`
  ADD PRIMARY KEY (`entry_id`),
  ADD KEY `edate` (`edate`);

ALTER TABLE `entry2categories`
  ADD PRIMARY KEY (`entry_id`,`category_id`),
  ADD KEY `entry_id` (`entry_id`),
  ADD KEY `category_id` (`category_id`);

ALTER TABLE `settings`
  ADD UNIQUE KEY `setting` (`setting`);


ALTER TABLE `categories`
  MODIFY `category_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
ALTER TABLE `entries`
  MODIFY `entry_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;SET FOREIGN_KEY_CHECKS=1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
