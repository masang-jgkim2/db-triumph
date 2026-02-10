-- =========================================================
-- 브라켓 테이블 재구성 + 데이터 마이그레이션
-- 목적: FFA 구조(스테이지/그룹) 개념을 도입하고
--       싱글/더블 토너먼트 확장 가능하게 재설계
-- =========================================================
-- 주의: 운영 반영 전 반드시 전체 백업 수행
-- =========================================================

-- 0) 안전 모드(선택)
-- SET sql_safe_updates = 1;

-- 1) 신규 테이블 생성 (기존 테이블과 충돌 방지용 _v2)
CREATE TABLE `bracket_stages` (
	`stage_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`event_id` INT(10) UNSIGNED NOT NULL,
	`round_depth` INT(11) NOT NULL COMMENT '1:예선,2:본선,3:결선...',
	`round_title` VARCHAR(100) NULL DEFAULT NULL COMMENT '라운드 이름' COLLATE 'utf8mb4_unicode_ci',
	`bracket_side` ENUM('W','L','GF') NOT NULL DEFAULT 'W' COMMENT 'W:승자조, L:패자조, GF:결승' COLLATE 'utf8mb4_unicode_ci',
	`start_dt` DATETIME NULL DEFAULT NULL,
	`auto_judge` TINYINT(4) NULL DEFAULT '0',
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`stage_id`) USING BTREE,
	UNIQUE INDEX `uk_event_round_side` (`event_id`, `round_depth`, `bracket_side`) USING BTREE
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `bracket_groups_v2` (
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

CREATE TABLE `brackets_v2` (
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
		FOREIGN KEY (`group_id`) REFERENCES `bracket_groups_v2` (`group_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `bracket_entries_v2` (
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
		FOREIGN KEY (`bracket_id`) REFERENCES `brackets_v2` (`bracket_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `bracket_sets_v2` (
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
		FOREIGN KEY (`bracket_id`) REFERENCES `brackets_v2` (`bracket_id`)
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB;

-- 2) 데이터 마이그레이션
-- 2-1) 스테이지 생성: 기존 bracket_groups -> bracket_stages
INSERT INTO `bracket_stages` (
	`event_id`,
	`round_depth`,
	`round_title`,
	`bracket_side`,
	`start_dt`,
	`auto_judge`,
	`created_at`,
	`updated_at`
)
SELECT
	tBg.`event_id`,
	tBg.`depth` AS `round_depth`,
	NULL AS `round_title`,
	'W' AS `bracket_side`,
	tBg.`start_dt`,
	tBg.`auto_judge`,
	tBg.`created_dt` AS `created_at`,
	tBg.`updated_dt` AS `updated_at`
FROM `bracket_groups` tBg;

-- 2-2) 그룹 생성: 기존 brackets -> bracket_groups_v2
-- 상태 매핑: 0(생성)=대기, 1/2(진행/판정중)=진행중, 4(판정완료)=완료
INSERT INTO `bracket_groups_v2` (
	`stage_id`,
	`group_order`,
	`max_capacity`,
	`winners_per_group`,
	`status`,
	`created_at`,
	`updated_at`
)
SELECT
	tBs.`stage_id`,
	tBr.`order` AS `group_order`,
	2 AS `max_capacity`,
	1 AS `winners_per_group`,
	CASE
		WHEN tBr.`status` = 4 THEN 2
		WHEN tBr.`status` IN (1, 2) THEN 1
		ELSE 0
	END AS `status`,
	tBr.`created_at`,
	tBr.`updated_at`
FROM `brackets` tBr
INNER JOIN `bracket_stages` tBs
	ON tBs.`event_id` = tBr.`event_id`
	AND tBs.`round_depth` = tBr.`depth`
	AND tBs.`bracket_side` = 'W';

-- 2-3) bracket_id -> group_id 매핑 테이블 (디버깅 겸용)
CREATE TEMPORARY TABLE `tmp_bracket_group_map` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL,
	`group_id` INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (`bracket_id`) USING BTREE,
	UNIQUE INDEX `uk_group_id` (`group_id`) USING BTREE
);

INSERT INTO `tmp_bracket_group_map` (`bracket_id`, `group_id`)
SELECT
	tBr.`bracket_id`,
	tBg.`group_id`
FROM `brackets` tBr
INNER JOIN `bracket_stages` tBs
	ON tBs.`event_id` = tBr.`event_id`
	AND tBs.`round_depth` = tBr.`depth`
	AND tBs.`bracket_side` = 'W'
INNER JOIN `bracket_groups_v2` tBg
	ON tBg.`stage_id` = tBs.`stage_id`
	AND tBg.`group_order` = tBr.`order`;

-- 2-4) 경기 생성: 기존 brackets -> brackets_v2
INSERT INTO `brackets_v2` (
	`bracket_id`,
	`group_id`,
	`match_order`,
	`match_point`,
	`winner_participant_id`,
	`status`,
	`start_dt`,
	`match_start_dt`,
	`match_end_dt`,
	`next_win_bracket_id`,
	`next_lose_bracket_id`,
	`created_at`,
	`updated_at`
)
SELECT
	tBr.`bracket_id`,
	tMap.`group_id`,
	1 AS `match_order`,
	tBr.`match_point`,
	NULLIF(tBr.`winner_entrant_id`, 0) AS `winner_participant_id`,
	tBr.`status`,
	tBr.`start_dt`,
	tBr.`match_start_dt`,
	tBr.`match_end_dt`,
	NULL AS `next_win_bracket_id`,
	NULL AS `next_lose_bracket_id`,
	tBr.`created_at`,
	tBr.`updated_at`
FROM `brackets` tBr
INNER JOIN `tmp_bracket_group_map` tMap
	ON tMap.`bracket_id` = tBr.`bracket_id`;

-- 2-5) 참가자 생성: 기존 bracket_entries -> bracket_entries_v2
-- 주의: 슬롯은 participant_id 기준 순서로 1,2... 부여
INSERT INTO `bracket_entries_v2` (
	`bracket_id`,
	`participant_id`,
	`slot_no`,
	`seed_no`,
	`score`,
	`status`,
	`is_bye`,
	`created_at`,
	`updated_at`
)
SELECT
	tBe.`bracket_id`,
	tBe.`participant_id`,
	ROW_NUMBER() OVER (PARTITION BY tBe.`bracket_id` ORDER BY tBe.`participant_id`) AS `slot_no`,
	NULL AS `seed_no`,
	tBe.`score`,
	tBe.`status`,
	0 AS `is_bye`,
	tBe.`created_at`,
	tBe.`updated_at`
FROM `bracket_entries` tBe;

-- MySQL 5.7 이하 대체안 (ROW_NUMBER 미지원)
-- SET @nRow := 0;
-- SET @nBr := 0;
-- INSERT INTO `bracket_entries_v2` (
-- 	`bracket_id`,
-- 	`participant_id`,
-- 	`slot_no`,
-- 	`seed_no`,
-- 	`score`,
-- 	`status`,
-- 	`is_bye`,
-- 	`created_at`,
-- 	`updated_at`
-- )
-- SELECT
-- 	tBe.`bracket_id`,
-- 	tBe.`participant_id`,
-- 	IF(@nBr = tBe.`bracket_id`, @nRow := @nRow + 1, @nRow := 1) AS `slot_no`,
-- 	NULL AS `seed_no`,
-- 	tBe.`score`,
-- 	tBe.`status`,
-- 	0 AS `is_bye`,
-- 	tBe.`created_at`,
-- 	tBe.`updated_at`,
-- 	@nBr := tBe.`bracket_id`
-- FROM `bracket_entries` tBe
-- ORDER BY tBe.`bracket_id`, tBe.`participant_id`;

-- 2-6) 세트 결과: 기존 bracket_sets -> bracket_sets_v2
INSERT INTO `bracket_sets_v2` (
	`bracket_id`,
	`participant_id`,
	`set_order`,
	`winlose`,
	`judge_image_url`,
	`created_at`,
	`updated_at`
)
SELECT
	tBs.`bracket_id`,
	tBs.`participant_id`,
	tBs.`set_order`,
	tBs.`winlose`,
	tBs.`judge_image_url`,
	tBs.`create_dt` AS `created_at`,
	tBs.`update_dt` AS `updated_at`
FROM `bracket_sets` tBs;

-- 3) 디버깅/검증 쿼리
SELECT COUNT(*) AS `cnt_brackets_old` FROM `brackets`;
SELECT COUNT(*) AS `cnt_brackets_new` FROM `brackets_v2`;
SELECT COUNT(*) AS `cnt_entries_old` FROM `bracket_entries`;
SELECT COUNT(*) AS `cnt_entries_new` FROM `bracket_entries_v2`;
SELECT COUNT(*) AS `cnt_sets_old` FROM `bracket_sets`;
SELECT COUNT(*) AS `cnt_sets_new` FROM `bracket_sets_v2`;

SELECT COUNT(*) AS `cnt_unmapped_brackets`
FROM `brackets` tBr
LEFT JOIN `tmp_bracket_group_map` tMap
	ON tMap.`bracket_id` = tBr.`bracket_id`
WHERE tMap.`bracket_id` IS NULL;

SELECT COUNT(*) AS `cnt_invalid_winner`
FROM `brackets_v2` tBr
LEFT JOIN `bracket_entries_v2` tBe
	ON tBe.`bracket_id` = tBr.`bracket_id`
	AND tBe.`participant_id` = tBr.`winner_participant_id`
WHERE tBr.`winner_participant_id` IS NOT NULL
  AND tBe.`participant_id` IS NULL;

-- 4) 테이블 교체 (서비스 중단 최소화, 필요 시 트랜잭션/락 적용)
-- 주의: 운영 반영 시 점검 후 수행
-- RENAME TABLE
--   `bracket_groups` TO `bracket_groups_legacy`,
--   `bracket_entries` TO `bracket_entries_legacy`,
--   `bracket_sets` TO `bracket_sets_legacy`,
--   `brackets` TO `brackets_legacy`,
--   `bracket_groups_v2` TO `bracket_groups`,
--   `bracket_entries_v2` TO `bracket_entries`,
--   `bracket_sets_v2` TO `bracket_sets`,
--   `brackets_v2` TO `brackets`;

-- 5) 임시 테이블 제거
DROP TEMPORARY TABLE IF EXISTS `tmp_bracket_group_map`;
