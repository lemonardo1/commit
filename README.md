# commit

AI가 `git diff`를 분석해서 커밋 메시지를 자동으로 생성해주는 CLI 도구.

```
$ commit

commit v1.0.0
──────────────────────────────────────────

ℹ  변경 파일 스테이징 중... (git add .)

스테이징된 파일:
  + src/auth.ts
  ~ src/user.ts
  - src/legacy.ts

ℹ  AI가 커밋 메시지를 생성 중...

생성된 커밋 메시지:
──────────────────────────────────────────
feat(auth): add JWT token validation and remove legacy auth module

- Replace session-based auth with JWT
- Remove deprecated legacy.ts
──────────────────────────────────────────

?  이 메시지로 커밋할까요? [Y/n/e(편집)]
```

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/lemonardo1/commit/main/dist/install.sh | bash
```

설치 후 최초 1회 API 키 설정:

```bash
commit setup
```

> `/usr/local/bin` 권한이 없으면 `~/.local/bin`에 자동으로 설치됩니다.

## 사용법

```bash
commit          # AI 커밋 메시지 생성 → 확인 → push
commit setup    # API 키 재설정
commit --help
commit --version
```

### 실행 순서

1. `git add .` — 모든 변경 파일 스테이징
2. `git diff --cached` — AI에 전달
3. 생성된 메시지 확인 → **Y** 승인 / **n** 직접 입력 / **e** 에디터 편집
4. `git commit -m "..."`
5. `git push` — 원격 저장소가 없으면 URL 입력 후 자동 추가

git 저장소가 없는 디렉토리에서 실행하면 `git init` 여부를 묻습니다.

## 지원 AI

| 제공자 | 모델 | API 키 형식 |
|--------|------|------------|
| OpenAI | GPT-4o | `sk-...` |
| Anthropic | Claude Opus 4.6 | `sk-ant-...` |

## 설정 파일

API 키는 `~/.commit/config`에 저장됩니다 (권한 `600`).

```bash
# ~/.commit/config
AI_PROVIDER="openai"
AI_API_KEY="sk-..."
AI_MODEL="gpt-4o"
```

설정을 변경하려면 `commit setup`을 다시 실행하거나 파일을 직접 수정하세요.

## 요구사항

- bash 4.0+
- git
- curl
- `jq` 또는 `python3` (JSON 파싱)

macOS에서 jq 설치:

```bash
brew install jq
```

## 배포 (자체 서버)

스크립트를 install.sh에 내장한 self-contained 인스톨러를 빌드합니다:

```bash
bash build.sh
# → dist/install.sh 생성
```

`dist/install.sh`를 웹서버에 올린 뒤 배포 URL을 공유하세요.

## 라이선스

MIT
