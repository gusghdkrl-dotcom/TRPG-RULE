# 조사자 수첩 개발 참고

개발용 문서이며 프로젝트 게임 소스에 넣지 않는다. 게임 실행 계약은 rules/09-notebook.md에만 둔다.

기존 문서에 기록된 구현 위치는 `gusghdkrl-dotcom/trpg-engine`, `experiments/investigator-notebook/`이다. 이전 작업 브랜치는 `feat/lightweight-investigator-notebook-mvp-20261021`, 서비스명은 `investigator-notebook-lite`였다. 이 기록은 현재 브랜치·배포 상태의 증거가 아니므로 작업 시 다시 확인한다.

주요 파일: notebook.html(UI), model.mjs(공개 허용목록), server.mjs(도구/이미지/API), resume-guard.mjs(검증 저장보다 앞선 공개 기록 차단), KEEPER_LIVE_SYNC_A27.md(운영 계약), test/notebook.test.mjs와 test/mcp-flow.test.mjs. 해당 저장소의 실제 package.json과 CI를 따른다.

수첩 기능 유지 기준:
- 사건 연표/목표/약속/챕터와 인물/NPC/인물 사건의 탭·ID·이력을 구분한다.
- 공개 지도·이미지 원본과 갤러리, 복구 키·revision·이전 UI Resource alias를 보존한다.
- inactive 탭의 hidden이 CSS display!important로 무효화되지 않게 검사한다. 작은 화면·빈 기록·다수 기록·이미지 확대·오류/복구 대기를 실제 UI에서 확인한다.
- 공개 allowlist·소유권·Resume 가드를 약화하지 않는다. 비공개 게임 DB를 수첩의 저장 대체물로 쓰지 않는다.
- 실제 이미지 바이트 접근 가능성과 도구 계약을 먼저 확인한다. 채팅 이미지·게임 사건의 자동 수집이 구현됐다고 추정하지 않는다.
- MP 삭제 등 새 규칙판의 시트 변경은 model/server/UI/관련 테스트의 실제 계약을 함께 확인해야 한다. 이 문서 개편에서 수첩 앱을 수정·배포하지 않았다.

앱 수정 시 현재 소스·배포 SHA를 읽고 승인 범위 안에서 수정한다. synthetic 자료로 모델/API·권한·탭·이미지 회귀를 검사하고, 배포가 승인된 경우에만 정확한 서비스의 live 상태를 확인한다. 과거 v32 배포 기록을 현재 운영 사실로 단정하지 않는다. 실제 저장 기록 초기화는 UI 문제 해결 수단이 아니다.
