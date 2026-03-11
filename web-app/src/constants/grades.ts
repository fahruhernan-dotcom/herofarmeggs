export const GRADES = {
    hero: {
        id: 'hero',
        label: 'Telur Hero',
        shortLabel: 'HERO',
        sizeRule: '>65g',
        accentColor: '#f59e0b',
        accentDim: 'rgba(245,158,11,0.15)',
        accentBorder: 'rgba(245,158,11,0.30)',
        textOnAccent: '#000000'
    },
    salted_egg: {
        id: 'salted_egg',
        label: 'Salted Egg',
        shortLabel: 'SALTED EGG',
        sizeRule: 'Salted',
        accentColor: '#38bdf8',
        accentDim: 'rgba(56,189,248,0.15)',
        accentBorder: 'rgba(56,189,248,0.30)',
        textOnAccent: '#000000'
    }
}

// Canonical ID resolver — handles all legacy IDs
export function normalizeGrade(raw: string | undefined | null): string {
    if (!raw) return '';
    const map: Record<string, string> = {
        'hero_size': 'hero',
        'standard': 'hero',
        'standard_size': 'hero',
        'medium_size': 'hero',
        'medium': 'hero',
        'telur_asin': 'salted_egg',
        'salted_egg': 'salted_egg',
        'small_size': 'salted_egg',
        'small': 'salted_egg'
    }
    return map[raw.toLowerCase()] ?? raw;
}

export function getGradeLabel(id: string | undefined | null): string {
    if (!id) return 'Unknown'
    const normalized = normalizeGrade(id)
    return (GRADES as any)[normalized]?.label ?? (GRADES as any)[normalized]?.shortLabel ?? id
}

// Map any legacy ID to canonical ID
export function toCanonicalId(id: string | undefined | null): string {
    return normalizeGrade(id)
}
