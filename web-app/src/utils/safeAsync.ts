export function withTimeout(promise: any, ms: number = 8000, label: string = 'request'): Promise<any> {
    const timeout = new Promise<any>((_, reject) =>
        setTimeout(() => reject(new Error(`${label} timeout after ${ms}ms`)), ms)
    );
    return Promise.race([Promise.resolve(promise), timeout]);
}
