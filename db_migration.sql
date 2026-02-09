-- =========================================================
-- DB 구조 개선 및 데이터 마이그레이션 (MySQL 기준)
-- =========================================================
-- 주의: 운영 반영 전 반드시 전체 백업을 수행하세요.
-- =========================================================

START TRANSACTION;

-- 1) 신규 테이블 생성
-- 참가 주체 마스터 (개인/팀)
CREATE TABLE `entrants` (
	`entrant_id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
	`entrant_type` TINYINT(4) NOT NULL COMMENT '0 개인전, 1 팀전',
	`member_id` INT(11) NULL DEFAULT NULL COMMENT '개인전일 때 회원 아이디',
	`team_id` INT(11) NULL DEFAULT NULL COMMENT '팀전일 때 팀 아이디',
	`entrant_name` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`entrant_image_url` VARCHAR(512) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`is_dummy` TINYINT(1) NOT NULL DEFAULT '0',
	`created_by_member_id` INT(11) NOT NULL,
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	`legacy_participant_id` INT(11) NULL DEFAULT NULL COMMENT '마이그레이션 임시 키',
	PRIMARY KEY (`entrant_id`) USING BTREE,
	UNIQUE INDEX `uk_entrant_type_member` (`entrant_type`, `member_id`) USING BTREE,
	UNIQUE INDEX `uk_entrant_type_team` (`entrant_type`, `team_id`) USING BTREE,
	UNIQUE INDEX `uk_legacy_participant` (`legacy_participant_id`) USING BTREE
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 대회별 참가 엔트리 (기존 participant_id 재사용)
CREATE TABLE `event_entries` (
	`entry_id` INT(11) UNSIGNED NOT NULL COMMENT '기존 participant_id 재사용',
	`event_id` INT(11) UNSIGNED NOT NULL,
	`entrant_id` BIGINT(20) UNSIGNED NOT NULL,
	`entrant_type` TINYINT(4) NOT NULL COMMENT '0 개인전, 1 팀전',
	`checkin_dt` DATETIME NULL DEFAULT NULL,
	`is_dummy` TINYINT(1) NOT NULL DEFAULT '0',
	`created_by_member_id` INT(11) NOT NULL,
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`entry_id`) USING BTREE,
	UNIQUE INDEX `uk_event_entrant` (`event_id`, `entrant_id`) USING BTREE,
	INDEX `ix_event_id` (`event_id`) USING BTREE,
	INDEX `ix_entrant_id` (`entrant_id`) USING BTREE,
	CONSTRAINT `fk_event_entries_entrant` FOREIGN KEY (`entrant_id`) REFERENCES `entrants` (`entrant_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 대회별 참가 멤버 (팀 구성/체크인 기록)
CREATE TABLE `entry_members` (
	`entry_member_id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
	`entry_id` INT(11) UNSIGNED NOT NULL,
	`member_id` INT(11) NULL DEFAULT NULL,
	`member_name` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`member_image_url` VARCHAR(512) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`checkin_dt` DATETIME NULL DEFAULT NULL,
	`is_dummy` TINYINT(1) NOT NULL DEFAULT '0',
	`created_by_member_id` INT(11) NOT NULL,
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`entry_member_id`) USING BTREE,
	INDEX `ix_entry_id` (`entry_id`) USING BTREE,
	INDEX `ix_member_id` (`member_id`) USING BTREE,
	CONSTRAINT `fk_entry_members_entry` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 대진표 (v2)
CREATE TABLE `brackets_v2` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
	`event_id` INT(10) UNSIGNED NOT NULL,
	`round_depth` INT(11) NOT NULL,
	`match_order` INT(11) NOT NULL,
	`match_point` TINYINT(4) NOT NULL DEFAULT '1',
	`winner_entry_id` INT(11) UNSIGNED NULL DEFAULT NULL,
	`status` TINYINT(1) NOT NULL DEFAULT '0',
	`start_dt` DATETIME NULL DEFAULT NULL,
	`match_start_dt` DATETIME NULL DEFAULT NULL,
	`match_end_dt` DATETIME NULL DEFAULT NULL,
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`bracket_id`) USING BTREE,
	INDEX `ix_event_round_order` (`event_id`, `round_depth`, `match_order`) USING BTREE,
	INDEX `ix_winner_entry` (`winner_entry_id`) USING BTREE,
	CONSTRAINT `fk_brackets_winner_entry` FOREIGN KEY (`winner_entry_id`) REFERENCES `event_entries` (`entry_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 대진표 참가 엔트리 (v2)
CREATE TABLE `bracket_entries_v2` (
	`bracket_entry_id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL,
	`entry_id` INT(11) UNSIGNED NOT NULL,
	`score` TINYINT(4) NOT NULL DEFAULT '0',
	`status` TINYINT(1) NOT NULL DEFAULT '0',
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`bracket_entry_id`) USING BTREE,
	UNIQUE INDEX `uk_entry_bracket` (`entry_id`, `bracket_id`) USING BTREE,
	INDEX `ix_bracket_id` (`bracket_id`) USING BTREE,
	CONSTRAINT `fk_bracket_entries_bracket` FOREIGN KEY (`bracket_id`) REFERENCES `brackets_v2` (`bracket_id`),
	CONSTRAINT `fk_bracket_entries_entry` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 세트별 승패 기록 (v2)
CREATE TABLE `bracket_sets_v2` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL,
	`entry_id` INT(11) UNSIGNED NOT NULL,
	`set_order` TINYINT(4) NOT NULL,
	`winlose` TINYINT(1) NULL DEFAULT NULL,
	`judge_image_url` VARCHAR(512) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`bracket_id`, `entry_id`, `set_order`) USING BTREE,
	CONSTRAINT `fk_bracket_sets_bracket` FOREIGN KEY (`bracket_id`) REFERENCES `brackets_v2` (`bracket_id`),
	CONSTRAINT `fk_bracket_sets_entry` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 라운드 자동 판정 여부 (v2)
CREATE TABLE `bracket_groups_v2` (
	`event_id` INT(11) NOT NULL,
	`round_depth` INT(11) NOT NULL,
	`start_dt` DATETIME NULL DEFAULT NULL,
	`auto_judge` TINYINT(4) NULL DEFAULT '0',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`event_id`, `round_depth`) USING BTREE
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 2) entrants 적재 - 팀 (entrant_id는 team_id로 매핑)
INSERT INTO `entrants` (
	`entrant_type`,
	`member_id`,
	`team_id`,
	`entrant_name`,
	`entrant_image_url`,
	`is_dummy`,
	`created_by_member_id`,
	`created_at`,
	`updated_at`,
	`legacy_participant_id`
)
SELECT
	1 AS `entrant_type`,
	NULL AS `member_id`,
	p.`entrant_id` AS `team_id`,
	MAX(p.`entrant_name`) AS `entrant_name`,
	MAX(p.`entrant_image_url`) AS `entrant_image_url`,
	MAX(p.`dummy`) AS `is_dummy`,
	MAX(p.`create_member_id`) AS `created_by_member_id`,
	MIN(p.`create_dt`) AS `created_at`,
	MAX(p.`update_dt`) AS `updated_at`,
	NULL AS `legacy_participant_id`
FROM `participants` p
WHERE p.`participant_type` = 1
  AND p.`entrant_id` IS NOT NULL
GROUP BY p.`entrant_id`;

-- 3) entrants 적재 - 개인 (member_id 존재)
INSERT INTO `entrants` (
	`entrant_type`,
	`member_id`,
	`team_id`,
	`entrant_name`,
	`entrant_image_url`,
	`is_dummy`,
	`created_by_member_id`,
	`created_at`,
	`updated_at`,
	`legacy_participant_id`
)
SELECT
	0 AS `entrant_type`,
	pm.`member_id` AS `member_id`,
	NULL AS `team_id`,
	MAX(pm.`member_name`) AS `entrant_name`,
	MAX(pm.`member_image_url`) AS `entrant_image_url`,
	MAX(p.`dummy`) AS `is_dummy`,
	MAX(p.`create_member_id`) AS `created_by_member_id`,
	MIN(p.`create_dt`) AS `created_at`,
	MAX(p.`update_dt`) AS `updated_at`,
	NULL AS `legacy_participant_id`
FROM `participants` p
INNER JOIN (
	SELECT
		pm.`participant_id`,
		MIN(pm.`member_id`) AS `member_id`,
		MAX(pm.`member_name`) AS `member_name`,
		MAX(pm.`member_image_url`) AS `member_image_url`
	FROM `participant_members` pm
	GROUP BY pm.`participant_id`
) pm ON pm.`participant_id` = p.`participant_id`
WHERE p.`participant_type` = 0
  AND pm.`member_id` IS NOT NULL
GROUP BY pm.`member_id`;

-- 4) entrants 적재 - 개인/팀 (member_id, team_id 모두 없는 예외 케이스)
INSERT INTO `entrants` (
	`entrant_type`,
	`member_id`,
	`team_id`,
	`entrant_name`,
	`entrant_image_url`,
	`is_dummy`,
	`created_by_member_id`,
	`created_at`,
	`updated_at`,
	`legacy_participant_id`
)
SELECT
	p.`participant_type` AS `entrant_type`,
	NULL AS `member_id`,
	NULL AS `team_id`,
	p.`entrant_name` AS `entrant_name`,
	p.`entrant_image_url` AS `entrant_image_url`,
	p.`dummy` AS `is_dummy`,
	p.`create_member_id` AS `created_by_member_id`,
	p.`create_dt` AS `created_at`,
	p.`update_dt` AS `updated_at`,
	p.`participant_id` AS `legacy_participant_id`
FROM `participants` p
LEFT JOIN (
	SELECT
		pm.`participant_id`,
		MIN(pm.`member_id`) AS `member_id`
	FROM `participant_members` pm
	GROUP BY pm.`participant_id`
) pm ON pm.`participant_id` = p.`participant_id`
WHERE (p.`participant_type` = 0 AND pm.`member_id` IS NULL)
   OR (p.`participant_type` = 1 AND p.`entrant_id` IS NULL)
   OR (p.`participant_type` NOT IN (0, 1));

-- 5) event_entries 적재
INSERT INTO `event_entries` (
	`entry_id`,
	`event_id`,
	`entrant_id`,
	`entrant_type`,
	`checkin_dt`,
	`is_dummy`,
	`created_by_member_id`,
	`created_at`,
	`updated_at`
)
SELECT
	p.`participant_id` AS `entry_id`,
	p.`event_id`,
	CASE
		WHEN p.`participant_type` = 1 AND p.`entrant_id` IS NOT NULL THEN et.`entrant_id`
		WHEN p.`participant_type` = 0 AND pm.`member_id` IS NOT NULL THEN ei.`entrant_id`
		ELSE el.`entrant_id`
	END AS `entrant_id`,
	p.`participant_type` AS `entrant_type`,
	p.`checkin_dt`,
	p.`dummy` AS `is_dummy`,
	p.`create_member_id` AS `created_by_member_id`,
	p.`create_dt` AS `created_at`,
	p.`update_dt` AS `updated_at`
FROM `participants` p
LEFT JOIN (
	SELECT
		pm.`participant_id`,
		MIN(pm.`member_id`) AS `member_id`
	FROM `participant_members` pm
	GROUP BY pm.`participant_id`
) pm ON pm.`participant_id` = p.`participant_id`
LEFT JOIN `entrants` et
	ON et.`entrant_type` = 1
	AND et.`team_id` = p.`entrant_id`
LEFT JOIN `entrants` ei
	ON ei.`entrant_type` = 0
	AND ei.`member_id` = pm.`member_id`
LEFT JOIN `entrants` el
	ON el.`legacy_participant_id` = p.`participant_id`;

-- 6) entry_members 적재
INSERT INTO `entry_members` (
	`entry_id`,
	`member_id`,
	`member_name`,
	`member_image_url`,
	`checkin_dt`,
	`is_dummy`,
	`created_by_member_id`,
	`created_at`,
	`updated_at`
)
SELECT
	pm.`participant_id` AS `entry_id`,
	pm.`member_id`,
	pm.`member_name`,
	pm.`member_image_url`,
	pm.`checkin_dt`,
	pm.`dummy` AS `is_dummy`,
	pm.`create_member_id` AS `created_by_member_id`,
	pm.`create_dt` AS `created_at`,
	pm.`update_dt` AS `updated_at`
FROM `participant_members` pm;

-- 7) 대진표 데이터 이관
INSERT INTO `brackets_v2` (
	`bracket_id`,
	`event_id`,
	`round_depth`,
	`match_order`,
	`match_point`,
	`winner_entry_id`,
	`status`,
	`start_dt`,
	`match_start_dt`,
	`match_end_dt`,
	`created_at`,
	`updated_at`
)
SELECT
	b.`bracket_id`,
	b.`event_id`,
	b.`depth` AS `round_depth`,
	b.`order` AS `match_order`,
	b.`match_point`,
	NULLIF(b.`winner_entrant_id`, 0) AS `winner_entry_id`,
	b.`status`,
	b.`start_dt`,
	b.`match_start_dt`,
	b.`match_end_dt`,
	b.`created_at`,
	b.`updated_at`
FROM `brackets` b;

INSERT INTO `bracket_entries_v2` (
	`bracket_id`,
	`entry_id`,
	`score`,
	`status`,
	`created_at`,
	`updated_at`
)
SELECT
	be.`bracket_id`,
	be.`participant_id` AS `entry_id`,
	be.`score`,
	be.`status`,
	be.`created_at`,
	be.`updated_at`
FROM `bracket_entries` be;

INSERT INTO `bracket_sets_v2` (
	`bracket_id`,
	`entry_id`,
	`set_order`,
	`winlose`,
	`judge_image_url`,
	`created_at`,
	`updated_at`
)
SELECT
	bs.`bracket_id`,
	bs.`participant_id` AS `entry_id`,
	bs.`set_order`,
	bs.`winlose`,
	bs.`judge_image_url`,
	bs.`create_dt` AS `created_at`,
	bs.`update_dt` AS `updated_at`
FROM `bracket_sets` bs;

INSERT INTO `bracket_groups_v2` (
	`event_id`,
	`round_depth`,
	`start_dt`,
	`auto_judge`,
	`created_at`,
	`updated_at`
)
SELECT
	bg.`event_id`,
	bg.`depth` AS `round_depth`,
	bg.`start_dt`,
	bg.`auto_judge`,
	bg.`created_dt` AS `created_at`,
	bg.`updated_dt` AS `updated_at`
FROM `bracket_groups` bg;

-- 8) 기본 검증(디버깅) 쿼리
-- 참가/멤버 건수 비교
SELECT COUNT(*) AS `cnt_participants` FROM `participants`;
SELECT COUNT(*) AS `cnt_event_entries` FROM `event_entries`;
SELECT COUNT(*) AS `cnt_participant_members` FROM `participant_members`;
SELECT COUNT(*) AS `cnt_entry_members` FROM `entry_members`;

-- 대진표 건수 비교
SELECT COUNT(*) AS `cnt_brackets` FROM `brackets`;
SELECT COUNT(*) AS `cnt_brackets_v2` FROM `brackets_v2`;
SELECT COUNT(*) AS `cnt_bracket_entries` FROM `bracket_entries`;
SELECT COUNT(*) AS `cnt_bracket_entries_v2` FROM `bracket_entries_v2`;
SELECT COUNT(*) AS `cnt_bracket_sets` FROM `bracket_sets`;
SELECT COUNT(*) AS `cnt_bracket_sets_v2` FROM `bracket_sets_v2`;

-- FK 기준 누락 여부 확인
SELECT COUNT(*) AS `cnt_null_entrant_id`
FROM `event_entries`
WHERE `entrant_id` IS NULL;

SELECT COUNT(*) AS `cnt_invalid_winner_entry`
FROM `brackets_v2` b
LEFT JOIN `event_entries` e ON e.`entry_id` = b.`winner_entry_id`
WHERE b.`winner_entry_id` IS NOT NULL
  AND e.`entry_id` IS NULL;

-- 9) 테이블 교체 (선택)
-- 주의: 실제 반영 시 서비스 중단/락 고려 필요
-- RENAME TABLE `participants` TO `participants_legacy`,
--              `participant_members` TO `participant_members_legacy`,
--              `brackets` TO `brackets_legacy`,
--              `bracket_entries` TO `bracket_entries_legacy`,
--              `bracket_sets` TO `bracket_sets_legacy`,
--              `bracket_groups` TO `bracket_groups_legacy`,
--              `brackets_v2` TO `brackets`,
--              `bracket_entries_v2` TO `bracket_entries`,
--              `bracket_sets_v2` TO `bracket_sets`,
--              `bracket_groups_v2` TO `bracket_groups`;

-- 10) 마이그레이션 임시 컬럼 정리 (선택, 검증 후 수행)
-- ALTER TABLE `entrants` DROP COLUMN `legacy_participant_id`;
-- ALTER TABLE `entrants` DROP INDEX `uk_legacy_participant`;

COMMIT;
