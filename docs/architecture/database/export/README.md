# Export ERD

3 file **`erDiagram`** trắng đen — quan hệ kiểu cũ `||--o{`, `|o--o{` (chân quạ, không nhãn `0..1`):

| File | Mục Word |
|------|----------|
| `erd-hinh-1a-user-lop.mmd` | 2.x.2.1 |
| `erd-hinh-1b-de-thi.mmd` | 2.x.2.2 |
| `erd-hinh-2-hoc-tap.mmd` | 2.x.2.3 |

Khôi phục từ snapshot: `node erd-restore-er.js` (nguồn `_snapshot-*.er.txt`).

### Export

```powershell
cd docs/architecture/database/export
.\export-erd.ps1
node build-diagrams-md.js
```
