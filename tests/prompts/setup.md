---
type: setup
---

# Preview 환경 셋업

preview/ 디렉토리에 shadcn/ui 프로젝트의 기본 CSS/테마를 설정하세요.
**컴포넌트는 설치하지 마세요.** 컴포넌트는 페이지 생성 시 필요에 따라 설치합니다.

## 작업 항목

### 1. index.css에 Tailwind + 토큰 설정
- `@import "tailwindcss";` 유지
- `tokens/globals.css`의 CSS 커스텀 프로퍼티를 `preview/src/index.css`에 추가
- `:root`와 `.dark` 모두 포함

### 2. shadcn 초기 구성 확인
- `preview/components.json` 이 존재하고 올바른 설정인지 확인
- aliases가 `@/components`, `@/lib` 등으로 설정되어 있는지 확인

### 3. 변경하지 말 것
- `package.json` — 기본 의존성 외 추가 설치 금지
- `vite.config.ts` — 수정 금지
- `tsconfig.app.json` — 수정 금지
- 어떤 shadcn 컴포넌트도 설치 금지 (`npx shadcn add` 실행 금지)
