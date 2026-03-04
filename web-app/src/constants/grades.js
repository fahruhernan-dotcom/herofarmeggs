export const GRADES = {
    hero: {
        id: 'hero',
        label: 'Hero',
        sizeRule: '>65g',
        accentColor: '#f59e0b',
        accentDim: 'rgba(245,158,11,0.15)',
        accentBorder: 'rgba(245,158,11,0.30)',
        textOnAccent: '#000000'
    },
    medium: {
        id: 'medium',
        label: 'Medium',
        sizeRule: '55-65g',
        accentColor: '#8b5cf6',
        accentDim: 'rgba(139,92,246,0.15)',
        accentBorder: 'rgba(139,92,246,0.30)',
        textOnAccent: '#ffffff'
    },
    small: {
        id: 'small',
        label: 'Small',
        sizeRule: '<55g',
        accentColor: '#38bdf8',
        accentDim: 'rgba(56,189,248,0.15)',
        accentBorder: 'rgba(56,189,248,0.30)',
        textOnAccent: '#000000'
    }
}

export function getGradeLabel(id) {
    if (id === 'hero_size' || id === 'hero') return GRADES.hero.label
    if (id === 'standard_size' || id === 'medium') return GRADES.medium.label
    if (id === 'salted_egg' || id === 'small') return GRADES.small.label
    return id
}
