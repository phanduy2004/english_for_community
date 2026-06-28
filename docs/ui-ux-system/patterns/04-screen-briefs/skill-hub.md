# Screen Brief — Skill Hub (student)

> Áp blueprint **A2 · Hub / Browse list** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào màn thật.
> **Màn:** Skill Hub — ví dụ **Reading** (luyện đọc theo chủ đề) · **File:** `lib/feature/reading/reading_list_page.dart` (card nội tuyến `_ReadingCard` cùng file).
> **Trạng thái:** dùng `SkillType.reading` (orange) — skill color HỢP LỆ ở màn kỹ năng học (banner/filter/icon/accent). Brief lo phần **bố cục & nhịp dọc** + thứ tự search/filter; text vẫn `textPrimary`, amber chỉ celebrate.
> **Khái quát hoá:** cùng khuôn cho các hub `listening`, `listening-comp`, `speaking`, `writing`, `vocabulary` — chỉ đổi `SkillType` + l10n + entity; widget shared giữ nguyên.

---

## 1. Hiện trạng (đo theo token)

```
┌──────────────────────────────────────────┐  pagePadding = LTRB(12,10,12,20)  (pageHPadding/Top/Bottom)
│ ‹  Đọc hiểu                                │  skillAppBar (appBar 46 + accent line 2dp @reading 55%)
│ ════════════════════════════════════════  │  ← accent line orange
│ ┌────────────────────────────────────────┐│
│ │ Bài đọc mỗi ngày             📖(box 44) ││  skillHubBanner(skill:reading) — tint orange
│ │ Luyện đọc theo trình độ của bạn.        ││   padding s4: title(h2)+s1+subtitle(body)
│ │ ( Bài mới mỗi ngày )                    ││   +s2+badge → cao ~3 dòng + icon 44
│ └────────────────────────────────────────┘│
│   ↕ sectionGap(14)                          │
│ (Cơ bản)(Trung cấp)(Nâng cao)              │  filterRow(skill:reading) — chip selected = orange
│   ↕ cardGap(8)                              │
│ [🔍 Tìm chủ đề…                          ] │  searchField (surfaceSubtle + outline)
│   ↕ sectionGap(14)                          │
│ ┌────────────────────────────────────────┐│
│ │▌(Cơ bản)(Đã xong)              📖(box)  ││  _ReadingCard = skillAccentCard(left border orange s2)
│ │▌Tiêu đề bài (h3, 2 dòng)                ││   padding s4
│ │▌Tóm tắt (body, 2 dòng)                  ││
│ │▌─────────────────────────── (divider)   ││   s5 → Divider(outlineMuted) → s4
│ │▌⏱ 5 phút  ❓ 8 câu  ✓ 90%   [Xem][Lại] ││  metaWrap + trailing review/retake (hoặc [Bắt đầu])
│ └────────────────────────────────────────┘│
│   ↕ cardGap(8)  (separatorBuilder)          │
│ ┌────────────────────────────────────────┐│  bài kế…
└──────────────────────────────────────────┘
```

**Đo:** từ accent line tới card đầu = **banner ~3 dòng (≥104dp)** + `sectionGap` + filter + `cardGap` + search + `sectionGap`. → **4 khối chrome** trước item đầu, và **search nằm DƯỚI filter** (ngược thói quen "tìm trước, lọc sau"). File: `reading_list_page.dart:83-117`.

### Đánh giá
| ✅ Giữ | ⚠️ Sửa |
|--------|--------|
| `skillAppBar` accent orange 2dp — nhận diện skill ngay (`reading_list_page.dart:74-78`) | **Thứ tự lạ:** filter ĐỨNG TRƯỚC search (`:92-116`). A2/A7 mong **search → filter** |
| Banner skill tint + icon box 44 + badge (đúng A2, `:83-90`) | **Banner 3 dòng** chiếm ~104dp cho thông tin tĩnh; lặp ý subtitle ↔ title |
| `_ReadingCard` = `skillAccentCard` (left border orange) + icon box + progress meta (`:261-311`) | **Nhịp dọc to:** `sectionGap(14)` ×2 quanh search → chrome dày trước item đầu (`:91,117`) |
| 3 state đủ: `listLoading` / `errorBanner` / `emptyState(skill)` (`:120-148`) | **`_ReadingCard` re-define nút "Bắt đầu" thủ công** (`:371-382`) thay vì dùng widget shared |
| Filter chip selected = orange, badge level dùng `difficultyColor` semantic (`:259,388-409`) | **Empty do search = empty do 0-data** (cùng `noReadingArticlesFound` + icon, `:140-147`) — không phân biệt 2 ca |
| `_matchesPrefix` lọc client-side ổn định (`:208-212`) | Toàn bộ trong `ListView` + `ListView.separated(shrinkWrap, NeverScrollable)` lồng nhau (`:80,150-152`) — không lazy/phân trang dù BLoC có `page/limit` |

