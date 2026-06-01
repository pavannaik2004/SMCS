# SCMS Project — Context & Progress Log
## Single Source of Truth for All AI Agents & Team Members

> **⚠️ EVERY AI AGENT SESSION MUST READ THIS FILE FIRST before writing any code.**
> After completing work, UPDATE this file with what was done.

---

## 📋 Project Summary

**Project:** Smart Complaint Management System (SCMS)
**Type:** Cross-platform mobile app (Flutter) + Node.js backend + Python AI microservice
**Team:** 4 members — Pavan, Prabhava, Prem, Pramath
**Academic:** MCA II Semester project at RVCE

**Key Documents:**
- `SCMS_PRD.md` — Full product requirements (3378 lines, the single source of truth)
- `TEAM_WORKDIVISION.md` — Who owns what files, build order, dependencies
- `PROMPT_PAVAN.md` — AI agent prompt for Pavan's scope
- `PROMPT_PRABHAVA.md` — AI agent prompt for Prabhava's scope

---

## 🏗️ Architecture at a Glance

```
Flutter App (scms_flutter/)    →  Node.js API (scms_backend/:3000)  →  Python AI (scms_ai_service/:8000)
                                         ↓                                    ↓
                                   PostgreSQL + pgvector              Google AI Studio (Gemini)
```

- **Auth:** Google OAuth 2.0 only — `hostedDomain: "rvce.edu.in"` in GoogleSignIn. NO email/password.
- **State:** flutter_bloc (BLoC + Cubit pattern)
- **Routing:** go_router with role-based redirects in `app.dart`
- **Storage:** FlutterSecureStorage (JWT tokens), Hive (offline drafts — manual TypeAdapters, NO code-gen)
- **AI flow:** Flutter → Node.js → Python AI service (Flutter NEVER calls Python directly)

---

## 👥 Team Ownership & Start Status

| Member | Scope | Branch | Status |
|---|---|---|---|
| **Pavan** | Flutter: Foundation + Core + Data + Widgets + Student Screens | `pavan/core-and-student-flow` | ✅ Phases 1-6 DONE |
| **Prabhava** | Flutter: Staff + SR + Admin + Settings + Notifications | `prabhava/staff-sr-admin` | 🟢 **CAN START NOW** |
| **Prem** | Node.js backend: All routes, auth, SLA, FCM | `prem/nodejs-backend` | 🟢 **CAN START NOW** |
| **Pramath** | Python AI: FastAPI, Gemini, embeddings, duplicate detection | `pramath/ai-service` | ✅ All 4 endpoints DONE |

---

## 📊 Progress Tracker

### Day 0 — Monorepo Scaffold
**Status: ✅ COMPLETE** | Date: 2026-05-19

| Task | Status |
|---|---|
| `flutter create scms_flutter` | ✅ |
| Full dir structure (98 placeholder .dart files) | ✅ |
| `scms_backend/` scaffold (26 placeholder files) | ✅ |
| `scms_ai_service/` scaffold (9 placeholder files) | ✅ |
| `pubspec.yaml` (all PRD §21.4 deps) | ✅ |
| `scms_backend/package.json` | ✅ |
| `scms_backend/prisma/schema.prisma` (full schema) | ✅ |
| All `.env.example` files (Flutter, Node, Python) | ✅ |
| `docker-compose.yml` | ✅ |
| Root `.gitignore` | ✅ |

