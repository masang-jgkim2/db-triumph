# DB 구조 개선 제안

## 1) 기존 구조 분석 요약
- **참가자/팀/멤버 정보 중복**: `participants.entrant_name`/`entrant_image_url`와 `participant_members`에 동일 정보가 중복될 가능성이 큼.
- **개인/팀 구분 로직이 분산**: `participant_type`, `entrant_id`, `participant_members` 조합으로 개인/팀 판별이 필요해 조회·검증이 복잡.
- **PK/UK/FGK 부재**: `participant_members`에 PK가 없고, 대진표 관련 테이블에 FK가 없어 데이터 무결성 유지가 어렵다.
- **컬럼 네이밍·의미 불명확**: `order`(예약어), `winner_entrant_id`(실제론 참가 엔트리인지 모호), `dummy`(의미가 불명확).
- **시간 컬럼 타입 혼합**: `TIMESTAMP`/`DATETIME` 혼재로 일관성이 떨어짐.

## 2) 개선 설계 방향
1. **엔트리 분리**:  
   - `entrants`(개인/팀 단위의 참가 주체)  
   - `event_entries`(대회별 참가 엔트리)  
2. **대회별 멤버 정보 분리**:  
   - `entry_members`로 대회별 멤버 구성/체크인 기록 유지  
3. **대진표 구조 정비**:  
   - `order` → `match_order`로 변경  
   - `winner_entrant_id` → `winner_entry_id`로 명확화  
4. **무결성 강화**: FK, UK, 인덱스 추가  

> **참고**: 기존 스키마가 snake_case이므로 DB 네이밍은 호환성을 우선하고, 코드 레벨에서 헝가리안 표기를 적용하는 방향을 권장한다.

## 3) 추천 테이블 구조(핵심)
- `entrants`
  - 참가 주체(개인/팀) 마스터
- `event_entries`
  - 대회별 참가 엔트리
- `entry_members`
  - 대회별 참가 멤버(팀 구성, 체크인 기록 포함)
- `brackets`, `bracket_entries`, `bracket_sets`, `bracket_groups`
  - 대진표 관련 컬럼 명 정비 및 FK 연결

## 4) 마이그레이션 개요
1. 신규 테이블 생성
2. `entrants`에 개인/팀 마스터 데이터 적재
3. `event_entries`에 기존 참가 데이터 적재
4. `entry_members`에 기존 참가 멤버 데이터 적재
5. 대진표 테이블 v2로 이관
6. 검증 쿼리로 건수·정합성 확인
7. 기존 테이블을 `_legacy`로 보관 후 신규 테이블로 교체

## 5) 가정/주의사항
- `participant_type` 값은 **0(개인)**, **1(팀)** 기준으로 설계.
- 개인전의 `member_id`가 없는 케이스는 `legacy_participant_id`로 임시 매핑.
- `winner_entrant_id`는 실제로 **참가 엔트리 ID**로 간주하고 `winner_entry_id`로 변경.

자세한 SQL은 `db_migration.sql` 파일 참고.