---

## 2. Target layout (refined) — search lên trước, item lên sớm

Theo A2 (search → filter → list) + A7. **Giữ banner skill** (đúng vibe hub học), nhưng **đảo search↔filter** và **siết nhịp dọc** để card đầu lên cao hơn. Phân biệt empty-search vs empty-data.

```
TRƯỚC (filter trên search, chrome dày)     SAU (search-first, gọn)
┌───────────────────────────┐             ┌───────────────────────────┐
│ ‹ Đọc hiểu  ══════════════ │             │ ‹ Đọc hiểu  ══════════════ │  accent orange 2dp
│ ┌───────────────────────┐ │             │ ┌───────────────────────┐ │
│ │ Bài đọc mỗi ngày  📖   │ │             │ │ Bài đọc mỗi ngày  📖   │ │  banner (giữ)
│ │ Luyện đọc…  (badge)    │ │             │ │ Luyện đọc…  (badge)    │ │
│ └───────────────────────┘ │             │ └───────────────────────┘ │
│  ↕ sectionGap(14)         │             │  ↕ cardGap(8)             │
│ (Cơ bản)(Trung)(Nâng)     │  filter     │ [🔍 Tìm chủ đề…         ] │  search NGAY dưới banner
│  ↕ cardGap(8)             │             │  ↕ cardGap(8)             │
│ [🔍 Tìm chủ đề…         ] │  search     │ (Cơ bản)(Trung)(Nâng)     │  filter sát list
│  ↕ sectionGap(14)         │             │  ↕ cardGap(8)             │
│ ┌───────────────────────┐ │             │ ┌───────────────────────┐ │
│ │▌Tiêu đề… ⏱5 ❓8 [Bắt đầu]│            │ │▌Tiêu đề… ⏱5 ❓8 [Bắt đầu]│  card đầu cao hơn ~22dp
│ └───────────────────────┘ │             │ └───────────────────────┘ │
└───────────────────────────┘             └───────────────────────────┘
                                          ↳ tiết kiệm ~18–22dp chrome; thao tác đúng "tìm → lọc"
```

### Zones (target)
| Zone | Nội dung | Token / widget | Ghi chú |
|------|----------|----------------|---------|
| App bar | `Đọc hiểu` + accent line | `skillAppBar(skill: reading)` | accent orange `@0.55` 2dp — giữ |
| Banner | tip/overview + badge + icon box | `skillHubBanner(skill: reading)` tint orange | giữ; title `sectionTitle`/h2, subtitle `body`, text vẫn textPrimary |
| Search | `searchField` | surfaceSubtle + `outline` | **lên ngay dưới banner**, ↕ `cardGap` |
| Filter | `filterRow(skill: reading)` | chip selected = orange | **xuống sát list**, ↕ `cardGap` |
| List | `_ReadingCard` (skillAccentCard) + meta + progress | surfaceCard, left border orange `s2` | separator `cardGap`; trailing review/retake hoặc start |

> **Không trộn 2 skill color** trong 1 card (đúng `AppSkillColors` rule). Badge **level** dùng `difficultyColor` (success/warning/danger semantic) — KHÔNG phải skill color; đó là phân loại độ khó, không phải accent skill.

---

## 3. Build diff (đường dẫn cụ thể cho Cursor)

File: `lib/feature/reading/reading_list_page.dart`, trong `build()` (children của `ListView`, `:80-169`):

