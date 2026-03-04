export function calcHppPerPack(hppPerEgg, packSize = 10) {
    return packSize * hppPerEgg * 1.073
}

export function calcMargin(retailPrice, hppPerPack) {
    if (!retailPrice || retailPrice === 0) return 0
    return ((retailPrice - hppPerPack) / retailPrice) * 100
}

export function calcMaxPacks(stockButir, packSize = 10) {
    return Math.floor(stockButir / packSize)
}