### Phase 1 — Foundation (Pavan)
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/main.dart` | ✅ |
| `lib/app.dart` | ✅ GoRouter + role-based redirect |
| `lib/core/constants/api_constants.dart` | ✅ All PRD §12 endpoints |
| `lib/core/constants/app_constants.dart` | ✅ SLA, form limits, timeouts |
| `lib/core/constants/route_constants.dart` | ✅ All named routes |
| `lib/core/constants/tag_constants.dart` | ✅ 14 predefined tags |
| `lib/core/theme/app_colors.dart` | ✅ Full palette + helpers |
| `lib/core/theme/app_text_styles.dart` | ✅ Typography + AppSpacing |
| `lib/core/theme/app_theme.dart` | ✅ Light + Dark ThemeData |
| `lib/core/utils/date_formatter.dart` | ✅ |
| `lib/core/utils/validators.dart` | ✅ |
| `lib/core/utils/extensions.dart` | ✅ |
| `lib/core/utils/logger.dart` | ✅ |
| `lib/core/utils/watermark_painter.dart` | ✅ |
| `lib/core/errors/exceptions.dart` | ✅ |
| `lib/core/errors/failures.dart` | ✅ |
| `lib/core/network/dio_client.dart` | ✅ Auth interceptor + 401 refresh |
| `lib/core/network/network_info.dart` | ✅ |
| `analysis_options.yaml` | ✅ |

### Phase 2 — Data Layer (Pavan)
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/data/models/user_model.dart` | ✅ fromJson/toJson/copyWith/role helpers |
| `lib/data/models/complaint_model.dart` | ✅ Full model with canRate/isSlaActive |
| `lib/data/models/complaint_update_model.dart` | ✅ |
| `lib/data/models/department_model.dart` | ✅ |
| `lib/data/models/category_model.dart` | ✅ |
| `lib/data/models/rating_model.dart` | ✅ |
| `lib/data/models/analytics_model.dart` | ✅ With DepartmentStat + CategoryStat |
| `lib/data/models/grammar_correction_model.dart` | ✅ With diff types |
| `lib/data/models/duplicate_check_model.dart` | ✅ With DuplicateMatch |
| `lib/data/models/sr_review_model.dart` | ✅ |
| `lib/data/datasources/remote/auth_remote_datasource.dart` | ✅ Full Google OAuth flow |
| `lib/data/datasources/remote/complaint_remote_datasource.dart` | ✅ CRUD + AI + Analytics |
| `lib/data/datasources/local/auth_local_datasource.dart` | ✅ FlutterSecureStorage |
| `lib/data/datasources/local/complaint_local_datasource.dart` | ✅ Hive + manual TypeAdapter |
| `lib/data/repositories/auth_repository.dart` | ✅ |
| `lib/data/repositories/complaint_repository.dart` | ✅ With offline draft fallback |
| `lib/domain/entities/user_entity.dart` | ✅ |
| `lib/domain/entities/complaint_entity.dart` | ✅ |
| `lib/domain/usecases/login_usecase.dart` | ✅ |
| `lib/domain/usecases/submit_complaint_usecase.dart` | ✅ |
| `lib/domain/usecases/get_my_complaints_usecase.dart` | ✅ |
| `lib/domain/usecases/get_analytics_usecase.dart` | ✅ |

### Phase 3 — State Management (Pavan)
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/presentation/bloc/auth/auth_bloc.dart` | ✅ GoogleSignIn + AppStarted + Logout |
| `lib/presentation/bloc/auth/auth_event.dart` | ✅ |
| `lib/presentation/bloc/auth/auth_state.dart` | ✅ |
| `lib/presentation/bloc/complaint/complaint_bloc.dart` | ✅ |
| `lib/presentation/bloc/complaint/complaint_event.dart` | ✅ |
| `lib/presentation/bloc/complaint/complaint_state.dart` | ✅ |
| `lib/presentation/bloc/submit_complaint/submit_complaint_cubit.dart` | ✅ 800ms debounce grammar + AI |
| `lib/presentation/bloc/submit_complaint/submit_complaint_state.dart` | ✅ |

### Phase 4 — Common Widgets (Pavan) — 🔴 PRABHAVA DEPENDENCY
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/presentation/widgets/common/scms_button.dart` | ✅ 4 variants + loading |
| `lib/presentation/widgets/common/scms_text_field.dart` | ✅ |
| `lib/presentation/widgets/common/scms_chip.dart` | ✅ Animated selected state |
| `lib/presentation/widgets/common/loading_overlay.dart` | ✅ |
| `lib/presentation/widgets/common/error_widget.dart` | ✅ With retry |
| `lib/presentation/widgets/common/empty_state_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/complaint_card.dart` | ✅ Full card with SLA |
| `lib/presentation/widgets/complaint/status_badge.dart` | ✅ |
| `lib/presentation/widgets/complaint/sla_timer_widget.dart` | ✅ Real-time ticker |
| `lib/presentation/widgets/complaint/media_capture_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/category_selector_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/tag_selector_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/grammar_correction_banner.dart` | ✅ Diff view |
| `lib/presentation/widgets/complaint/duplicate_warning_banner.dart` | ✅ |
| `lib/presentation/widgets/complaint/grouped_complaint_card.dart` | ✅ |
| `lib/presentation/widgets/notification/notification_badge.dart` | ✅ |

