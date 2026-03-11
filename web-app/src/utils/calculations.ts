export function calcHppPerPack(
    hppPerEgg: number,
    packSize: number = 10,
    costPackaging: number = 0,
    costSticker: number = 0,
    costCard: number = 0
): number {
    return (packSize * hppPerEgg) + costPackaging + costSticker + costCard
}

export function calcMargin(retailPrice: number, hppPerPack: number): number {
    if (!retailPrice || retailPrice === 0) return 0
    return ((retailPrice - hppPerPack) / retailPrice) * 100
}

export function calcMaxPacks(stockButir: number, packSize: number = 10): number {
    return Math.floor(stockButir / packSize)
}
