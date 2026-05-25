-- LKS SMK Tingkat Provinsi Jawa Barat Tahun 2023
-- Bidang Lomba: Web Technologies
-- Database Dump for "Formify"
-- Structure and initial dummy data matching specifications exactly

SET FOREIGN_KEY_CHECKS=0;

-- --------------------------------------------------------
-- Table structure for table `users`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Dumping data for table `users`
-- --------------------------------------------------------
INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'User 1', 'user1@webtech.id', NULL, '$2y$12$AJYYop0qZ9/mdO3Dpb2Vn.2T.xdJRYm.vminZUzIE2J3G6gtyiprO', NULL, '2023-10-20 00:00:00', '2023-10-20 00:00:00'),
(2, 'User 2', 'user2@webtech.id', NULL, '$2y$12$8MHvX4fnGEESXQ8GyCd0/uGkhXNc2H67wz54Dx897ztjOU4g4tfkC', NULL, '2023-10-20 00:00:00', '2023-10-20 00:00:00'),
(3, 'User 3', 'user3@worldskills.org', NULL, '$2y$12$6/dod34UlyvAJnHPPiWzpujqudtzdQNo5SBoAPTVg.zcumoT6kbNW', NULL, '2023-10-20 00:00:00', '2023-10-20 00:00:00');

-- --------------------------------------------------------
-- Table structure for table `forms`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `forms`;
CREATE TABLE `forms` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `limit_one_response` tinyint(1) NOT NULL DEFAULT '0',
  `creator_id` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `forms_slug_unique` (`slug`),
  KEY `forms_creator_id_foreign` (`creator_id`),
  CONSTRAINT `forms_creator_id_foreign` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Dumping data for table `forms`
-- --------------------------------------------------------
INSERT INTO `forms` (`id`, `name`, `slug`, `description`, `limit_one_response`, `creator_id`, `created_at`, `updated_at`) VALUES
(1, 'Biodata - Web Tech Members', 'biodata', 'To save web tech members data', 1, 1, '2022-10-23 00:00:00', '2022-10-23 00:00:00'),
(2, 'HTML and CSS Skills - Quiz', 'htmlcss-quiz', 'Fundamental web tests', 1, 1, '2022-10-23 01:00:00', '2022-10-23 01:00:00'),
(3, 'Stacks of Web Tech Members', 'member-stacks', 'To collect all of favorite stacks', 1, 1, '2022-10-23 02:00:00', '2022-10-23 02:00:00');

-- --------------------------------------------------------
-- Table structure for table `allowed_domains`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `allowed_domains`;
CREATE TABLE `allowed_domains` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `form_id` bigint(20) unsigned NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `allowed_domains_form_id_foreign` (`form_id`),
  CONSTRAINT `allowed_domains_form_id_foreign` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Dumping data for table `allowed_domains`
-- --------------------------------------------------------
INSERT INTO `allowed_domains` (`id`, `form_id`, `domain`, `created_at`, `updated_at`) VALUES
(1, 1, 'webtech.id', '2022-10-23 00:00:00', '2022-10-23 00:00:00'),
(2, 3, 'webtech.id', '2022-10-23 02:00:00', '2022-10-23 02:00:00');

-- --------------------------------------------------------
-- Table structure for table `questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `questions`;
CREATE TABLE `questions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `form_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `choice_type` enum('short answer','paragraph','date','time','multiple choice','dropdown','checkboxes') NOT NULL,
  `choices` varchar(255) DEFAULT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `questions_form_id_foreign` (`form_id`),
  CONSTRAINT `questions_form_id_foreign` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Dumping data for table `questions`
-- --------------------------------------------------------
INSERT INTO `questions` (`id`, `form_id`, `name`, `choice_type`, `choices`, `is_required`, `created_at`, `updated_at`) VALUES
(1, 1, 'Name', 'short answer', NULL, 1, '2022-10-23 00:05:00', '2022-10-23 00:05:00'),
(2, 1, 'Address', 'paragraph', NULL, 0, '2022-10-23 00:06:00', '2022-10-23 00:06:00'),
(3, 1, 'Born Date', 'date', NULL, 1, '2022-10-23 00:07:00', '2022-10-23 00:07:00'),
(4, 1, 'Sex', 'multiple choice', 'Male,Female', 1, '2022-10-23 00:08:00', '2022-10-23 00:08:00');

-- --------------------------------------------------------
-- Table structure for table `responses`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `responses`;
CREATE TABLE `responses` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `form_id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `responses_form_id_foreign` (`form_id`),
  KEY `responses_user_id_foreign` (`user_id`),
  CONSTRAINT `responses_form_id_foreign` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `responses_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Dumping data for table `responses`
-- --------------------------------------------------------
INSERT INTO `responses` (`id`, `form_id`, `user_id`, `date`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2022-10-24 01:47:14', '2022-10-24 01:47:14', '2022-10-24 01:47:14'),
(2, 1, 2, '2022-10-24 02:03:27', '2022-10-24 02:03:27', '2022-10-24 02:03:27');

-- --------------------------------------------------------
-- Table structure for table `answers`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `answers`;
CREATE TABLE `answers` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `response_id` bigint(20) unsigned NOT NULL,
  `question_id` bigint(20) unsigned NOT NULL,
  `value` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `answers_response_id_foreign` (`response_id`),
  KEY `answers_question_id_foreign` (`question_id`),
  CONSTRAINT `answers_question_id_foreign` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `answers_response_id_foreign` FOREIGN KEY (`response_id`) REFERENCES `responses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Dumping data for table `answers`
-- --------------------------------------------------------
INSERT INTO `answers` (`id`, `response_id`, `question_id`, `value`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Budi Setiawan', '2022-10-24 01:47:14', '2022-10-24 01:47:14'),
(2, 1, 2, 'Jakarta, Indonesia', '2022-10-24 01:47:14', '2022-10-24 01:47:14'),
(3, 1, 3, '2004-05-05', '2022-10-24 01:47:14', '2022-10-24 01:47:14'),
(4, 1, 4, 'Male', '2022-10-24 01:47:14', '2022-10-24 01:47:14'),
(5, 2, 1, 'Ica Amalia', '2022-10-24 02:03:27', '2022-10-24 02:03:27'),
(6, 2, 2, 'Bandung', '2022-10-24 02:03:27', '2022-10-24 02:03:27'),
(7, 2, 3, '2006-08-01', '2022-10-24 02:03:27', '2022-10-24 02:03:27'),
(8, 2, 4, 'Female', '2022-10-24 02:03:27', '2022-10-24 02:03:27');

-- --------------------------------------------------------
-- Table structure for table `personal_access_tokens`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `personal_access_tokens`;
CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