### Phase 5 — Services (Pavan)
**Status: ⬜ NOT STARTED** — Prabhava is now unblocked; Pavan can do this next

### Phase 6 — Student Screens (Pavan)
**Status: ✅ FUNCTIONALLY COMPLETE** | Date: 2026-05-19

| File | Status | Notes |
|---|---|---|
| `splash_page.dart` | ✅ | Fade-in + auto-navigate |
| `onboarding_page.dart` | ✅ | 3-slide PageView + dots |
| `login_page.dart` | ✅ | Google Sign-In only |
| `home_page.dart` | ✅ | 3-tab + FAB + stats |
| `my_complaints_page.dart` | ✅ | Filter chips + pull-to-refresh |
| `submit_complaint_page.dart` | ✅ | Form + AI + severity + photos |
| `complaint_detail_page.dart` | ✅ | Full detail + timeline |
| `duplicate_complaints_page.dart` | 🔄 Stub | Router entry exists, logic TODO |
| `rating_page.dart` | ✅ | Star rating + comment |

**`flutter analyze` result: ✅ No issues found**

---

### Prabhava — Staff/SR/Admin/Settings/Notifications
**Status: 🟡 IN PROGRESS**

Completed (2026-06-01):
- `lib/data/datasources/remote/sr_review_remote_datasource.dart`
- `lib/data/repositories/sr_review_repository.dart`
- `lib/domain/usecases/sr_approve_complaint_usecase.dart`
- `lib/domain/usecases/sr_reject_complaint_usecase.dart`
- `lib/domain/usecases/update_complaint_status_usecase.dart`
- `lib/presentation/bloc/sr_review/sr_review_bloc.dart`
- `lib/presentation/bloc/sr_review/sr_review_event.dart`
- `lib/presentation/bloc/sr_review/sr_review_state.dart`
- `lib/presentation/bloc/analytics/analytics_cubit.dart`
- `lib/presentation/bloc/analytics/analytics_state.dart`
- `lib/presentation/widgets/analytics/stats_card.dart`
- `lib/presentation/widgets/analytics/complaints_chart.dart`
- `lib/services/notification_service.dart`
- `lib/services/analytics_service.dart`
- `lib/presentation/pages/sr/sr_dashboard_page.dart`
- `lib/presentation/pages/sr/sr_review_detail_page.dart`
- `lib/presentation/pages/staff/staff_dashboard_page.dart`
- `lib/presentation/pages/staff/staff_complaint_detail_page.dart`
- `lib/presentation/pages/admin/admin_dashboard_page.dart`
- `lib/presentation/pages/admin/admin_complaints_list_page.dart`
- `lib/presentation/pages/settings/settings_page.dart`
- `lib/presentation/pages/route_helpers.dart`

Next:
1. Add PR request to Pavan to register `SrReviewBloc` + `AnalyticsCubit` in `main.dart`
2. Add PR request to Pavan to wire `prabhavaRoutes` into `app.dart`
3. Add PR request to Pavan to initialize Firebase + NotificationService in `main.dart`
4. Add widget tests: `test/widget/sr_dashboard_test.dart`, `test/widget/staff_dashboard_test.dart`