1. **Đảo search ↔ filter.** Di chuyển block `StudentMobileUi.searchField(...)` (`:108-116`) lên **trước** `StudentMobileUi.filterRow(...)` (`:92-106`). Thứ tự mới: `skillHubBanner` → search → filter → list.
2. **Siết spacing.** Đổi 2 `SizedBox(height: sectionGap)` (`:91` sau banner, `:117` sau search) thành `cardGap`. Spacing mới: banner → `cardGap` → search → `cardGap` → filter → `cardGap` → list.
   ```dart
   StudentMobileUi.skillHubBanner( /* …giữ nguyên… */ ),
   const SizedBox(height: StudentMobileUi.cardGap),
   StudentMobileUi.searchField( /* …moved up… */ ),
   const SizedBox(height: StudentMobileUi.cardGap),
   StudentMobileUi.filterRow( /* …moved down… */ ),
   const SizedBox(height: StudentMobileUi.cardGap),
   BlocBuilder<ReadingBloc, ReadingState>( /* list */ ),
   ```
3. **Dùng widget shared cho nút "Bắt đầu".** Thay `FilledButton` thủ công trong `_ReadingCard` (`:371-382`) bằng nút start-pattern nhất quán (vd `skillCardRetakeButton`-style/`FilledButton` primary với `AppTypography.label(color: onPrimary)`) — giữ height 32 đồng bộ với review/retake. (Không phát minh widget mới; nếu thêm helper thì đặt trong `StudentMobileUi`, không inline.)
4. **Phân biệt empty-search vs empty-data** ở nhánh `readings.isEmpty` (`:140-147`):
   ```dart
   final isSearching = _searchQuery.trim().isNotEmpty;
   if (readings.isEmpty) {
     return StudentMobileUi.emptyState(
       context,
       icon: isSearching ? Icons.search_off : Icons.article_outlined,
       title: isSearching ? t.noReadingArticlesFound : t.noReadingArticlesFound,
       body: isSearching ? t.searchTopicHint : t.searchTopicHint, // tách copy khi có key riêng
       skill: SkillType.reading,
     );
   }
   ```
   (Khi có l10n key riêng cho "không khớp tìm kiếm" thì thay vào; icon `search_off` là tối thiểu cần đổi ngay.)
5. **Giữ nguyên:** `skillAppBar` (`:74-78`), `skillHubBanner`, `listLoading` (`:120-127`), `errorBanner` (`:128-134`), `ListView.separated` + `_ReadingCard` (`:150-166`), `_handleAction` review/retake (`:186-206`).

> Không đụng `StudentMobileUi` shared API (dùng chung 5 hub). `_ReadingCard`/`_Badge`/`_IconText` là private cùng file → sửa tự do nhưng map về token.

---

## 4. States (đã có — chỉ kiểm/tinh lại)
- **Loading** → `StudentMobileUi.listLoading()` (skeleton skill list) — căn giữa, padding `s10` (`:120-127`) ✔
- **Empty (0 bài)** → `emptyState(skill: reading, icon: article_outlined)` — icon box tint orange (`:140-147`) ✔
- **Search empty** → ⚠️ **tách**: `emptyState(icon: search_off, …)` khi `_searchQuery` không rỗng (step 3.4). A2/A8 yêu cầu phân biệt 2 ca.
- **Error** → `StudentMobileUi.errorBanner(message, onRetry, retryLabel)` → `_retry()` re-fetch (`:128-134, 178-184`) ✔
- **Done item** → card đổi trailing sang `skillCardReviewButton` + `skillCardRetakeButton`; badge "Đã xong" (`successBg`) + score % (`success`) (`:355-368, 280-287`) ✔

## 5. Checklist
- [ ] Search **đứng trước** filter (search → filter → list).
- [ ] Banner → search → filter → list cùng nhịp `cardGap` (bỏ 2× `sectionGap`); card đầu lên cao hơn.
- [ ] Banner/filter/icon/accent dùng `SkillType.reading` (orange); **text vẫn `textPrimary`**, amber 0 (không celebrate ở hub).
- [ ] Badge level vẫn `difficultyColor` semantic (success/warning/danger), không trộn skill color trong row.
- [ ] Search-empty (`search_off`) tách khỏi data-empty (`article_outlined`).
- [ ] Nút "Bắt đầu" dùng pattern nút shared (height 32, primary), không re-define màu thủ công.
- [ ] Không đụng `StudentMobileUi` shared API; khuôn áp lại được cho listening/listening-comp/speaking/writing/vocabulary.
- [ ] `dart analyze lib/feature/reading` 0 lỗi mới.
- [ ] Xem trên 360×640: ít bài không "top-heavy"; orange accent rõ nhưng không chói.

> Áp xong ghi vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log" (§5).
