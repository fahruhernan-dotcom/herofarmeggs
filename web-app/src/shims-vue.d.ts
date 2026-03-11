declare module '@/directives/titlecase' {
    import { ObjectDirective } from 'vue'
    export const vTitleCase: ObjectDirective
}

declare module './directives/titlecase' {
    import { ObjectDirective } from 'vue'
    export const vTitleCase: ObjectDirective
}

declare module '../utils/sanitize' {
    export function sanitizePayload(payload: any): any;
}