**Key pages to implement:**
- `lib/presentation/pages/sr/sr_dashboard_page.dart`
- `lib/presentation/pages/sr/sr_review_detail_page.dart`
- `lib/presentation/pages/staff/staff_dashboard_page.dart`
- `lib/presentation/pages/staff/staff_complaint_detail_page.dart`
- `lib/presentation/pages/admin/admin_dashboard_page.dart`
- `lib/presentation/pages/admin/admin_complaints_list_page.dart`
- `lib/presentation/pages/settings/settings_page.dart`
- `lib/services/notification_service.dart`

### Prem — Node.js Backend
**Status: 🟢 READY TO START**

All placeholder files exist in `scms_backend/`. `package.json` and `prisma/schema.prisma` are fully populated.

**Start immediately with:**
1. `cd scms_backend && npm install`
2. Copy `.env.example` → `.env`, fill real values
3. `npx prisma migrate dev` (needs PostgreSQL running via `docker-compose up postgres -d`)
4. Implement `POST /api/auth/google` FIRST — this unblocks Flutter auth testing

**Priority build order:**
```
server.js → src/app.js → src/middleware/authenticate.js
→ src/routes/auth.js (POST /api/auth/google) ← DO FIRST
→ src/routes/complaints.js → src/routes/ai.js
→ src/services/aiProxy.js → src/jobs/slaScheduler.js
```

### Pramath — Python AI Service
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status | Notes |
|---|---|---|
| `requirements.txt` | ✅ | google-genai, fastapi, uvicorn, psycopg2-binary, pgvector, pydantic, numpy, httpx |
| `.env` | ✅ | Copy `.env.example`, set real `GEMINI_API_KEY` from AI Studio |
| `models/schemas.py` | ✅ | All Pydantic schemas: Grammar, Categorize, Embed, Duplicate |
| `services/gemini_client.py` | ✅ | New `google-genai` SDK; grammar + categorize + embed, all with try/except fallbacks |
| `services/db_client.py` | ✅ | psycopg2 pool + pgvector; store_embedding + find_similar_complaints |
| `routers/grammar.py` | ✅ | POST /grammar-check with word-level EQUAL/DELETE/INSERT diffs |
| `routers/categorize.py` | ✅ | POST /categorize; maps AI output to category/dept IDs |
| `routers/embed.py` | ✅ | POST /embed; generates + stores 768-d vector in complaints.embedding |
| `routers/duplicate.py` | ✅ | POST /check-duplicate; cosine similarity >= SIMILARITY_THRESHOLD |
| `main.py` | ✅ | CORS, all routers, /health probe, startup pgvector migration |

**Notes for Prem (Node.js):**
- Service runs on port 8000 (configurable via PORT env var)
- All endpoints return safe defaults on failure — never crash with 500
- `/embed` must be called by Node.js AFTER saving complaint to DB (`complaintId` required)
- Category/dept IDs in `/categorize` are placeholder slugs — update once Prem seeds DB UUIDs
- Gemini: `gemini-2.0-flash` (text), `models/gemini-embedding-004` (768-d)

**To start:**
```bash
cd scms_ai_service && venv\Scripts\activate
# Set real GEMINI_API_KEY in .env
uvicorn main:app --reload --port 8000
```

---


## ⚠️ Known Issues & Decisions

| Date | Issue | Resolution |
|---|---|---|
| 2026-05-19 | `hive_generator ^2.0.1` conflicts with `bloc_test ^9.1.7` | Removed `hive_generator` + `build_runner`. Hive TypeAdapters written **manually** in `complaint_local_datasource.dart`. |
| 2026-05-19 | `AuthFailure` name collision (failures.dart vs auth_state.dart) | `auth_bloc.dart` uses `import ... as failures` to disambiguate. |
| 2026-05-19 | `withOpacity` deprecated in Flutter | Added `deprecated_member_use: ignore` in `analysis_options.yaml`. Replace with `.withValues(alpha: x)` when upgrading Flutter. |

