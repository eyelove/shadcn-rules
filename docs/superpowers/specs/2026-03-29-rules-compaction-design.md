# Rules Compaction Design

## 문제

현재 `.claude/rules/` 파일 9개(2,601줄, ~94KB)가 CLAUDE.md의 `@` 참조로 매 세션 전체 인라인 로딩된다. 규칙은 잘 동작하지만, 컨텍스트 부담이 크다.

## 목표

동작하는 규칙을 유지하면서 **컨텍스트 사용량만 줄인다.** 2,601줄 → ~720줄 (72% 감소).

## 접근법

**CORRECT/FORBIDDEN 한 쌍만 남기기.**

각 규칙 항목을 이 형태로 압축한다:

```
규칙 문장 (1~2줄)
// WHY: 이유 (1줄)

FORBIDDEN: 잘못된 코드 (1~3줄)
CORRECT: 올바른 코드 (1~3줄)
```

## 왜 이 접근법인가

검토한 대안과 기각 이유:

| 대안 | 기각 이유 |
|------|----------|
| gold/ 참조 파일 | Claude가 파일을 읽을지 보장 안됨 |
| skill로 on-demand 로딩 | 여러 skill이 있으면 트리거 정확도 보장 안됨 |
| hook으로 시점별 주입 | additionalContext 우선순위가 rule과 동일한지 미검증 |
| 예제 전체 삭제 | 프로젝트 고유 패턴(chartConfig, Field 계층)은 예제 없이 틀릴 위험 |

**한 쌍 예제**는 Claude가 "올바른 것"과 "금지된 것"의 경계를 잡기에 충분하면서, 컨텍스트를 최소화한다.

## 유지하는 것 (삭제 불가)

AI가 추론할 수 없는 프로젝트 고유 정보:

- Props Interface: DataTable, SearchBar의 타입 정의
- 함수 시그니처: formatCurrency, formatCompact 등 `@/lib/format` API
- ko-KR 만/억 스케일 규칙과 "원" 접미사 처리
- shadcn import path 전체 목록
- 의사결정 트리: Select vs Combobox, RadioGroup vs Choice Card
- spacing 역할별 고정값 테이블
- chartConfig 정의 방법과 var(--color-KEY) 참조 패턴
- react-hook-form Controller + data-invalid + aria-invalid 연결 패턴

## 삭제하는 것

- 동일 규칙의 2번째~5번째 코드 예제 (한 쌍이면 충분)
- AI가 이미 아는 React/Tailwind 기본 패턴
- 다른 rule 파일과 중복되는 내용 (한 곳에만 유지)
- 장문 설명, Escape Hatch, Cross-References (2줄로 압축)

## CLAUDE.md 변경

`@` 참조 9개를 유지하되, CLAUDE.md 자체의 설명 텍스트를 ~50줄로 압축한다. `@` 참조를 제거하지 않는 이유: `paths:` 조건부 로딩은 Claude가 해당 파일을 읽을 때만 규칙이 로딩되므로, 규칙을 모르는 상태에서 코드를 생성할 위험이 있다. 현재 동작이 확인된 방식을 유지한다.

## 파일별 목표

| 파일 | Before | After | 감소율 |
|------|--------|-------|--------|
| CLAUDE.md | 107줄 | ~50줄 | 53% |
| cards.md | 441줄 | ~100줄 | 77% |
| fields.md | 488줄 | ~90줄 | 82% |
| data-table.md | 356줄 | ~80줄 | 78% |
| components.md | 266줄 | ~80줄 | 70% |
| page-templates.md | 259줄 | ~60줄 | 77% |
| formatting.md | 210줄 | ~70줄 | 67% |
| forbidden.md | 216줄 | ~70줄 | 68% |
| tokens.md | 166줄 | ~70줄 | 58% |
| naming.md | 92줄 | ~50줄 | 46% |
| **합계** | **2,601줄** | **~720줄** | **72%** |

## 롤백 전략

1. 작업 전 `git tag rules-v1-before-compaction`으로 현재 상태 마킹
2. 간결화 작업 수행
3. `/eval` 실행하여 arm_a 점수 확인
4. 이전 run(run9)과 동등하거나 개선 → 성공
5. 점수 하락 → `git checkout rules-v1-before-compaction -- .claude/ CLAUDE.md`로 즉시 롤백

## 검증 기준

- check-rules.sh arm_a 점수가 이전 run9 대비 동등 이상
- tsc 빌드 통과
- 4개 페이지(campaign-list, campaign-detail, campaign-form, campaign-dashboard) 모두 생성 성공

## 단계적 확장 (향후)

이번 작업으로 충분하지 않으면:
- **경로 B**: hook으로 특정 시점에만 규칙 주입 (additionalContext)
- 이 경우 별도 설계 + eval 검증 필요
