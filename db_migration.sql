-- =========================================================
-- 브래킷 개선 테이블 생성 (MariaDB 5.5)
-- =========================================================
-- 주의: 기존 브래킷 테이블 삭제 후 생성용
-- =========================================================

CREATE TABLE `bracket_stages` (
	`stage_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`event_id` INT(10) UNSIGNED NOT NULL,
	`round_depth` INT(11) NOT NULL COMMENT '1:예선,2:본선,3:결선...',
	`round_title` VARCHAR(100) NULL DEFAULT NULL COMMENT '라운드 이름' COLLATE 'utf8mb4_unicode_ci',
	`bracket_side` ENUM('W','L','GF') NOT NULL DEFAULT 'W' COMMENT 'W:승자조, L:패자조, GF:결승',
	`start_dt` DATETIME NULL DEFAULT NULL,
	`auto_judge` TINYINT(4) NULL DEFAULT '0',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`stage_id`) USING BTREE,
	UNIQUE INDEX `uk_event_round_side` (`event_id`, `round_depth`, `bracket_side`) USING BTREE
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `bracket_groups` (
	`group_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`stage_id` INT(10) UNSIGNED NOT NULL,
	`group_order` INT(11) NOT NULL COMMENT '1조,2조...',
	`max_capacity` INT(11) NOT NULL COMMENT '조 최대 참가 수',
	`winners_per_group` INT(11) NOT NULL DEFAULT '1' COMMENT '조당 진출 인원',
	`status` TINYINT(4) NOT NULL DEFAULT '0' COMMENT '0:대기,1:진행중,2:완료',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`group_id`) USING BTREE,
	UNIQUE INDEX `uk_stage_group` (`stage_id`, `group_order`) USING BTREE,
	INDEX `ix_stage_id` (`stage_id`) USING BTREE,
	CONSTRAINT `fk_bracket_groups_stage`
		FOREIGN KEY (`stage_id`) REFERENCES `bracket_stages` (`stage_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `brackets` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
	`group_id` INT(10) UNSIGNED NOT NULL,
	`match_order` INT(11) NOT NULL DEFAULT '1' COMMENT '그룹 내 경기 순서',
	`match_point` TINYINT(4) NOT NULL DEFAULT '1',
	`winner_participant_id` INT(11) UNSIGNED NULL DEFAULT NULL COMMENT '승자 참가자',
	`status` TINYINT(1) NOT NULL DEFAULT '0',
	`start_dt` DATETIME NULL DEFAULT NULL,
	`match_start_dt` DATETIME NULL DEFAULT NULL,
	`match_end_dt` DATETIME NULL DEFAULT NULL,
	`next_win_bracket_id` BIGINT(20) UNSIGNED NULL DEFAULT NULL COMMENT '승자 이동 경기',
	`next_lose_bracket_id` BIGINT(20) UNSIGNED NULL DEFAULT NULL COMMENT '패자 이동 경기',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`bracket_id`) USING BTREE,
	INDEX `ix_group_match` (`group_id`, `match_order`) USING BTREE,
	INDEX `ix_winner_participant` (`winner_participant_id`) USING BTREE,
	CONSTRAINT `fk_brackets_group`
		FOREIGN KEY (`group_id`) REFERENCES `bracket_groups` (`group_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `bracket_entries` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL,
	`participant_id` INT(10) UNSIGNED NOT NULL,
	`slot_no` TINYINT(4) NOT NULL DEFAULT '1' COMMENT '1P/2P 슬롯',
	`seed_no` INT(11) NULL DEFAULT NULL COMMENT '시드 번호',
	`score` TINYINT(4) NOT NULL DEFAULT '0',
	`status` TINYINT(1) NOT NULL DEFAULT '0',
	`is_bye` TINYINT(1) NOT NULL DEFAULT '0' COMMENT '부전승 여부',
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`bracket_id`, `participant_id`) USING BTREE,
	UNIQUE INDEX `uk_bracket_slot` (`bracket_id`, `slot_no`) USING BTREE,
	INDEX `ix_participant_id` (`participant_id`) USING BTREE,
	CONSTRAINT `fk_bracket_entries_bracket`
		FOREIGN KEY (`bracket_id`) REFERENCES `brackets` (`bracket_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `bracket_sets` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL,
	`participant_id` INT(10) UNSIGNED NOT NULL,
	`set_order` TINYINT(4) NOT NULL,
	`winlose` TINYINT(1) NULL DEFAULT NULL,
	`judge_image_url` VARCHAR(512) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`bracket_id`, `participant_id`, `set_order`) USING BTREE,
	INDEX `ix_bracket_id` (`bracket_id`) USING BTREE,
	CONSTRAINT `fk_bracket_sets_bracket`
		FOREIGN KEY (`bracket_id`) REFERENCES `brackets` (`bracket_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;