---

## 📁 Project Structure (Current State)

```
d:\projects\SCMS\
├── SCMS_PRD.md                         ← Source of truth for all specs
├── TEAM_WORKDIVISION.md                ← Ownership rules
├── CONTEXT.md                          ← THIS FILE
├── PROMPT_PAVAN.md                     ← Pavan's AI agent prompt
├── PROMPT_PRABHAVA.md                  ← Prabhava's AI agent prompt
├── docker-compose.yml                  ← Postgres + Backend + AI
├── .gitignore
│
├── scms_flutter/                       ← Flutter app ✅ Phases 1-6 complete
│   ├── analysis_options.yaml
│   ├── pubspec.yaml                    ← All deps installed
│   ├── .env                            ← Placeholder values (update before running)
│   ├── .env.example
│   └── lib/
│       ├── main.dart                   ✅ Entry point + DI
│       ├── app.dart                    ✅ GoRouter + role redirect
│       ├── core/                       ✅ All foundation files
│       ├── data/models/                ✅ 10 models with fromJson/toJson
│       ├── data/datasources/           ✅ Remote + local
│       ├── data/repositories/          ✅ Auth + Complaint
│       ├── domain/                     ✅ Entities + usecases
│       ├── presentation/bloc/          ✅ Auth + Complaint + SubmitComplaint BLoCs
│       ├── presentation/widgets/       ✅ All common + complaint + notification widgets
│       ├── presentation/pages/
│       │   ├── splash/                 ✅
│       │   ├── onboarding/             ✅
│       │   ├── auth/                   ✅ Google Sign-In only
│       │   ├── home/                   ✅ 3-tab
│       │   ├── complaint/              ✅ my list + submit + detail + rating
│       │   ├── staff/                  ⬜ PRABHAVA
│       │   ├── admin/                  ⬜ PRABHAVA
│       │   ├── sr/                     ⬜ PRABHAVA
│       │   └── settings/               ⬜ PRABHAVA
│       └── services/                   ⬜ PAVAN next (camera, location, grammar)
│
├── scms_backend/                       ← Node.js API ⬜ PREM
│   ├── package.json                    ✅ All deps listed
│   ├── prisma/schema.prisma            ✅ Full schema
│   ├── .env.example                    ✅
│   └── src/                            ⬜ All placeholders — Prem to implement
│
└── scms_ai_service/                    ← Python FastAPI ⬜ PRAMATH
    ├── .env.example                    ✅
    └── routers/ services/ models/      ⬜ All placeholders — Pramath to implement
```

---

## 🔄 How to Resume as AI Agent

1. **Read this file first** — understand current state
2. **Read `SCMS_PRD.md` §§ relevant to your work** (don't read all 3378 lines)
3. **Read `TEAM_WORKDIVISION.md`** — never touch other members' files
4. **Check the progress tracker above** — find your first ⬜ item
5. **Update this file** after completing work
6. **Run `flutter analyze`** — must show "No issues found"

### Quick Start Commands
```bash
# Flutter
cd d:\projects\SCMS\scms_flutter
flutter pub get
flutter run

# Node.js backend (Prem)
cd d:\projects\SCMS\scms_backend
cp .env.example .env          # fill real values
npm install
docker-compose up postgres -d  # from root
npx prisma migrate dev
npm run dev

# Python AI service (Pramath)
cd d:\projects\SCMS\scms_ai_service
python -m venv venv
venv\Scripts\activate          # Windows
cp .env.example .env           # fill GEMINI_API_KEY
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

---

*Last updated: 2026-06-01T12:05:00+05:30 by Prabhava (AI agent) — staff/SR/admin/settings screens, analytics widgets, notification + analytics services, route helpers implemented*
