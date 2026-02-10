-- =========================================================
-- FFA 포인트제 마이그레이션 예시 (brackets 계열 -> ffa 계열)
-- =========================================================
-- 가정:
-- 1) bracket 1건 = ffa_group 1건(2인 조)으로 간주
-- 2) participant_id는 동일하게 유지됨
-- 3) winlose는 score(1/0)로 변환
-- =========================================================

START TRANSACTION;

-- 1) ffa_stages 생성: bracket_groups -> ffa_stages
INSERT INTO `ffa_stages` (
	`event_id`,
	`round_depth`,
	`round_title`
)
SELECT DISTINCT
	tBracketGroups.`event_id`,
	tBracketGroups.`depth` AS `round_depth`,
	NULL AS `round_title`
FROM `bracket_groups` tBracketGroups;

-- (옵션) bracket_groups가 비어있고 brackets만 있는 경우
-- INSERT INTO `ffa_stages` (`event_id`, `round_depth`, `round_title`)
-- SELECT DISTINCT b.`event_id`, b.`depth`, NULL
-- FROM `brackets` b;

-- 2) ffa_groups 생성: brackets -> ffa_groups
-- status 매핑: 0(생성) -> 0(대기), 1/2(진행/판정중) -> 1(진행중), 4(판정완료) -> 2(완료)
INSERT INTO `ffa_groups` (
	`stage_id`,
	`group_order`,
	`max_capacity`,
	`winners_per_group`,
	`status`
)
SELECT
	tFfaStages.`stage_id`,
	tBrackets.`order` AS `group_order`,
	2 AS `max_capacity`,
	1 AS `winners_per_group`,
	CASE
		WHEN tBrackets.`status` = 0 THEN 0
		WHEN tBrackets.`status` IN (1, 2) THEN 1
		WHEN tBrackets.`status` = 4 THEN 2
		ELSE 0
	END AS `status`
FROM `brackets` tBrackets
INNER JOIN `ffa_stages` tFfaStages
	ON tFfaStages.`event_id` = tBrackets.`event_id`
	AND tFfaStages.`round_depth` = tBrackets.`depth`;

-- 3) bracket_id -> group_id 매핑 테이블 (디버깅/검증 겸용)
CREATE TEMPORARY TABLE `tmp_bracket_group_map` (
	`bracket_id` BIGINT(20) UNSIGNED NOT NULL,
	`group_id` INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (`bracket_id`) USING BTREE,
	UNIQUE INDEX `uk_group_id` (`group_id`) USING BTREE
);

INSERT INTO `tmp_bracket_group_map` (`bracket_id`, `group_id`)
SELECT
	tBrackets.`bracket_id`,
	tFfaGroups.`group_id`
FROM `brackets` tBrackets
INNER JOIN `ffa_stages` tFfaStages
	ON tFfaStages.`event_id` = tBrackets.`event_id`
	AND tFfaStages.`round_depth` = tBrackets.`depth`
INNER JOIN `ffa_groups` tFfaGroups
	ON tFfaGroups.`stage_id` = tFfaStages.`stage_id`
	AND tFfaGroups.`group_order` = tBrackets.`order`;

-- 4) ffa_group_results 생성: bracket_entries -> ffa_group_results
INSERT INTO `ffa_group_results` (
	`group_id`,
	`participant_id`,
	`total_score`,
	`rank_in_group`,
	`is_advanced`
)
SELECT
	tMap.`group_id`,
	tBracketEntries.`participant_id`,
	tBracketEntries.`score` AS `total_score`,
	CASE
		WHEN tBrackets.`winner_entrant_id` IS NULL OR tBrackets.`winner_entrant_id` = 0 THEN NULL
		WHEN tBrackets.`winner_entrant_id` = tBracketEntries.`participant_id` THEN 1
		ELSE 2
	END AS `rank_in_group`,
	CASE
		WHEN tBrackets.`winner_entrant_id` = tBracketEntries.`participant_id` THEN 1
		ELSE 0
	END AS `is_advanced`
FROM `bracket_entries` tBracketEntries
INNER JOIN `brackets` tBrackets
	ON tBrackets.`bracket_id` = tBracketEntries.`bracket_id`
INNER JOIN `tmp_bracket_group_map` tMap
	ON tMap.`bracket_id` = tBrackets.`bracket_id`;

-- 5) ffa_match_scores 생성: bracket_sets -> ffa_match_scores
-- 주의: judge_image_url 정보는 소실됨 (필요시 컬럼 추가 권장)
INSERT INTO `ffa_match_scores` (
	`group_id`,
	`participant_id`,
	`match_order`,
	`score`
)
SELECT
	tMap.`group_id`,
	tBracketSets.`participant_id`,
	tBracketSets.`set_order` AS `match_order`,
	CASE
		WHEN tBracketSets.`winlose` = 1 THEN 1
		WHEN tBracketSets.`winlose` = 0 THEN 0
		ELSE 0
	END AS `score`
FROM `bracket_sets` tBracketSets
INNER JOIN `tmp_bracket_group_map` tMap
	ON tMap.`bracket_id` = tBracketSets.`bracket_id`;

-- 6) 디버깅/검증 쿼리
SELECT COUNT(*) AS `cnt_brackets` FROM `brackets`;
SELECT COUNT(*) AS `cnt_ffa_groups` FROM `ffa_groups`;
SELECT COUNT(*) AS `cnt_bracket_entries` FROM `bracket_entries`;
SELECT COUNT(*) AS `cnt_ffa_group_results` FROM `ffa_group_results`;
SELECT COUNT(*) AS `cnt_bracket_sets` FROM `bracket_sets`;
SELECT COUNT(*) AS `cnt_ffa_match_scores` FROM `ffa_match_scores`;

SELECT COUNT(*) AS `cnt_unmapped_bracket_entries`
FROM `bracket_entries` tBracketEntries
LEFT JOIN `tmp_bracket_group_map` tMap
	ON tMap.`bracket_id` = tBracketEntries.`bracket_id`
WHERE tMap.`bracket_id` IS NULL;

SELECT COUNT(*) AS `cnt_unmapped_bracket_sets`
FROM `bracket_sets` tBracketSets
LEFT JOIN `tmp_bracket_group_map` tMap
	ON tMap.`bracket_id` = tBracketSets.`bracket_id`
WHERE tMap.`bracket_id` IS NULL;

COMMIT;
