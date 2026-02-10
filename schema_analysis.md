# 스키마 분석 요약 (MariaDB 5.5)

## 1) 전체 구조 요약
- **대회 운영**: `events`, `participants`, `participant_members`
- **토너먼트**: `brackets`, `bracket_entries`, `bracket_groups`, `bracket_sets`
- **FFA 포인트전**: `ffa_*` 테이블
- **채팅**: `chat_rooms`, `chat_members`, `chat_messages`, `chat_message_attaches`, `chats`
- **게임/플랫폼**: `games`, `platforms`, `platform_games`, `platform_game_members`, `platform_game_member_info`
- **팀**: `teams`, `team_members`
- **운영로그/유틸**: `log_*`, `urls`, `feedbacks`, `announces`

## 2) 핵심 문제점 (데이터 무결성/성능/운영 리스크)
### A. 무결성(FK) 부재
- 대부분의 관계에 **FOREIGN KEY가 없음**  
  예) `participants.event_id`, `brackets.event_id`, `bracket_entries.participant_id` 등  
  → **고아 데이터 발생** 및 유지보수 비용 증가

### B. 컬럼/테이블 불일치 (프로시저 오류 가능성 높음)
1) `bracket_sets`에 **`bracket_set_id` 없음**  
   - 그런데 `sp_bracket_sets_delete/select/update`는 `bracket_set_id`를 사용  
   - **실행 시 오류 발생 가능**
2) `sp_brackets_update_auto_judge`, `sp_brackets_update_group`  
   - `brackets`에 `auto_judge` 컬럼이 없음  
   - 실제 컬럼은 `bracket_groups.auto_judge`  
   - **업데이트 대상 테이블 오류**
3) `sp_events_select`는 `platform_game_id` 컬럼을 조회  
   - `events` 테이블에는 `game_id`만 존재  
4) `sp_platforms_select`에서 `game_id`를 조회  
   - `platforms` 테이블에는 `game_id` 컬럼 없음
5) `sp_participant_members_select_all`  
   - JOIN 조건이 `p.participant_id = pm.member_id`  
   - 의도상 `pm.participant_id`가 맞음

### C. 예약어 사용
- `brackets.order`는 **예약어** → 쿼리마다 백틱 필요  
  → 유지보수/리팩터링 시 실수 위험 증가

### D. 타입/콜레이션 불일치
- `utf8mb4_unicode_ci`, `utf8mb4` 혼용  
- `utf8`과 `utf8mb4` 혼재  
  → **조인/정렬 시 Collation 오류 가능**

### E. 인덱스 부족
자주 쓰는 조건에 맞는 인덱스가 부족합니다.
예)
- `participants (event_id, create_member_id)`
- `participant_members (participant_id, member_id)`
- `bracket_entries (bracket_id)` (조인 성능 핵심)
- `chat_messages (room_id, created_dt)`

### F. 트랜잭션/에러 핸들러 혼선
- `START TRANSACTION` 없이 `ROLLBACK` 호출
- 에러 핸들러에 `SELECT 'EXP'`만 있고, **실제 오류 원인 로깅 없음**

### G. 로직 중복 및 불명확한 상태값
- `status` 값 정의가 코드/DB에 분산  
  → 상태값 테이블 또는 ENUM 정의 필요

## 3) DBA 관점 개선 방향 (DB 중심 로직 강화)
### 1) FK 및 규칙 테이블 추가
- **기본 FK 적용**으로 무결성 강화  
  (MariaDB 5.5 지원)
- 상태값은 **참조 테이블**로 관리

### 2) 프로시저 정합성 점검
- 현재 프로시저 중 **실행 자체가 실패 가능**한 것 존재  
  → 1차로 “실행 불가 프로시저”부터 정리 필요

### 3) 토너먼트/FFA 구조 통합 방향
- **싱글/더블/FFA 공용 구조** 가능성 있음  
  다만 토너먼트는 승자 이동 경로 컬럼이 필요

### 4) 성능 최적화 기본 규칙
- **조인 기준 컬럼 선두 인덱스**
- 서브쿼리 반복 제거
- 정렬 컬럼 인덱스 적용

## 4) 바로 점검해야 할 “치명 이슈” 목록
1) `sp_bracket_sets_delete/select/update` → `bracket_set_id` 없음  
2) `sp_brackets_update_auto_judge`, `sp_brackets_update_group` → 컬럼 없음  
3) `sp_events_select` → `platform_game_id` 없음  
4) `sp_platforms_select` → `game_id` 없음  
5) `sp_participant_members_select_all` → JOIN 컬럼 오류

## 5) 다음 단계 제안
1) **프로시저 정합성 수정** (실행 불가 오류 제거)  
2) **FK 및 인덱스 설계**  
3) **토너먼트/FFA 구조 통합 설계안 제시**

---
필요하시면 다음 단계로:
- “실행 불가 프로시저 수정안”
- “FK/인덱스 DDL 일괄 스크립트”
- “토너먼트/FFA 통합 스키마 설계”
까지 바로 진행 가능합니다.
