-- --------------------------------------------------------
-- 호스트:                          172.31.9.207
-- 서버 버전:                        5.5.41-MariaDB-1ubuntu0.14.04.1-log - (Ubuntu)
-- 서버 OS:                        debian-linux-gnu
-- HeidiSQL 버전:                  12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
use triumph;

-- 테이블 triumph.brackets 구조 내보내기
CREATE TABLE IF NOT EXISTS `brackets` (
  `bracket_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `event_id` int(10) unsigned NOT NULL,
  `depth` int(11) NOT NULL,
  `order` int(11) NOT NULL,
  `match_point` tinyint(4) NOT NULL DEFAULT '1',
  `winner_entrant_id` int(11) NOT NULL DEFAULT '0',
  `status` tinyint(1) NOT NULL DEFAULT '0',
  `start_dt` datetime DEFAULT NULL,
  `match_start_dt` datetime DEFAULT NULL,
  `match_end_dt` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`bracket_id`),
  UNIQUE KEY `event_id_depth_order` (`event_id`,`depth`,`order`)
) ENGINE=InnoDB AUTO_INCREMENT=2729853 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 triumph.bracket_entries 구조 내보내기
CREATE TABLE IF NOT EXISTS `bracket_entries` (
  `participant_id` int(10) unsigned NOT NULL,
  `bracket_id` bigint(20) unsigned NOT NULL,
  `score` tinyint(4) NOT NULL DEFAULT '0',
  `status` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`bracket_id`,`participant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 triumph.bracket_groups 구조 내보내기
CREATE TABLE IF NOT EXISTS `bracket_groups` (
  `event_id` int(11) NOT NULL,
  `depth` int(11) NOT NULL,
  `start_dt` datetime DEFAULT NULL,
  `auto_judge` tinyint(4) DEFAULT '0',
  `created_dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_dt` datetime DEFAULT NULL,
  PRIMARY KEY (`event_id`,`depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 테이블 triumph.bracket_sets 구조 내보내기
CREATE TABLE IF NOT EXISTS `bracket_sets` (
  `bracket_id` bigint(20) NOT NULL,
  `participant_id` int(11) NOT NULL,
  `set_order` tinyint(4) NOT NULL,
  `winlose` tinyint(1) DEFAULT NULL,
  `judge_image_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `create_dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_dt` datetime DEFAULT NULL,
  PRIMARY KEY (`bracket_id`,`participant_id`,`set_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 triumph.participants 구조 내보내기
CREATE TABLE IF NOT EXISTS `participants` (
  `participant_id` int(11) NOT NULL AUTO_INCREMENT,
  `event_id` int(11) NOT NULL,
  `participant_type` tinyint(4) DEFAULT NULL,
  `entrant_id` int(11) DEFAULT NULL,
  `entrant_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entrant_image_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `checkin_dt` datetime DEFAULT NULL,
  `dummy` tinyint(1) NOT NULL,
  `create_member_id` int(11) NOT NULL,
  `create_dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_dt` datetime DEFAULT NULL,
  PRIMARY KEY (`participant_id`),
  KEY `event_id` (`event_id`)
) ENGINE=InnoDB AUTO_INCREMENT=211053 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 triumph.participant_members 구조 내보내기
CREATE TABLE IF NOT EXISTS `participant_members` (
  `participant_id` int(11) NOT NULL,
  `member_id` int(11) DEFAULT NULL,
  `member_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `member_image_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `checkin_dt` datetime DEFAULT NULL,
  `dummy` tinyint(1) NOT NULL,
  `create_member_id` int(11) NOT NULL,
  `create_dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_dt` datetime DEFAULT NULL,
  KEY `participant_id` (`participant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 프로시저 triumph.participant_member_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `participant_member_select`(
	IN `p_event_id` INT,
	IN `p_member_id` INT
)
BEGIN

SELECT
    `p`.*,
    `m`.`name` AS `member_name`
FROM `participants` AS `p`
LEFT JOIN `members` AS `m`
    ON `p`.`create_member_id` = `m`.`member_id`
WHERE `p`.`event_id` = p_event_id
AND `p`.`create_member_id` = p_member_id;

END//
DELIMITER ;

-- 프로시저 triumph.participant_team_member_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `participant_team_member_select`(
	IN `p_event_id_1` INT,
	IN `p_event_id_2` INT,
	IN `p_game_id` INT,
	IN `p_team_id` INT
)
BEGIN

SELECT
    `t_m`.`team_id`,
    `t_m`.`member_id`,
    `m`.`name` AS `member_name`,
    `p_g_m_i`.`val0` AS `member_game_nickname`,
    `t_m`.`status`,
    `t_m`.`grade`,
    `t_m`.`created_dt` AS `member_created_at`,
    `m`.`image_url` AS `member_profile_img_url`,
    CASE
        WHEN `p_m`.`member_id` IS NOT NULL THEN 1
        WHEN `p`.`create_member_id` IS NOT NULL THEN 1
        ELSE 0
    END AS `member_applied`
FROM `team_members` AS `t_m`
INNER JOIN `members` AS `m`
    ON `t_m`.`member_id` = `m`.`member_id`
    AND `m`.`status` = 2
LEFT JOIN `platform_games` AS `p_g`
    ON `p_g`.`game_id` = p_game_id
LEFT JOIN `platform_game_members` AS `p_g_m`
    ON `t_m`.`member_id` = `p_g_m`.`member_id`
    AND `p_g`.`platform_game_id` = `p_g_m`.`platform_game_id`
LEFT JOIN `platform_game_member_info` AS `p_g_m_i`
    ON `p_g_m`.`platform_game_member_id` = `p_g_m_i`.`platform_game_member_id`
LEFT JOIN `participant_members` AS `p_m`
    ON `p_m`.`member_id` = `t_m`.`member_id`
    AND EXISTS (
        SELECT 1
        FROM `participants`
        WHERE `participant_id` = `p_m`.`participant_id`
        AND `event_id` = p_event_id_1
    )
LEFT JOIN `participants` AS `p`
    ON `p`.`create_member_id` = `t_m`.`member_id`
    AND `p`.`event_id` = p_event_id_2
WHERE `t_m`.`team_id` = p_team_id
AND `t_m`.`status` = 1
ORDER BY `t_m`.`created_dt` ASC;
END//
DELIMITER ;

-- 프로시저 triumph.sp_brackets_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_brackets_delete`(
	IN `p_bracket_id` BIGINT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    DELETE FROM brackets WHERE bracket_id = p_bracket_id;

    SELECT ROW_COUNT() INTO ret;
    
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_brackets_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_brackets_insert`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_order` INT,
	IN `p_match_point` TINYINT,
	IN `p_winner_entrant_id` INT,
	IN `p_status` TINYINT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    INSERT INTO brackets (event_id, depth, `order`, match_point, winner_entrant_id, `status`, created_at, updated_at)
    VALUES (p_event_id, p_depth, p_order, p_match_point, p_winner_entrant_id, p_status, NOW(), NULL);

    SELECT ROW_COUNT() INTO ret;
    
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_brackets_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_brackets_select`(
	IN `p_bracket_id` BIGINT
)
BEGIN
    SELECT bracket_id, event_id, depth, `order`, match_point, winner_entrant_id, `status`, start_dt, created_at, updated_at
    FROM brackets
    WHERE bracket_id = p_bracket_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_brackets_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_brackets_update`(
	IN `p_bracket_id` BIGINT,
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_order` INT,
	IN `p_match_point` TINYINT,
	IN `p_winner_entrant_id` INT,
	IN `p_status` TINYINT,
	IN `p_start_dt` DATETIME,
	IN `p_match_start_dt` DATETIME,
	IN `p_match_end_dt` DATETIME
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    UPDATE brackets
    SET `depth` = p_depth, `order` = p_order, match_point = p_match_point
    , `winner_entrant_id` = p_winner_entrant_id, `status` = p_status
	 , `start_dt` = p_start_dt, `match_start_dt` = p_match_start_dt, `match_end_dt` = p_match_end_dt
	 , `updated_at` = NOW()
    WHERE bracket_id = p_bracket_id and event_id = p_event_id;

    SELECT ROW_COUNT() INTO ret;
    
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_brackets_update_auto_judge 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_brackets_update_auto_judge`(
	IN `p_event_id` INT(11),
	IN `p_depth` INT(11),
	IN `p_auto_judge` TINYINT
)
BEGIN

	DECLARE ret INT DEFAULT 0;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT 'EXP' AS 'RETURN';
	END;

	IF (p_event_id IS NULL OR p_depth IS NULL OR p_auto_judge IS NULL) THEN
		SELECT 'ERR' AS 'RETURN';
	ELSE
		
		UPDATE brackets
		SET auto_judge = p_auto_judge, updated_at = NOW()
		WHERE event_id = p_event_id AND depth = p_depth;
	
		SELECT ROW_COUNT() INTO ret;
	END IF;

	IF ret > 0 THEN
		SELECT 'SUC' AS 'RETURN';
	ELSE
		SELECT 'ERR' AS 'RETURN';
	END IF;

END//
DELIMITER ;

-- 프로시저 triumph.sp_brackets_update_group 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_brackets_update_group`(
	IN `p_event_id` INT(11),
	IN `p_depth` INT(11),
	IN `p_start_dt` DATETIME,
	IN `p_auto_judge` TINYINT
)
proc_main: BEGIN

	DECLARE ret INT DEFAULT 0;
	
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT 'EXP' AS 'RETURN';
	END;
	
	IF (p_event_id IS NULL OR p_depth IS NULL OR p_auto_judge IS NULL) THEN
		SELECT 'ERR' AS 'RETURN';
		LEAVE proc_main;
	END IF;

	UPDATE brackets
	SET start_dt = p_start_dt, auto_judge = p_auto_judge, updated_at = NOW()
	WHERE event_id = p_event_id AND depth = p_depth;

	SELECT ROW_COUNT() INTO ret;

	IF ret > 0 THEN
		SELECT 'SUC' AS 'RETURN';
	ELSE
		SELECT 'ERR' AS 'RETURN';
	END IF;

END;//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_delete`(
	IN `p_participant_id` INT,
	IN `p_bracket_id` BIGINT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    DELETE FROM bracket_entries
    WHERE participant_id = p_participant_id
    AND bracket_id = p_bracket_id;

    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_groups_participants_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_groups_participants_select`(
	IN `p_event_id` INT
)
BEGIN

SELECT
    br.bracket_id,
    br.event_id,
    br.depth,
    br.`order`,
    br.match_point,
    br.start_dt,
    br.winner_entrant_id,
    br.status,
    en.score,
    en.participant_id,
    pa.entrant_name,
    pa.participant_type,
    pa.dummy,
    en.status AS entry_status,
    pa.entrant_image_url AS image_url,
    (SELECT bg.auto_judge 
     FROM bracket_groups AS bg
     WHERE bg.event_id = br.event_id
       AND bg.depth   = br.depth
     LIMIT 1) AS auto_judge,
    (SELECT bg.start_dt 
     FROM bracket_groups AS bg
     WHERE bg.event_id = br.event_id
       AND bg.depth   = br.depth
     LIMIT 1) AS group_start_dt
FROM brackets AS br
LEFT JOIN bracket_entries AS en
    ON en.bracket_id = br.bracket_id
LEFT JOIN participants AS pa
    ON en.participant_id = pa.participant_id
WHERE br.event_id = p_event_id
ORDER BY br.depth DESC, br.`order` ASC;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_groups_participants_select2 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_groups_participants_select2`(
	IN `p_event_id` INT
)
BEGIN

SELECT
    `br`.`bracket_id`,
    `br`.`event_id`,
    `br`.`depth`,
    `br`.`order`,
    `br`.`match_point`,
    `br`.`start_dt`,
    `br`.`winner_entrant_id`,
    `br`.`status`,
    `en`.`score`,
    `en`.`participant_id`,
    `pa`.`entrant_name`,
    `pa`.`participant_type`,
    -- dummy가 필요 없다면 삭제
    `pa`.`dummy`,
    `en`.`status` AS `entry_status`,
    `pa`.`entrant_image_url` AS `image_url`,
    (SELECT `bg`.`auto_judge` 
     FROM `bracket_groups` `bg` 
     WHERE `bg`.`event_id` = `br`.`event_id` 
       AND `bg`.`depth` = `br`.`depth`
     LIMIT 1) AS `auto_judge`,
    (SELECT `bg`.`start_dt` 
     FROM `bracket_groups` `bg` 
     WHERE `bg`.`event_id` = `br`.`event_id` 
       AND `bg`.`depth` = `br`.`depth`
     LIMIT 1) AS `group_start_dt`
FROM `brackets` AS `br`
INNER JOIN `bracket_entries` AS `en`
    ON `en`.`bracket_id` = `br`.`bracket_id`
INNER JOIN `participants` AS `pa`
    ON `en`.`participant_id` = `pa`.`participant_id`
WHERE `br`.`event_id` = p_event_id
ORDER BY `br`.`depth` DESC, `br`.`order` ASC;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_insert`(
	IN `p_participant_id` INT,
	IN `p_bracket_id` BIGINT,
	IN `p_score` TINYINT,
	IN `p_status` TINYINT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    INSERT INTO bracket_entries (participant_id, bracket_id, score, `status`, created_at, updated_at)
    VALUES (p_participant_id, p_bracket_id, p_score, 0, NOW(), NULL);

    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_participants_members_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_participants_members_select`(
	IN `p_event_id` INT,
	IN `p_bracket_id` INT
)
BEGIN

SELECT
    `br`.`depth`,
    `br`.`order`,
    `br`.`match_point`,
    `ev`.`team_size`,
    `ev`.`member_id` AS `operators_member_id`,
    `me_oper`.`name` AS `operators_member_name`,
    `me_oper`.`image_url` AS `operators_member_image_url`,
    `b_e`.`participant_id`,
    `pa`.`participant_type`,
    `pa`.`entrant_id`,
    `pa`.`entrant_name`,
    `pa`.`entrant_image_url`,
    `pa`.`dummy` AS `is_dummy_team`,
    `me`.`member_id` AS `leader_member_id`,
    `me`.`image_url` AS `leader_member_image_url`,
    `me`.`name` AS `leader_member_name`,
    `p_m`.`member_id` AS `part_member_id`,
    `p_m`.`member_name` AS `part_member_name`,
    `p_m`.`member_image_url` AS `part_member_image_url`,
    `p_m`.`dummy` AS `is_dummy_member`
FROM `brackets` AS `br`
LEFT JOIN `events` AS `ev`
    ON `br`.`event_id` = `ev`.`event_id`
LEFT JOIN `members` AS `me_oper`
    ON `ev`.`member_id` = `me_oper`.`member_id`
LEFT JOIN `bracket_entries` AS `b_e`
    ON `br`.`bracket_id` = `b_e`.`bracket_id`
LEFT JOIN `participants` AS `pa`
    ON `b_e`.`participant_id` = `pa`.`participant_id`
LEFT JOIN `members` AS `me`
    ON `pa`.`create_member_id` = `me`.`member_id`
LEFT JOIN `participant_members` AS `p_m`
    ON `b_e`.`participant_id` = `p_m`.`participant_id`
WHERE `br`.`bracket_id` = p_bracket_id
AND `br`.`event_id` = p_event_id
ORDER BY `pa`.`participant_id` DESC;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_participants_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_participants_select`(
	IN `p_bracket_id` INT,
	IN `p_participant_id` INT
)
BEGIN

SELECT
    `pa`.`create_member_id`,
    `p_m`.`member_id`
FROM `bracket_entries` AS `b_e`
LEFT JOIN `participants` AS `pa`
    ON `b_e`.`participant_id` = `pa`.`participant_id`
LEFT JOIN `participant_members` AS `p_m`
    ON `b_e`.`participant_id` = `p_m`.`participant_id`
WHERE `b_e`.`participant_id` = p_participant_id
AND `b_e`.`bracket_id` = p_bracket_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_select`(
	IN `p_bracket_id` INT,
	IN `p_participant_id` INT
)
BEGIN

SELECT
    `b_e`.`participant_id`,
    `b_e`.`bracket_id`,
    `b_e`.`score`,
    `b_e`.`status`,
    `b_e`.`created_at`,
    `b_e`.`updated_at`,
    `pa`.`create_member_id`
FROM `bracket_entries` AS `b_e`
LEFT JOIN `participants` AS `pa`
    ON `b_e`.`participant_id` = `pa`.`participant_id`
WHERE `b_e`.`participant_id` = p_participant_id
AND `b_e`.`bracket_id` = p_bracket_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_single_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_single_delete`(
	IN `p_event_id` INT,
	IN `p_depth` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
	 
	 DELETE be
	 FROM brackets b inner join bracket_entries be
	 on b.bracket_id = be.bracket_id
	 WHERE event_id = p_event_id AND depth = p_depth;
	
    SELECT ROW_COUNT() INTO ret; 
    
	 IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_single_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_single_insert`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_entries` VARCHAR(2048)
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    
    DECLARE round1 INT DEFAULT 0;
    DECLARE i INT DEFAULT 1;
    
    DECLARE start_position INT DEFAULT 1;
    DECLARE end_position INT;
    DECLARE value INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp (bracket_id BIGINT, event_id INT, depth INT, `order` INT, participant_id INT);

    TRUNCATE tmp;

    WHILE start_position > 0 DO
        SET end_position = LOCATE(',', p_entries, start_position);

        IF end_position > 0 THEN
            SET value = SUBSTRING(p_entries, start_position, end_position - start_position);
        ELSE
            SET value = SUBSTRING(p_entries, start_position);
        END IF;

        INSERT INTO tmp(bracket_id, event_id, depth, `order`, participant_id)
        SELECT bracket_id, event_id, depth, `order`, value FROM brackets WHERE event_id = p_event_id AND depth = p_depth AND `order` = i;
			  
        SET start_position = IF(end_position > 0, end_position + 1, 0);
        
        IF start_position > 0 THEN
      	
        SET end_position = LOCATE(',', p_entries, start_position);

        IF end_position > 0 THEN
            SET value = SUBSTRING(p_entries, start_position, end_position - start_position);
        ELSE
            SET value = SUBSTRING(p_entries, start_position);
        END IF;

        INSERT INTO tmp(bracket_id, event_id, depth, `order`, participant_id)
        SELECT bracket_id, event_id, depth, `order`, value FROM brackets WHERE event_id = p_event_id AND depth = p_depth AND `order` = i;
			  
        SET start_position = IF(end_position > 0, end_position + 1, 0);
        END IF;

        SET i = i + 1;
    END WHILE;

    START TRANSACTION;	
	    
	    DELETE be 
	    FROM brackets b inner join bracket_entries be
	    on b.bracket_id = be.bracket_id 
	    WHERE event_id = p_event_id AND depth = p_depth;
	
	    INSERT INTO bracket_entries (bracket_id, participant_id)
	    SELECT bracket_id, participant_id FROM tmp WHERE participant_id is not null;
	    
	    SELECT ROW_COUNT() INTO ret; 
    
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
        COMMIT;
    ELSE
        SELECT 'ERR' AS 'RETURN';
        ROLLBACK;
    END IF;
    
	 DROP TEMPORARY TABLE IF EXISTS tmp;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entries_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entries_update`(
	IN `p_participant_id` INT,
	IN `p_bracket_id` BIGINT,
	IN `p_score` TINYINT,
	IN `p_status` TINYINT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    UPDATE bracket_entries
    SET score = p_score, `status` = p_status, updated_at = NOW()
    WHERE participant_id = p_participant_id
    AND bracket_id = p_bracket_id;

    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entry_sets_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entry_sets_delete`(
	IN `p_bracket_id` BIGINT,
	IN `p_participant_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DELETE bs
    FROM bracket_entries be LEFT JOIN bracket_sets bs 
    on be.bracket_id = bs.bracket_id and be.participant_id = bs.participant_id
    WHERE be.bracket_id = p_bracket_id and be.participant_id = p_participant_id;
    
    SELECT ROW_COUNT() INTO ret;
    
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
		  COMMIT;        
    ELSE
        SELECT 'ERR' AS 'RETURN';
        ROLLBACK;
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_entry_sets_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_entry_sets_insert`(
	IN `p_bracket_id` BIGINT,
	IN `p_participant_id` INT,
	IN `p_winlose` VARCHAR(64),
	IN `p_judgeimageurl` VARCHAR(4086)
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    
    DECLARE i INT DEFAULT 1; 

    DECLARE start_position_winlose INT DEFAULT 1;
    DECLARE end_position_winlose INT;
    DECLARE winlose INT DEFAULT 0;
    
    DECLARE start_position_judgeimageurl INT DEFAULT 1;
    DECLARE end_position_judgeimageurl INT;
    DECLARE judgeimageurl VARCHAR(256);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp (bracket_id BIGINT, participant_id INT, set_order TINYINT, _winlose TINYINT, judge_image_url VARCHAR(512));
    TRUNCATE tmp;

    WHILE start_position_winlose > 0 DO
        SET end_position_winlose = LOCATE(',', p_winlose, start_position_winlose);
        SET end_position_judgeimageurl = LOCATE(',', p_judgeimageurl, start_position_judgeimageurl);

        IF end_position_winlose > 0 THEN
            SET winlose = SUBSTRING(p_winlose, start_position_winlose, end_position_winlose - start_position_winlose);
            SET judgeimageurl = SUBSTRING(p_judgeimageurl, start_position_judgeimageurl, end_position_judgeimageurl - start_position_judgeimageurl);
        ELSE
            SET winlose = SUBSTRING(p_winlose, start_position_winlose);
            SET judgeimageurl = SUBSTRING(p_judgeimageurl, start_position_judgeimageurl);
        END IF;
        
        IF winlose >= 1 THEN SET winlose = 1; ELSE SET winlose = 0; END IF;

        INSERT INTO tmp(bracket_id, participant_id, set_order, _winlose, judge_image_url)
        SELECT bracket_id, participant_id, i, winlose, judgeimageurl
        FROM bracket_entries
        WHERE bracket_id = p_bracket_id and participant_id = p_participant_id;
        
        SET start_position_winlose = IF(end_position_winlose > 0, end_position_winlose + 1, 0);
        SET start_position_judgeimageurl = IF(end_position_judgeimageurl > 0, end_position_judgeimageurl + 1, 0);

        SET i = i + 1;
    END WHILE;
    
    START TRANSACTION;    
    DELETE bs
    FROM bracket_entries be LEFT JOIN bracket_sets bs 
    on be.bracket_id = bs.bracket_id and be.participant_id = bs.participant_id
    WHERE be.bracket_id = p_bracket_id and be.participant_id = p_participant_id;

    INSERT INTO bracket_sets (bracket_id, participant_id, set_order, winlose, judge_image_url, update_dt)
    SELECT bracket_id, participant_id, set_order, _winlose, judge_image_url, NOW() FROM tmp;
    
    SELECT ROW_COUNT() INTO ret;
    
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
		  COMMIT;        
    ELSE
        SELECT 'ERR' AS 'RETURN';
        ROLLBACK;
    END IF;
    
    DROP TEMPORARY TABLE IF EXISTS tmp;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_groups_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_groups_delete`(
	IN `p_event_id` INT,
	IN `p_depth` INT
)
proc_main: BEGIN

	DECLARE ret INT DEFAULT 0;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT 'EXP' AS 'RETURN';
	END;

	IF (p_event_id IS NULL OR p_depth IS NULL) THEN
		SELECT 'ERR' AS 'RETURN';
		LEAVE proc_main;
	END IF;

	DELETE FROM bracket_groups 
	WHERE event_id = p_event_id AND depth = p_depth;

	SELECT ROW_COUNT() INTO ret;

	IF ret > 0 THEN
		SELECT 'SUC' AS 'RETURN';
	ELSE
		SELECT 'ERR' AS 'RETURN';
	END IF;
END;//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_groups_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_groups_insert`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_start_dt` DATETIME,
	IN `p_auto_judge` TINYINT
)
BEGIN

	DECLARE ret INT DEFAULT 0;
	
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT 'EXP' AS 'RETURN';
	END;
	
	IF (p_event_id IS NULL OR p_depth IS NULL) THEN
		SELECT 'ERR' AS 'RETURN';
	ELSE 
		INSERT INTO bracket_groups (`event_id`, `depth`, `start_dt`, `auto_judge`)
		VALUES (p_event_id, p_depth, p_start_dt, p_auto_judge);

	SELECT ROW_COUNT() INTO ret;
	END IF;

	IF ret > 0 THEN
		SELECT 'SUC' AS 'RETURN';
	ELSE
		SELECT 'ERR' AS 'RETURN';
	END IF;

END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_groups_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_groups_select`(
	IN `p_event_id` INT,
	IN `p_depth` INT
)
BEGIN

	IF p_event_id > 0 THEN
		SELECT `event_id`, `depth`, `start_dt`, `auto_judge`, `created_dt`, `updated_dt`
		FROM bracket_groups
		WHERE event_id = p_event_id AND depth = p_depth;
	END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_groups_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_groups_update`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_start_dt` DATETIME,
	IN `p_auto_judge` TINYINT
)
proc_main: BEGIN

	DECLARE ret INT DEFAULT 0;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT 'EXP' AS 'RETURN';
	END;

	IF (p_event_id IS NULL OR p_depth IS NULL) THEN
		SELECT 'ERR' AS 'RETURN';
		LEAVE proc_main;
	END IF;

	UPDATE bracket_groups
	SET start_dt = p_start_dt, auto_judge = p_auto_judge, updated_dt = NOW()
	WHERE event_id = p_event_id AND depth = p_depth;

	SELECT ROW_COUNT() INTO ret;

	IF ret > 0 THEN
		SELECT 'SUC' AS 'RETURN';
	ELSE
		SELECT 'ERR' AS 'RETURN';
	END IF;

END;//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_sets_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_sets_delete`(
	IN `p_bracket_set_id` BIGINT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;

    DELETE FROM bracket_sets
    WHERE bracket_set_id = p_bracket_set_id;
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_sets_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_sets_insert`(
	IN `p_bracket_id` BIGINT,
	IN `p_participant_id` INT,
	IN `p_set_order` INT,
	IN `p_winlose` TINYINT,
	IN `p_judge_image_url` VARCHAR(255)
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    INSERT INTO bracket_sets (bracket_id, participant_id, set_order, winlose, judge_image_url, create_dt, update_dt)
    VALUES (p_bracket_id, p_participant_id, p_set_order, p_winlose, p_judge_image_url, NOW(), NULL);
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_sets_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_sets_select`(
    IN p_bracket_set_id BIGINT
)
BEGIN
    SELECT bracket_set_id, bracket_id, participant_id, set_order, winlose, judge_image_url, create_dt, update_dt
    FROM bracket_sets
    WHERE bracket_set_id = p_bracket_set_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_sets_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_sets_update`(
	IN `p_bracket_set_id` BIGINT,
	IN `p_score` TINYINT,
	IN `p_winlose` TINYINT,
	IN `p_judge_image_url` VARCHAR(255),
	IN `p_status` TINYINT,
	IN `p_set_end_dt` DATETIME
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    UPDATE bracket_sets
    SET winlose = p_winlose, judge_image_url = p_judge_image_url, update_dt = NOW()
    WHERE bracket_set_id = p_bracket_set_id;
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_single_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_single_delete`(
	IN `p_event_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    DELETE FROM brackets
    WHERE event_id = p_event_id;
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_single_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_single_insert`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_34` TINYINT,
	IN `p_points` VARCHAR(128)
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE rounds INT DEFAULT 1;

    DECLARE exponent INT ;
    
    DECLARE start_position INT DEFAULT 1;
    DECLARE end_position INT DEFAULT 1;
    DECLARE point INT DEFAULT 1;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;
    
    SET exponent = LOG(p_depth) / LOG(2);
    
    IF FIND_IN_SET(exponent,'1,2,3,4,5,6,7,8') > 0 THEN
	
    IF p_points = '' THEN
        SET p_points = '3,2,1,1,1'; 
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp (`event_id` INT(10) UNSIGNED NOT NULL,
    `depth` INT(11) NOT NULL,
    `order` INT(11) NOT NULL,
    `match_point` TINYINT(4) NOT NULL DEFAULT '1',
    `winner_entrant_id` INT(11) NOT NULL DEFAULT '0',
    `status` TINYINT(1) NOT NULL DEFAULT '2');

    TRUNCATE tmp;
		
    WHILE p_depth > rounds DO
        SET rounds = POW(2, i);
			
        SET end_position = LOCATE(',', p_points, start_position);

        IF end_position > 0 THEN
        SET point = SUBSTRING(p_points, start_position, end_position - start_position);
        ELSE
        SET point = SUBSTRING(p_points, start_position);
        END IF;
        
        IF point = 0 THEN SET point = 1; END IF;

        WHILE j <= rounds / 2 DO
            IF rounds = 2 AND p_34 = 1 THEN

                INSERT INTO tmp (event_id, depth, `order`, match_point, winner_entrant_id, `status`)
                VALUES (p_event_id, rounds, j, point, 0, 0)
                , (p_event_id, rounds, j + 1, point, 0, 0);

            ELSE

                INSERT INTO tmp (event_id, depth, `order`, match_point, winner_entrant_id, `status`)
                VALUES (p_event_id, rounds, j, point, 0, 0);
                END IF;
	
            SET j = j + 1;
        END WHILE;

        SET start_position = IF(end_position > 0, end_position + 1, 0);

        SET i = i + 1;
        SET j = 1;
        END WHILE;
	    
    END IF;

    START TRANSACTION;	
    
    DELETE FROM brackets 
    WHERE event_id = p_event_id;
	
    INSERT INTO brackets (event_id, depth, `order`, match_point, winner_entrant_id, `status`)
    SELECT event_id, depth, `order`, match_point, winner_entrant_id, `status` FROM tmp;
        
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';

        COMMIT;
    ELSE
        SELECT 'ERR' AS 'RETURN';

        ROLLBACK;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp;
END//
DELIMITER ;

-- 프로시저 triumph.sp_bracket_single_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_bracket_single_select`(
	IN `p_event_id` INT
)
BEGIN
    SELECT
    `bracket_id`,
	`event_id`,
	`depth`,
	`order`,
	`match_point`,
	`winner_entrant_id`,
	`status`,
	`created_at`,
	`updated_at`
    FROM brackets
    WHERE event_id = p_event_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_events_assign_participants 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_events_assign_participants`(
	IN `p_event_id` INT
)
BEGIN
    -- 에러 핸들러
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;

    START TRANSACTION;
    
    UPDATE `brackets` b
	 SET b.match_point = 5
    WHERE b.event_id = p_event_id;

    -- 1. 기존 할당 정보 초기화
    DELETE be FROM `bracket_entries` be
    INNER JOIN `brackets` b ON be.bracket_id = b.bracket_id
    WHERE b.event_id = p_event_id;

    -- 2. 임시 테이블: 대상 브라켓 순서대로 번호 부여
    DROP TEMPORARY TABLE IF EXISTS tmp_brackets;
    CREATE TEMPORARY TABLE tmp_brackets (
        row_idx INT AUTO_INCREMENT PRIMARY KEY,
        bracket_id BIGINT UNSIGNED
    );

    INSERT INTO tmp_brackets (bracket_id)
    SELECT bracket_id 
    FROM `brackets` 
    WHERE event_id = p_event_id 
      AND `depth` = (SELECT participant_capacity FROM `events` WHERE event_id = p_event_id)
    ORDER BY `order` ASC;

    -- 3. 임시 테이블: 참가자 랜덤하게 섞어서 번호 부여
    DROP TEMPORARY TABLE IF EXISTS tmp_participants;
    CREATE TEMPORARY TABLE tmp_participants (
        row_idx INT AUTO_INCREMENT PRIMARY KEY,
        participant_id INT UNSIGNED
    );

    INSERT INTO tmp_participants (participant_id)
    SELECT participant_id 
    FROM `participants` 
    WHERE event_id = p_event_id 
    ORDER BY RAND();

    -- 4. 브라켓과 참가자 매칭하여 한 번에 INSERT
    -- 참가자 번호(row_idx) 1, 2번은 브라켓 1번, 3, 4번은 브라켓 2번에 할당하는 로직
    -- 계산식: CEIL(참가자번호 / 2) = 브라켓번호
    INSERT INTO `bracket_entries` (bracket_id, participant_id, score, `status`, created_at)
    SELECT 
        b.bracket_id, 
        p.participant_id, 
        0, 0, NOW()
    FROM tmp_participants p
    INNER JOIN tmp_brackets b ON b.row_idx = CEIL(p.row_idx / 2);

    -- 5. 이벤트 상태 변경
    UPDATE `events` 
    SET `status` = 2 
    WHERE event_id = p_event_id;

    -- 임시 테이블 삭제
    DROP TEMPORARY TABLE IF EXISTS tmp_brackets;
    DROP TEMPORARY TABLE IF EXISTS tmp_participants;

    COMMIT;
    
    SELECT 'SUC' AS 'RETURN';

END//
DELIMITER ;

-- 프로시저 triumph.sp_events_bracket_participants_init 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_events_bracket_participants_init`(
	IN `p_event_id` INT
)
BEGIN
DELETE bs
FROM triumph.brackets b
LEFT OUTER JOIN bracket_entries be ON b.bracket_id = be.bracket_id
LEFT OUTER JOIN bracket_sets bs ON be.bracket_id = bs.bracket_id 
WHERE b.event_id = p_event_id;

DELETE be
FROM triumph.brackets b
LEFT OUTER JOIN bracket_entries be ON b.bracket_id = be.bracket_id
WHERE b.event_id = p_event_id;

UPDATE triumph.brackets b
SET b.winner_entrant_id = 0, b.`status` = 0
WHERE b.event_id = p_event_id;

SELECT 'SUC' AS 'RETURN';
END//
DELIMITER ;

-- 프로시저 triumph.sp_event_round_adjudicator 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_round_adjudicator`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_force_judge` TINYINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT p_event_id AS 'EVENT', 'EXCEPTION_ERROR' AS 'RETURN_RESULT';
    END;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_adj_targets;
    CREATE TEMPORARY TABLE tmp_adj_targets AS
    SELECT 
        b.bracket_id, b.depth, b.order, b.match_point, b.status as current_match_status,
        COUNT(be.participant_id) AS part_count,
        SUM(CASE WHEN p.dummy = 0 THEN 1 ELSE 0 END) AS real_user_count,
        SUM(CASE WHEN p.dummy = 0 AND be.status = 2 THEN 1 ELSE 0 END) AS ready_user_count,
        (SELECT COUNT(DISTINCT bs.participant_id) 
         FROM bracket_sets bs 
         WHERE bs.bracket_id = b.bracket_id) AS scored_part_count,
        IF(COUNT(be.participant_id) = 1, 1, 0) AS is_bye,
        (CASE WHEN EXISTS (
            SELECT 1 FROM `brackets` prev
            WHERE prev.event_id = b.event_id
              AND prev.depth = b.depth * 2
              AND prev.order IN (b.order * 2 - 1, b.order * 2)
              AND prev.status NOT IN (4, 9)
        ) THEN 0 ELSE 1 END) AS is_parent_finished
    FROM `brackets` b
    LEFT JOIN `bracket_entries` be ON b.bracket_id = be.bracket_id
    LEFT JOIN `participants` p ON be.participant_id = p.participant_id
    WHERE b.event_id = p_event_id AND b.depth = p_depth AND b.status NOT IN (4, 9)
    GROUP BY b.bracket_id, b.depth, b.order, b.match_point, b.status;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_process_matches;
    CREATE TEMPORARY TABLE tmp_process_matches AS
    SELECT *,
        IF(real_user_count = 1 AND part_count = 2, 1, 0) AS is_user_vs_dummy
    FROM tmp_adj_targets
    WHERE (is_parent_finished = 1 OR p_force_judge = 1)
      AND (
            (part_count = 0) 
            OR (p_force_judge = 1) 
            OR (part_count > 0 AND scored_part_count = part_count AND (
                (real_user_count = 0)
                OR (real_user_count > 0 AND ready_user_count = real_user_count)
            ))
      );
      
    IF EXISTS (SELECT 1 FROM tmp_process_matches WHERE scored_part_count = 2) THEN
    
    START TRANSACTION ;

        DROP TEMPORARY TABLE IF EXISTS tmp_adj_results;
        CREATE TEMPORARY TABLE tmp_adj_results AS
        SELECT 
            t.bracket_id, t.depth, t.order, be.participant_id, p.dummy,
            t.real_user_count, t.is_user_vs_dummy, t.part_count, t.is_bye,
            IFNULL(SUM(CASE WHEN bs.winlose = 1 THEN 1 ELSE 0 END), 0) AS final_score,
            COUNT(bs.bracket_id) AS total_set_records
        FROM tmp_process_matches t
        INNER JOIN `bracket_entries` be ON t.bracket_id = be.bracket_id
        LEFT JOIN `participants` p ON be.participant_id = p.participant_id
        LEFT JOIN `bracket_sets` bs ON be.bracket_id = bs.bracket_id AND be.participant_id = bs.participant_id
        GROUP BY t.bracket_id, be.participant_id;

        DROP TEMPORARY TABLE IF EXISTS tmp_winner_list;
        CREATE TEMPORARY TABLE tmp_winner_list AS
        SELECT 
            bracket_id,
            SUBSTRING_INDEX(GROUP_CONCAT(participant_id ORDER BY final_score DESC, dummy ASC, participant_id ASC), ',', 1) AS winner_id,
            MAX(final_score) AS max_score,
            MIN(final_score) AS min_score,
            IF(real_user_count = 2 AND MIN(final_score) = MAX(final_score), 1, 0) AS is_user_tie,
            IF(MAX(depth) > 4 AND SUM(total_set_records) = 0 AND p_force_judge = 0, 1, 0) AS is_both_lose
        FROM tmp_adj_results
        GROUP BY bracket_id
        UNION ALL
        SELECT bracket_id, 0, 0, 0, 0, 0 FROM tmp_process_matches WHERE part_count = 0;

        UPDATE `brackets` b 
        INNER JOIN tmp_winner_list w ON b.bracket_id = w.bracket_id
        SET b.winner_entrant_id = w.winner_id, 
            b.status = IF(w.is_both_lose = 1, 9, 4), 
            b.updated_at = NOW()
        WHERE w.is_user_tie = 0;

        UPDATE `bracket_entries` be
        INNER JOIN tmp_adj_results r ON be.bracket_id = r.bracket_id AND be.participant_id = r.participant_id
        INNER JOIN tmp_winner_list w ON be.bracket_id = w.bracket_id
        SET be.status = CASE 
                            WHEN w.is_both_lose = 1 THEN 9 
                            WHEN r.is_bye = 1 THEN 7 
                            WHEN be.participant_id = w.winner_id THEN 
                                CASE 
                                    WHEN r.is_user_vs_dummy = 1 THEN 
                                        IF(w.max_score > w.min_score, 1, 7)
                                    ELSE 1 
                                END
                            ELSE 2 
                        END,
            be.score = r.final_score, 
            be.updated_at = NOW()
        WHERE w.is_user_tie = 0;

        IF p_depth > 2 THEN
            DELETE be FROM `bracket_entries` be
            INNER JOIN `brackets` b ON be.bracket_id = b.bracket_id
            INNER JOIN tmp_winner_list w ON be.participant_id = w.winner_id
            WHERE b.event_id = p_event_id AND b.depth = p_depth / 2 AND w.is_user_tie = 0;

            INSERT INTO `bracket_entries` (bracket_id, participant_id, score, status, created_at)
            SELECT b.bracket_id, w.winner_id, 0, 0, NOW()
            FROM tmp_winner_list w
            INNER JOIN tmp_process_matches pm ON w.bracket_id = pm.bracket_id
            INNER JOIN `brackets` b ON b.event_id = p_event_id 
                                    AND b.depth = pm.depth / 2 
                                    AND b.order = IF(pm.depth = 4, 1, CEIL(pm.order / 2))
            WHERE w.winner_id > 0 AND w.is_both_lose = 0 AND w.is_user_tie = 0
            ON DUPLICATE KEY UPDATE participant_id = VALUES(participant_id);

            IF p_depth = 4 THEN
                INSERT INTO `bracket_entries` (bracket_id, participant_id, score, status, created_at)
                SELECT b.bracket_id, r.participant_id, 0, 0, NOW()
                FROM tmp_adj_results r
                INNER JOIN tmp_winner_list w ON r.bracket_id = w.bracket_id
                INNER JOIN `brackets` b ON b.event_id = p_event_id AND b.depth = 2 AND b.order = 2
                WHERE r.participant_id != w.winner_id 
                  AND w.is_both_lose = 0 AND w.is_user_tie = 0 
                  AND r.part_count > 1
                ON DUPLICATE KEY UPDATE participant_id = VALUES(participant_id);
            END IF;
        END IF;
        
        COMMIT  ;

        SELECT p_event_id, 'SUC' AS 'RETURN';
    ELSE
        SELECT p_event_id, p_depth, 'NO_READY_TARGET' AS 'RETURN';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_adj_targets;
    DROP TEMPORARY TABLE IF EXISTS tmp_process_matches;
    DROP TEMPORARY TABLE IF EXISTS tmp_adj_results;
    DROP TEMPORARY TABLE IF EXISTS tmp_winner_list;

END//
DELIMITER ;

-- 프로시저 triumph.sp_event_round_adjudicator_job 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_round_adjudicator_job`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_aj_id BIGINT;
    DECLARE v_event_id, v_round, v_order INT;
    DECLARE v_force TINYINT;

    BEGIN
        DECLARE cur_adj CURSOR FOR 
            SELECT auto_judge_id, event_id, `round`, match_order, force_judge
            FROM `event_auto_judge` 
            WHERE result_msg = 'PENDING'
            AND event_id NOT IN (376)
            ORDER BY RAND()
			LIMIT 1;
            
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

        OPEN cur_adj;
        read_loop: LOOP
            FETCH cur_adj INTO v_aj_id, v_event_id, v_round, v_order, v_force;
            IF done THEN LEAVE read_loop; END IF;
                            
		    IF NOT EXISTS (SELECT 1 FROM `brackets` WHERE event_id = v_event_id AND depth = v_round * 2 AND status NOT IN (4, 9)) THEN
		                            
		            CALL sp_event_round_adjudicator(v_event_id, v_round, v_force);
		
					UPDATE `event_auto_judge` aj
					INNER JOIN `brackets` b ON aj.event_id = b.event_id 
					                       AND aj.`round` = b.depth 
					                       AND aj.match_order = b.`order`
					SET aj.result_msg = CASE 
					                        WHEN b.status IN (4, 9) THEN 'SUCCESS' 
					                        ELSE 'PENDING' 
					                    END,
					    aj.processed_dt = NOW()
		            WHERE aj.event_id = v_event_id
		            AND aj.`round` = v_round
					;
 SELECT 'sp_event_round_adjudicator_job',  v_event_id, v_round, v_force, ROW_COUNT() AS affected_rows;
		      END IF;
      
		      UPDATE event_auto_judge aj
				INNER JOIN brackets b ON aj.event_id = b.event_id 
				                     AND aj.round = b.depth 
				                     AND aj.match_order = b.order
				SET aj.result_msg = NULL,
				    aj.processed_dt = NULL
				WHERE b.event_id = v_event_id
				AND b.depth = v_round
				AND b.status = 0;

        END LOOP;
        CLOSE cur_adj;
    END;
END//
DELIMITER ;

-- 프로시저 triumph.sp_event_round_score_generator 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_round_score_generator`(
	IN `p_event_id` INT,
	IN `p_depth` INT,
	IN `p_force_judge` TINYINT,
	IN `p_judge_mode` TINYINT,
	IN `p_wait_minutes` INT
)
BEGIN
    DECLARE v_start_depth INT;
    DECLARE v_prev_depth INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT p_event_id AS 'EVENT', 'EXCEPTION_ERROR' AS 'RETURN_RESULT';
    END;

    SET v_prev_depth = p_depth * 2;
    IF EXISTS (SELECT 1 FROM `brackets` WHERE event_id = p_event_id AND depth = v_prev_depth AND status NOT IN (4, 9)) THEN
        SELECT p_event_id AS 'EVENT', 'PREV_ROUND_PENDING' AS 'CHECK_POINT', p_depth AS '현재_라운드', v_prev_depth AS '미종료_라운드';
    ELSE
        DROP TEMPORARY TABLE IF EXISTS tmp_eligible_brackets;
        CREATE TEMPORARY TABLE tmp_eligible_brackets AS
        SELECT 
            b.bracket_id, b.depth, b.order, b.match_point,
            SUM(CASE WHEN p.dummy = 0 THEN 1 ELSE 0 END) AS real_user_count
        FROM `brackets` b
        INNER JOIN `bracket_groups` bg ON b.event_id = bg.event_id AND b.depth = bg.depth
        LEFT JOIN `bracket_entries` be ON b.bracket_id = be.bracket_id
        LEFT JOIN `participants` p ON be.participant_id = p.participant_id
        WHERE b.event_id = p_event_id AND b.depth = p_depth
          AND bg.auto_judge = 1 
          AND bg.start_dt <= DATE_SUB(NOW(), INTERVAL p_wait_minutes SECOND)
        GROUP BY b.bracket_id;
        
        DROP TEMPORARY TABLE IF EXISTS tmp_final_targets;
        CREATE TEMPORARY TABLE tmp_final_targets AS
        SELECT * FROM tmp_eligible_brackets
        WHERE (real_user_count < 2) OR (real_user_count = 2 AND p_force_judge = 1);
        
        IF NOT EXISTS (SELECT 1 FROM tmp_final_targets) THEN
            SELECT p_event_id AS 'EVENT', 'NO_TARGET_AVAILABLE' AS 'RETURN_RESULT', p_depth AS '라운드';
        ELSE
        
        START TRANSACTION;
        
            DROP TEMPORARY TABLE IF EXISTS tmp_dice_rolls;
            CREATE TEMPORARY TABLE tmp_dice_rolls AS
            SELECT 
                t.depth, t.order, be.bracket_id, be.participant_id, p.dummy, p.entrant_name,
                CASE WHEN p_force_judge = 1 AND p.dummy = 0 THEN 100 ELSE RAND() * 99 END AS dice_score,
                IF(p.dummy = 1 OR p_force_judge = 1, 1, 0) AS is_input_target
            FROM `bracket_entries` be
            INNER JOIN `participants` p ON be.participant_id = p.participant_id
            INNER JOIN tmp_final_targets t ON be.bracket_id = t.bracket_id;

            DROP TEMPORARY TABLE IF EXISTS tmp_match_results;
            CREATE TEMPORARY TABLE tmp_match_results AS
            SELECT 
                dr.bracket_id, dr.depth, dr.order, ft.match_point,
                SUBSTRING_INDEX(GROUP_CONCAT(dr.participant_id ORDER BY dr.dice_score DESC), ',', 1) AS winner_id,
                CASE 
                    WHEN p_judge_mode = 2 AND (RAND() < 0.15) THEN 7 
                    ELSE 1 
                END AS outcome_type,
                FLOOR(RAND() * ft.match_point) AS loser_score
            FROM tmp_dice_rolls dr
            INNER JOIN tmp_final_targets ft ON dr.bracket_id = ft.bracket_id
            GROUP BY dr.bracket_id;

            DROP TEMPORARY TABLE IF EXISTS tmp_set_blueprint;
            CREATE TEMPORARY TABLE tmp_set_blueprint AS
            SELECT 
                mr.bracket_id, mr.winner_id, mr.match_point, mr.loser_score,
                nums.seq AS set_order, RAND() AS shuffle_key
            FROM tmp_match_results mr
            CROSS JOIN (SELECT 1 AS seq UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) nums
            WHERE nums.seq <= (mr.match_point + mr.loser_score) AND mr.outcome_type <> 9;

            SET @brk := 0; SET @rnk := 0;
            DROP TEMPORARY TABLE IF EXISTS tmp_set_map;
            CREATE TEMPORARY TABLE tmp_set_map AS
            SELECT *, @rnk := IF(@brk = bracket_id, @rnk + 1, 1) AS set_rank, @brk := bracket_id AS d_val
            FROM tmp_set_blueprint WHERE set_order < (match_point + loser_score) ORDER BY bracket_id, shuffle_key;

            DELETE bs FROM `bracket_sets` bs
            INNER JOIN tmp_dice_rolls dr ON bs.bracket_id = dr.bracket_id AND bs.participant_id = dr.participant_id
            WHERE dr.is_input_target = 1;

            INSERT INTO `bracket_sets` (bracket_id, participant_id, set_order, winlose, create_dt)
            SELECT be.bracket_id, be.participant_id, sm.set_order,
                CASE WHEN be.participant_id = sm.winner_id THEN IF(sm.set_rank <= (sm.match_point - 1), 1, 0)
                     ELSE (1 - IF(sm.set_rank <= (sm.match_point - 1), 1, 0)) END, NOW()
            FROM `bracket_entries` be
            INNER JOIN tmp_dice_rolls dr ON be.bracket_id = dr.bracket_id AND be.participant_id = dr.participant_id
            INNER JOIN tmp_set_map sm ON be.bracket_id = sm.bracket_id
            WHERE dr.is_input_target = 1;

            INSERT INTO `bracket_sets` (bracket_id, participant_id, set_order, winlose, create_dt)
            SELECT be.bracket_id, be.participant_id, (mr.match_point + mr.loser_score),
                IF(be.participant_id = mr.winner_id, 1, 0), NOW()
            FROM `bracket_entries` be
            INNER JOIN tmp_dice_rolls dr ON be.bracket_id = dr.bracket_id AND be.participant_id = dr.participant_id
            INNER JOIN tmp_match_results mr ON be.bracket_id = mr.bracket_id
            WHERE dr.is_input_target = 1 AND mr.outcome_type <> 9;

            UPDATE `bracket_entries` be 
            INNER JOIN tmp_dice_rolls dr ON be.bracket_id = dr.bracket_id AND be.participant_id = dr.participant_id
            SET be.status = 2, be.updated_at = NOW()
            WHERE dr.is_input_target = 1;

            UPDATE `brackets` b 
            SET b.status = 2, b.updated_at = NOW()
            WHERE b.bracket_id IN (SELECT bracket_id FROM tmp_final_targets)
              AND NOT EXISTS (
                  SELECT 1 FROM `bracket_entries` be2 WHERE be2.bracket_id = b.bracket_id AND be2.status < 2
              );

            SELECT p_event_id, p_depth, 'SUC' AS 'RESULT';

            COMMIT;
        END IF;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_eligible_brackets;
    DROP TEMPORARY TABLE IF EXISTS tmp_final_targets;
    DROP TEMPORARY TABLE IF EXISTS tmp_dice_rolls;
    DROP TEMPORARY TABLE IF EXISTS tmp_match_results;
    DROP TEMPORARY TABLE IF EXISTS tmp_set_blueprint;
    DROP TEMPORARY TABLE IF EXISTS tmp_set_map;
END//
DELIMITER ;

-- 프로시저 triumph.sp_event_round_score_generator_job 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_round_score_generator_job`(
	IN `p_force_judge` TINYINT,
	IN `p_judge_mode` TINYINT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_aj_id BIGINT;
    DECLARE v_event_id, v_round, v_order INT;
    DECLARE v_prev_depth INT;

    INSERT IGNORE INTO `event_auto_judge` (event_id, `round`, match_order, force_judge, judge_mode, created_dt)
    SELECT b.event_id, b.depth, b.`order`, p_force_judge, p_judge_mode, NOW()
    FROM `events` e 
    INNER JOIN `brackets` b ON b.event_id = e.event_id
    LEFT OUTER JOIN `bracket_groups` bg ON b.event_id = bg.event_id AND b.depth = bg.depth
    WHERE e.`status` IN (1, 2) 
	 AND b.`status` NOT IN (4, 9) 
	 AND e.event_id > 400
	 AND bg.auto_judge = 1
    ;

    BEGIN
        DECLARE cur_gen CURSOR FOR
            SELECT event_id, `round`
            FROM `event_auto_judge` 
            WHERE result_msg IS NULL
            AND event_id > 500
            GROUP BY event_id, `round`
            ORDER BY `round` DESC, created_dt, event_id
            LIMIT 1;
            
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	        OPEN cur_gen;
	        read_loop: LOOP
	            FETCH cur_gen INTO v_event_id, v_round;
	            IF done THEN LEAVE read_loop; END IF;
	            
	            SELECT 'sp_event_round_score_generator_job', v_event_id, v_round;
	            
	        UPDATE `event_auto_judge` aj
	        INNER JOIN `brackets` b ON aj.event_id = b.event_id 
	                               AND aj.`round` = b.depth 
	                               AND aj.match_order = b.`order`
	        SET aj.result_msg = 'PROCESSING', 
	            aj.processed_dt = NOW()
	        WHERE aj.event_id = v_event_id 
	          AND aj.`round` = v_round 
	          AND aj.result_msg IS NULL
	          AND b.status IN (0);
	       
	           IF ROW_COUNT() > 0 THEN
	
	         CALL sp_event_round_score_generator(v_event_id, v_round, p_force_judge, p_judge_mode, 0);
	
	         UPDATE `event_auto_judge` aj 
	         INNER JOIN `brackets` b ON aj.event_id = b.event_id 
	                                AND aj.`round` = b.depth 
	                                AND aj.match_order = b.`order`
	         SET aj.result_msg = 'PENDING', 
	             aj.processed_dt = NOW()
	         WHERE aj.event_id = v_event_id 
	           AND aj.`round` = v_round
	           AND aj.result_msg = 'PROCESSING'
	           AND b.status = 2;
	           
	           END if;
	            
	        END LOOP;
	        CLOSE cur_gen;
        
    END;
END//
DELIMITER ;

-- 프로시저 triumph.sp_event_participants_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_participants_select`(
	IN `p_event_id` INT
)
BEGIN

    SET @rank = 0;

SELECT
t.participant_id,
t.entrant_id,
        t.entrant_name,
        t.entrant_image_url,
        t.dummy,
    @rank := @rank + 1 AS ranking,
    t.winCount,
    t.loseCount
    
FROM (
    SELECT 
    p.event_id,
        p.participant_id,
        p.entrant_id,
        p.entrant_name,
        p.entrant_image_url,
        p.dummy,
        SUM(CASE WHEN bs.winlose = 1 THEN 1 ELSE 0 END) AS winCount,
        SUM(CASE WHEN bs.winlose = 0 THEN 1 ELSE 0 END) AS loseCount
    FROM brackets b 
    INNER JOIN bracket_entries be ON b.bracket_id = be.bracket_id
    LEFT JOIN participants p ON p.participant_id = be.participant_id
    LEFT JOIN bracket_sets bs ON p.participant_id = bs.participant_id
    WHERE b.event_id = p_event_id
      AND b.depth = 2
      AND be.`status` IN (1,2,7)
    GROUP BY 
        p.participant_id,
        p.entrant_id,
        p.entrant_name,
        p.entrant_image_url,
        p.dummy
    ORDER BY 
        winCount DESC,
        loseCount ASC
) t;
END//
DELIMITER ;

-- 프로시저 triumph.sp_event_participant_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_participant_select`(
	IN `p_member_id` INT
)
BEGIN
    SELECT 
        e.event_id,
        e.title,
        e.event_start_dt,
        e.status,
        e.member_id,
        (
            SELECT COUNT(DISTINCT p1.participant_id)
            FROM participants p1
            WHERE p1.event_id = e.event_id AND p1.checkin_dt IS NOT NULL
        ) AS checked_in_count

    FROM events e
    LEFT JOIN participants p ON p.event_id = e.event_id
    LEFT JOIN participant_members pm ON p.participant_id = pm.participant_id
    INNER JOIN games g ON g.is_show = 1

    WHERE
        e.event_start_dt >= NOW()
        AND e.status < 3
        AND (
            e.member_id = p_member_id
            OR p.create_member_id = p_member_id
            OR pm.member_id = p_member_id
        )
    GROUP BY 
        e.event_id,
        e.title,
        e.event_start_dt,
        e.status,
        e.member_id
    ORDER BY e.event_start_dt ASC;
END//
DELIMITER ;

-- 프로시저 triumph.sp_event_participants_member_game_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_event_participants_member_game_select`(
	IN `p_member_id` INT
)
BEGIN
    SELECT 
        ev.*,
        ga.game_id AS game_game_id,
        ga.name AS game_name,
        ga.logo_image_url AS game_logo_image_url,
        ga.profile_image_url AS game_image_url,
        ga.box_art_image_url AS game_box_image,
        ga.main_banner_bg_image_url AS game_bg_image,
        me.member_id AS member_member_id,
        me.name AS member_name,
        me.image_url AS member_image_url,
        (
            SELECT COUNT(*)
            FROM participants p
            WHERE p.event_id = ev.event_id
              AND p.checkin_dt IS NOT NULL
        ) AS participants_count

    FROM events ev
    INNER JOIN games ga 
        ON ev.game_id = ga.game_id 
        AND ga.is_show = 1
    LEFT JOIN members me 
        ON ev.member_id = me.member_id
    WHERE 
        ev.event_start_dt >= NOW()
        AND ev.status < 3
        AND (
            ev.member_id = p_member_id
            OR EXISTS (
                SELECT 1
                FROM participants pa
                WHERE pa.event_id = ev.event_id
                  AND pa.create_member_id = p_member_id
            )
            OR EXISTS (
                SELECT 1
                FROM participants p
                INNER JOIN participant_members pm 
                    ON p.participant_id = pm.participant_id
                WHERE p.event_id = ev.event_id
                  AND pm.member_id = p_member_id
            )
        )
    ORDER BY ev.event_start_dt ASC;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_bracket_sets_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_bracket_sets_select`(IN p_participant_id INT)
BEGIN
    SELECT 
        p.participant_id,
        p.entrant_id,
        p.entrant_name,
        p.entrant_image_url,
        p.dummy,
        SUM(CASE WHEN bs.winlose = 1 THEN 1 ELSE 0 END) AS winCount,
        SUM(CASE WHEN bs.winlose = 0 THEN 1 ELSE 0 END) AS loseCount
    FROM participants p
    JOIN bracket_sets bs 
        ON p.participant_id = bs.participant_id
    WHERE FIND_IN_SET(p.participant_id, p_participant_id) > 0
    GROUP BY 
        p.participant_id, 
        p.entrant_id, 
        p.entrant_name, 
        p.entrant_image_url, 
        p.dummy;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_checkin_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_checkin_update`(
	IN `p_event_id` INT,
	IN `p_participant_id` INT
)
    COMMENT '참가자 체크인'
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
        
    END;

    START TRANSACTION;

    SELECT IFNULL(p.create_member_id, pm.member_id) INTO v_member_id FROM  `participants` p
	 LEFT OUTER JOIN participant_members pm ON p.participant_id = pm.participant_id
	 WHERE `event_id` = p_event_id AND p.`participant_id` = p_participant_id LIMIT 1;

    UPDATE `participants` SET `checkin_dt` = NOW(), `update_dt` = NOW()
    WHERE `event_id` = p_event_id AND `participant_id` = p_participant_id;
    SELECT ROW_COUNT() INTO ret;

    CALL sp_log_user_insert(4111, p_event_id, v_member_id, 'sp_participants_checkin_update');

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_checkout_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_checkout_update`(
	IN `p_event_id` INT,
	IN `p_participant_id` INT
)
    COMMENT '참가자 체크아웃'
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
        
    END;

    START TRANSACTION;

    SELECT IFNULL(p.create_member_id, pm.member_id) INTO v_member_id FROM  `participants` p
	 LEFT OUTER JOIN participant_members pm ON p.participant_id = pm.participant_id
	 WHERE `event_id` = p_event_id AND p.`participant_id` = p_participant_id LIMIT 1;

    UPDATE `participants` SET `checkin_dt` = NULL, `update_dt` = NOW()
    WHERE `event_id` = p_event_id AND `participant_id` = p_participant_id;
    SELECT ROW_COUNT() INTO ret;

    CALL sp_log_user_insert(4110, p_event_id, v_member_id, 'sp_participants_checkout_update');

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_delete`(
	IN `p_event_id` INT,
	IN `p_participant_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
    	  ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;
    
    START TRANSACTION;
    DELETE FROM `participants` WHERE `event_id` = p_event_id AND `participant_id` = p_participant_id;
    SELECT ROW_COUNT() INTO ret;

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_dummy_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_dummy_delete`(
	IN `p_event_id` INT,
	IN `p_participant_id` INT
)
    COMMENT '참가자 더미 데이터 삭제'
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;

    START TRANSACTION;
    
    DELETE FROM `participants` WHERE `event_id` = p_event_id AND `participant_id` = p_participant_id AND `dummy` = 1;
    SELECT ROW_COUNT() INTO ret;

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_insert`(
	IN `p_event_id` INT,
	IN `p_participant_type` TINYINT,
	IN `p_entrant_id` INT,
	IN `p_entrant_name` VARCHAR(255),
	IN `p_checkin_dt` DATETIME,
	IN `p_dummy` TINYINT,
	IN `p_create_member_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    INSERT INTO participants (event_id, participant_type, entrant_id, entrant_name, checkin_dt, dummy, create_member_id, create_dt, update_dt)
    VALUES (p_event_id, p_participant_type, p_entrant_id, p_entrant_name, p_checkin_dt, p_dummy, p_create_member_id, NOW(), NULL);
    
    SELECT LAST_INSERT_ID() INTO ret;
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_profile_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_profile_update`(
	IN `p_event_id` INT,
	IN `p_participant_id` INT,
	IN `p_entrant_name` VARCHAR(255),
	IN `p_entrant_image_url` VARCHAR(512)
)
    COMMENT '참가자 프로필 업데이트'
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;

    START TRANSACTION;
    
    UPDATE `participants` SET `entrant_name` = p_entrant_name, `entrant_image_url` = p_entrant_image_url
    WHERE `event_id` = p_event_id AND `participant_id` = p_participant_id;
    SELECT ROW_COUNT() INTO ret;

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_select`(
	IN `p_participant_id` INT
)
BEGIN
    SELECT participant_id, event_id, participant_type, entrant_id, entrant_name, checkin_dt, dummy, create_member_id, create_dt, update_dt
    FROM participants
    WHERE participant_id = p_participant_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participants_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participants_update`(
	IN `p_participant_id` INT,
	IN `p_event_id` INT,
	IN `p_participant_type` TINYINT,
	IN `p_entrant_id` INT,
	IN `p_entrant_name` VARCHAR(255),
	IN `p_checkin_dt` DATETIME,
	IN `p_dummy` TINYINT,
	IN `p_create_member_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    UPDATE participants
    SET event_id = p_event_id, participant_type = p_participant_type, entrant_id = p_entrant_id,
        entrant_name = p_entrant_name, checkin_dt = p_checkin_dt, dummy = p_dummy, create_member_id = p_create_member_id,
        update_dt = NOW()
    WHERE participant_id = p_participant_id;
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_bracket_set_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_bracket_set_select`(
    IN p_member_id INT
)
BEGIN
    SELECT
            p.participant_id,
            p.entrant_id,
            p.entrant_name,
            p.entrant_image_url,
            p.dummy,
            SUM(CASE WHEN bs.winlose = 1 THEN 1 ELSE 0 END) AS winCount,
            SUM(CASE WHEN bs.winlose = 0 THEN 1 ELSE 0 END) AS loseCount
        FROM participants p
        INNER JOIN bracket_sets bs 
            ON p.participant_id = bs.participant_id
        WHERE p.participant_id = p_member_id
        GROUP BY 
            p.participant_id, 
            p.entrant_id, 
            p.entrant_name, 
            p.entrant_image_url, 
            p.dummy;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_members_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_members_delete`(
	IN `p_participant_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    START TRANSACTION;
    
    DELETE FROM `participant_members` WHERE `participant_id` = p_participant_id;
    SELECT ROW_COUNT() INTO ret;

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_members_dummy_delete 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_members_dummy_delete`(
	IN `p_participant_id` INT
)
    COMMENT '참가자 멤버 더미 데이터 삭제'
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE v_member_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'EXP' AS 'RETURN';
    END;

    START TRANSACTION;
    
    DELETE FROM `participant_members` WHERE `participant_id` = p_participant_id AND `dummy` = 1;
    SELECT ROW_COUNT() INTO ret;

    IF ret > 0 THEN COMMIT; SELECT 'SUC' AS 'RETURN';
    ELSE ROLLBACK; SELECT 'ERR' AS 'RETURN'; END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_members_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_members_insert`(
	IN `p_participant_member_id` INT,
	IN `p_member_id` INT,
	IN `p_member_name` VARCHAR(255),
	IN `p_checkin_dt` DATETIME,
	IN `p_dummy` TINYINT,
	IN `p_create_member_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;
	 DECLARE v_member_id INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    INSERT INTO participant_members (participant_member_id, member_id, member_name, checkin_dt, dummy, create_member_id, create_dt, update_dt)
    VALUES (p_participant_member_id, p_member_id, p_member_name, p_checkin_dt, p_dummy, p_create_member_id, NOW(), NULL);
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_members_select 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_members_select`(
	IN `p_participant_member_id` INT
)
BEGIN
    SELECT participant_member_id, member_id, member_name, checkin_dt, dummy, create_member_id, create_dt, update_dt
    FROM participant_members
    WHERE participant_member_id = p_participant_member_id;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_members_select_all 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_members_select_all`(
    IN `p_page` INT,
    IN `p_rows` INT,
    IN `p_event_id` INT
)
BEGIN
    SELECT p.`participant_id`, p.`event_id`, p.`participant_type`, p.`entrant_id`, p.`entrant_name`, p.`checkin_dt`, p.`dummy`, p.`create_member_id`, p.`create_dt`, p.`update_dt`
    , pm.`member_id`, pm.`member_name`, pm.`checkin_dt`, pm.`dummy`, pm.`create_member_id`, pm.`create_dt`, pm.`update_dt`
    FROM `participants` p LEFT JOIN `participant_members` pm
    ON p.`participant_id` = pm.`member_id`
    WHERE event_id = p_event_id
    ORDER BY p.`create_dt`, pm.`create_dt` ASC
    LIMIT p_page, p_rows;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_members_update 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_members_update`(
	IN `p_participant_member_id` INT,
	IN `p_member_id` INT,
	IN `p_member_name` VARCHAR(255),
	IN `p_checkin_dt` DATETIME,
	IN `p_dummy` TINYINT,
	IN `p_create_member_id` INT
)
BEGIN
    DECLARE ret INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXP' AS 'RETURN';
    END;
    
    UPDATE participant_members
    SET member_id = p_member_id, member_name = p_member_name, checkin_dt = p_checkin_dt,
        dummy = p_dummy, create_member_id = p_create_member_id, update_dt = NOW()
    WHERE participant_member_id = p_participant_member_id;
    
    SELECT ROW_COUNT() INTO ret; 
	
    IF ret > 0 THEN
        SELECT 'SUC' AS 'RETURN';
    ELSE
        SELECT 'ERR' AS 'RETURN';
    END IF;
END//
DELIMITER ;

-- 프로시저 triumph.sp_participant_team_members_insert 구조 내보내기
DELIMITER //
CREATE PROCEDURE `sp_participant_team_members_insert`(
	IN `p_event_id` INT,
	IN `p_entrant_id` INT,
	IN `p_entrant_name` VARCHAR(255),
	IN `p_participant_member_ids` VARCHAR(128),
	IN `p_participant_member_names` VARCHAR(1024),
	IN `p_create_member_id` INT
)
BEGIN
    DECLARE _ret INT DEFAULT 0;
    DECLARE _team_size INT DEFAULT 0;

    DECLARE _start_position_id INT DEFAULT 1;
    DECLARE _end_position_id INT;
    DECLARE _start_position_name INT DEFAULT 1;
    DECLARE _end_position_name INT;

    DECLARE _member_id INT;
    DECLARE _member_name VARCHAR(64);
    DECLARE _dummy INT;
    
    DECLARE _participant_id INT DEFAULT 0;

    DECLARE _i INT DEFAULT 0;

    DECLARE _member_profile_name VARCHAR(255) DEFAULT NULL;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'EXC' AS 'RETURN';
        
        ROLLBACK;
    END;

    SELECT team_size INTO _team_size FROM `events` WHERE event_id = p_event_id;

    IF p_create_member_id IS NOT NULL THEN
        CREATE TEMPORARY TABLE IF NOT EXISTS tmp_participant (
        `event_id` INT(11),
        `participant_type` TINYINT(4),
        `entrant_id` INT(11),
        `entrant_name` VARCHAR(255),
        `entrant_image_url` VARCHAR(512),
        `dummy` TINYINT(1),
        `create_member_id` INT(11),
	    `checkin_dt` DATETIME);
        
        TRUNCATE tmp_participant;
        
        IF _team_size = 1 THEN
            IF p_entrant_id IS NULL THEN

                INSERT INTO tmp_participant (`event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`, `checkin_dt`)
                SELECT p_event_id, 0, NULL, p_entrant_name, NULL, 1, p_create_member_id, NOW();

            ELSEIF p_entrant_id IS NOT NULL AND p_entrant_id > 0 THEN
                SELECT `p_g_m_i`.`val0` INTO _member_profile_name
                FROM `platform_game_members` `p_g_m`
                    LEFT JOIN `platform_game_member_info` `p_g_m_i` ON `p_g_m`.`platform_game_member_id` = `p_g_m_i`.`platform_game_member_id`
                    LEFT JOIN `platform_games` `p_g` ON `p_g_m`.`platform_game_id` = `p_g`.`platform_game_id`
                    LEFT JOIN `games` `g` ON `p_g`.`game_id` = `g`.`game_id`
                    LEFT JOIN `events` `e` ON `g`.`game_id` = `e`.`game_id`
                WHERE `p_g_m`.`member_id` = p_entrant_id AND `e`.`event_id` = p_event_id
                ORDER BY `p_g_m`.`created_dt` DESC
                LIMIT 1;

                IF _member_profile_name IS NOT NULL THEN
                    INSERT INTO tmp_participant (`event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`)
                    SELECT p_event_id, 0, member_id, _member_profile_name, image_url, 0, p_create_member_id FROM members WHERE member_id = p_entrant_id;
                ELSE
                    INSERT INTO tmp_participant (`event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`)
                    SELECT p_event_id, 0, member_id, NAME, image_url, 0, p_create_member_id FROM members WHERE member_id = p_entrant_id;
                END IF;
                
                SELECT ROW_COUNT() INTO _ret;

                IF _ret = 0 THEN
                    SELECT 'ERR' AS 'RETURN';
                END IF;
            END IF;
            
            INSERT INTO	participants (`event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`, `checkin_dt`) 
            SELECT `event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`, `checkin_dt`
            FROM tmp_participant;
            
            SELECT ROW_COUNT() INTO _ret;
            
            IF _ret = 1 THEN
                SELECT 'SUC' AS 'RETURN';
            ELSE
                SELECT 'ERR' AS 'RETURN';
            END IF;

        ELSEIF _team_size > 1 THEN
            IF p_entrant_id IS NULL THEN
                INSERT INTO tmp_participant (`event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`, `checkin_dt`)
                SELECT p_event_id, 1, NULL, p_entrant_name, NULL, 1, p_create_member_id, NOW();
            ELSEIF p_entrant_id IS NOT NULL AND p_entrant_id > 0 THEN
                INSERT INTO tmp_participant (`event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`)
                SELECT p_event_id, 1, team_id, NAME, image_url, 0, p_create_member_id FROM teams WHERE team_id = p_entrant_id;
                SELECT ROW_COUNT() INTO _ret;
                IF _ret = 0 THEN
                    SELECT 'ERR' AS 'RETURN';
                END IF;
            END IF;
        
            CREATE TEMPORARY TABLE IF NOT EXISTS tmp_participant_members (
            `member_id` INT(11),
            `member_name` VARCHAR(255) COLLATE 'utf8mb4_unicode_ci',
            `member_image_url` VARCHAR(512) COLLATE 'utf8mb4_unicode_ci',
            `dummy` TINYINT(1),
            `create_member_id` INT(11),
			`checkin_dt` DATETIME);
            
            TRUNCATE tmp_participant_members;

            IF p_participant_member_ids IS NOT NULL AND p_participant_member_names IS NOT NULL
            THEN
                WHILE _start_position_id > 0 AND _start_position_name > 0 DO
                    SET _member_profile_name = NULL;
                    SET _end_position_id = LOCATE(',', p_participant_member_ids, _start_position_id);
                    SET _end_position_name = LOCATE(',', p_participant_member_names, _start_position_name);

                    IF _end_position_id > 0 AND _end_position_name > 0 THEN
                        SET _member_id = SUBSTRING(p_participant_member_ids, _start_position_id, _end_position_id - _start_position_id);
                        SET _member_name = SUBSTRING(p_participant_member_names, _start_position_name, _end_position_name - _start_position_name);
                    ELSE
                        SET _member_id = SUBSTRING(p_participant_member_ids, _start_position_id);
                        SET _member_name = SUBSTRING(p_participant_member_names, _start_position_name);
                    END IF;
                    
                    IF _member_id = '' THEN SET _dummy = 1; ELSE SET _dummy = 0; END IF;

                    IF _dummy = 1 THEN
						INSERT INTO tmp_participant_members (member_id, member_name, member_image_url, dummy, create_member_id, checkin_dt)
                        VALUES (TRIM(_member_id), TRIM(_member_name), NULL, TRIM(_dummy), p_create_member_id, NOW());
                    ELSE
                        SELECT `p_g_m_i`.`val0` INTO _member_profile_name
                        FROM `platform_game_members` `p_g_m`
                            LEFT JOIN `platform_game_member_info` `p_g_m_i` ON `p_g_m`.`platform_game_member_id` = `p_g_m_i`.`platform_game_member_id`
                            LEFT JOIN `platform_games` `p_g` ON `p_g_m`.`platform_game_id` = `p_g`.`platform_game_id`
                            LEFT JOIN `games` `g` ON `p_g`.`game_id` = `g`.`game_id`
                            LEFT JOIN `events` `e` ON `g`.`game_id` = `e`.`game_id`
                        WHERE `p_g_m`.`member_id` = TRIM(_member_id) AND `e`.`event_id` = p_event_id
                        ORDER BY `p_g_m`.`created_dt` DESC
                        LIMIT 1;

                        IF _member_profile_name IS NOT NULL THEN
					        INSERT INTO tmp_participant_members (member_id, member_name, member_image_url, dummy, create_member_id)
                            SELECT TRIM(_member_id), _member_profile_name, image_url, TRIM(_dummy), p_create_member_id FROM members WHERE member_id = TRIM(_member_id);
                        ELSE
					        INSERT INTO tmp_participant_members (member_id, member_name, member_image_url, dummy, create_member_id)
                            SELECT TRIM(_member_id), NAME, image_url, TRIM(_dummy), p_create_member_id FROM members WHERE member_id = TRIM(_member_id);
                        END IF;
                    END IF;

                    SET _start_position_id = IF(_end_position_id > 0, _end_position_id + 1, 0);
                    SET _start_position_name = IF(_end_position_name > 0, _end_position_name + 1, 0);

                    SET _i = _i + 1;

                END WHILE;
                
                START TRANSACTION;
                INSERT INTO	participants (event_id, participant_type, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`, `checkin_dt`) 
                SELECT `event_id`, `participant_type`, `entrant_id`, `entrant_name`, `entrant_image_url`, `dummy`, `create_member_id`, `checkin_dt`
                FROM tmp_participant;

                SELECT LAST_INSERT_ID() INTO _participant_id;

                INSERT INTO participant_members(participant_id, member_id, member_name, member_image_url, dummy, `create_member_id`, `checkin_dt`)
                SELECT _participant_id, member_id, member_name, member_image_url, dummy, `create_member_id`, `checkin_dt`
                FROM tmp_participant_members;
                
                SELECT ROW_COUNT() INTO _ret; 
                
                DROP TEMPORARY TABLE IF EXISTS tmp_participant_members;

                IF _ret = _i THEN
                    SELECT 'SUC' AS 'RETURN';
                    COMMIT;
                ELSE
                    SELECT 'ERR' AS 'RETURN';
                    ROLLBACK;
                END IF;
            END IF;
        END IF;

        DROP TEMPORARY TABLE IF EXISTS tmp_participant;

    END IF;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
