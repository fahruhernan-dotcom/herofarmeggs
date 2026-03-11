import { toTitleCase } from './formatters'

const TITLE_CASE_FIELDS = [
    'customer_name', 'name', 'supplier_name', 'contact_person',
    'location', 'address', 'alamat', 'catatan', 'notes',
    'reason', 'alasan', 'conducted_by', 'full_name', 'position',
    'catatan_batch', 'buyer_name'
]

/**
 * Ensures specific text fields are formatted as Title Case
 * to enforce database consistency prior to inserting/updating.
 * @param {Object} payload The data object being sent to Supabase
 * @returns {Object} A new sanitized data object
 */
export function sanitizePayload(payload: any): any {
    if (!payload || typeof payload !== 'object') return payload;

    const result = { ...payload }
    for (const field of TITLE_CASE_FIELDS) {
        if (field in result && typeof result[field] === 'string') {
            result[field] = toTitleCase(result[field])
        }
    }
    return result
}
