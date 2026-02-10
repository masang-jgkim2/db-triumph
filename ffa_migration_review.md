# FFA 포인트제 구조 전환 검토

## 결론
**조건부 가능**입니다.  
기존 `brackets` 계열은 **1:1 토너먼트(승패 중심)** 구조이고, 신규 FFA 구조는 **조별 누적 포인트(다자 참여 가능)** 구조라서 **의미가 완전히 동일하지 않습니다**.  
다만, 아래 가정을 둔다면 **기술적 마이그레이션은 가능**합니다.

### 주요 가정
1. **각 `bracket`을 FFA의 `group`(2인 조)으로 취급**한다.  
2. `participant_id`가 **동일하게 유지**되거나 **명확한 매핑**이 존재한다.  
3. `bracket_sets.winlose`는 `ffa_match_scores.score`로 **1/0 변환**한다.  
4. `winner_entrant_id`가 **실제 `participant_id`와 동일**하다고 가정한다.  
   - 동일하지 않다면 `participants`를 통해 별도 매핑 필요  
5. FFA에 **일부 컬럼이 누락**되어 정보 손실을 감수하거나 스키마를 보강한다.

---

## 매핑 가능성 요약

| 기존 테이블 | 신규 테이블 | 매핑 가능성 | 비고 |
|---|---|---|---|
| `bracket_groups` | `ffa_stages` | 부분 가능 | `auto_judge`, `start_dt` 저장 불가 |
| `brackets` | `ffa_groups` | 부분 가능 | `match_point`, 시작/종료 시각 누락 |
| `bracket_entries` | `ffa_group_results` | 가능 | `score` → `total_score`, 승자 기준으로 `rank_in_group`/`is_advanced` 생성 |
| `bracket_sets` | `ffa_match_scores` | 부분 가능 | `winlose` → `score`(1/0), `judge_image_url` 손실 |

---

## 정보 손실/불일치 포인트
1. **`brackets.match_point`**  
   - FFA 구조에는 매칭되는 컬럼 없음  
2. **경기 시각(`start_dt`, `match_start_dt`, `match_end_dt`)**  
   - FFA 그룹/스테이지에는 저장처 없음  
3. **`bracket_sets.judge_image_url`**  
   - FFA 구조에 저장처 없음  
4. **`brackets.status`와 `ffa_groups.status` 의미 불일치**  
   - 브라켓 상태(판정중 등)가 FFA 상태로 완전 매핑 불가

---

## 스키마 보강 추천 (필요시)
- `ffa_groups`
  - `start_dt`, `match_start_dt`, `match_end_dt`
  - `match_point` (또는 `point_rule_id`)
  - `legacy_bracket_id` (마이그레이션용)
- `ffa_match_scores`
  - `judge_image_url` (승패 판정 근거 보관)
- `ffa_stage_rules` (선택)
  - `auto_judge` 저장용 별도 테이블

---

## 마이그레이션 절차 (요약)
1. `bracket_groups` → `ffa_stages` 생성  
2. `brackets` → `ffa_groups` 생성  
   - `depth` → `round_depth`
   - `order` → `group_order`
   - `max_capacity = 2`, `winners_per_group = 1` 가정  
3. `bracket_entries` → `ffa_group_results`  
   - `score` → `total_score`
   - `winner_entrant_id` 기준 `rank_in_group`/`is_advanced` 계산  
4. `bracket_sets` → `ffa_match_scores`  
   - `winlose` → `score`(1/0)  
5. 디버깅/검증 쿼리로 건수 및 FK 정합성 확인

---

## 검토 결과 요약
- **기술적으로는 마이그레이션 가능**하지만,  
  **대회 방식(토너먼트 vs FFA 포인트)** 차이로 인해 의미가 100% 동일하지 않음.
- 운영에서 **판정 이미지/경기 시간/포인트 규칙**이 중요하다면  
  **스키마 보강 후 마이그레이션**을 권장.

자세한 예시 SQL은 `ffa_migration.sql` 참고.
