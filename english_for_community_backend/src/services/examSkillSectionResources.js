/**
 * Resolve CMS exercise links on skills_exam sections (resources[] vs legacy resourceId).
 */

export function resourcesFromSkillSection(sec) {
  if (!sec || typeof sec !== 'object') return [];
  if (Array.isArray(sec.resources) && sec.resources.length > 0) {
    return sec.resources
      .map((r) => {
        const raw = r && typeof r === 'object' ? r : {};
        const id = String(raw.id ?? raw._id ?? raw.resourceId ?? '').trim();
        const title = String(raw.title ?? raw.name ?? raw.resourceTitle ?? '').trim();
        return { id, title };
      })
      .filter((r) => r.id);
  }
  const id = sec.resourceId ? String(sec.resourceId).trim() : '';
  if (!id) return [];
  return [
    {
      id,
      title: sec.resourceTitle ? String(sec.resourceTitle).trim() : '',
    },
  ];
}

export function primaryResourceIdFromSection(sec) {
  const resources = resourcesFromSkillSection(sec);
  return resources.length > 0 ? resources[0].id : '';
}

/** Ensures resourceId + resources[] stay in sync for student clients and validators. */
export function normalizeSkillSection(sec) {
  if (!sec || typeof sec !== 'object') return sec;
  const resources = resourcesFromSkillSection(sec);
  if (resources.length === 0) return { ...sec };
  return {
    ...sec,
    resourceId: resources[0].id,
    resourceTitle: resources[0].title || sec.resourceTitle || '',
    resources,
  };
}

export function normalizeExamSnapshot(examSnapshot) {
  if (!examSnapshot || typeof examSnapshot !== 'object') return examSnapshot;
  const sections = Array.isArray(examSnapshot.sections) ? examSnapshot.sections : [];
  return {
    ...examSnapshot,
    sections: sections.map((sec) => normalizeSkillSection(sec)),
  };
}

function skillContentSections(examLike) {
  if (!examLike?.sections) return [];
  return examLike.sections.filter(
    (s) => s && (s.sectionKind === 'skill_content' || s.sectionKind == null) && s.skill
  );
}

/**
 * Fills missing resourceId/resources on attempt snapshots from the current published exam
 * (e.g. teacher added Speaking after the live session was created).
 */
export function healExamSnapshotFromLiveExam(snapshot, liveExam) {
  const snap = normalizeExamSnapshot(snapshot || {});
  const live = normalizeExamSnapshot(liveExam || {});
  const liveBySkill = new Map();
  for (const sec of skillContentSections(live)) {
    liveBySkill.set(String(sec.skill), sec);
  }
  const sections = (snap.sections || []).map((sec) => {
    if (!sec?.skill) return sec;
    if (primaryResourceIdFromSection(sec)) return normalizeSkillSection(sec);
    const liveSec = liveBySkill.get(String(sec.skill));
    if (liveSec && primaryResourceIdFromSection(liveSec)) {
      return normalizeSkillSection({ ...sec, ...liveSec });
    }
    return sec;
  });
  return { ...snap, sections };
}
