<script setup lang="ts">
const printSticker = () => {
    window.print();
};
</script>

<template>
    <div class="sticker-page">
        <div class="controls no-print">
            <h1 class="text-3xl font-black mb-2 text-[#4A332D]">Sticker Studio</h1>
            <p class="mb-8 text-lg opacity-70">Premium Packaging Design (20cm x 8cm)</p>
            <button @click="printSticker" class="btn-print">
                <i class="lucide-printer"></i> Save as PDF / Print
            </button>
        </div>

        <div class="sticker-container">
            <!-- The actual sticker -->
            <div class="sticker-canvas" id="sticker">
                <!-- PAPER TEXTURE OVERLAY -->
                <div class="paper-texture"></div>
                
                <!-- DECORATIVE WAVY LINES CORNERS -->
                <!-- TOP RIGHT -->
                <svg class="decorative-waves wave-tr" viewBox="0 0 100 100" preserveAspectRatio="none">
                    <path d="M0,20 Q30,0 60,30 T120,40" fill="none" stroke="#87A08B" stroke-width="1.8" opacity="0.5"/>
                    <path d="M0,35 Q30,15 60,45 T120,55" fill="none" stroke="#87A08B" stroke-width="1.8" opacity="0.3"/>
                    <path d="M0,50 Q30,30 60,60 T120,70" fill="none" stroke="#87A08B" stroke-width="1.8" opacity="0.2"/>
                </svg>

                <!-- BOTTOM RIGHT -->
                <svg class="decorative-waves wave-br" viewBox="0 0 100 100" preserveAspectRatio="none">
                    <path d="M0,60 Q40,90 80,60 T140,50" fill="none" stroke="#8D4B38" stroke-width="2" opacity="0.5"/>
                    <path d="M0,75 Q40,105 80,75 T140,65" fill="none" stroke="#8D4B38" stroke-width="2" opacity="0.3"/>
                    <path d="M0,90 Q40,120 80,90 T140,80" fill="none" stroke="#8D4B38" stroke-width="2" opacity="0.15"/>
                </svg>

                <!-- BOTTOM LEFT -->
                <svg class="decorative-waves wave-bl" viewBox="0 0 100 100" preserveAspectRatio="none">
                    <path d="M0,30 Q40,10 80,40 T140,50" fill="none" stroke="#87A08B" stroke-width="1.8" opacity="0.4"/>
                    <path d="M0,50 Q40,30 80,60 T140,70" fill="none" stroke="#87A08B" stroke-width="1.8" opacity="0.25"/>
                    <path d="M0,70 Q40,50 80,80 T140,90" fill="none" stroke="#87A08B" stroke-width="1.8" opacity="0.1"/>
                </svg>

                <!-- TOP LEFT -->
                <svg class="decorative-waves wave-tl" viewBox="0 0 100 100" preserveAspectRatio="none">
                    <path d="M0,40 Q40,70 80,40 T140,30" fill="none" stroke="#8D4B38" stroke-width="1.2" opacity="0.1"/>
                </svg>

                <div class="main-content">
                    <!-- LOGO AREA -->
                    <div class="logo-area">
                        <div class="hero-logo">
                            <svg viewBox="0 0 100 115" xmlns="http://www.w3.org/2000/svg">
                                <!-- EGG FRAME -->
                                <path d="M50,10 C28,10 12,45 12,78 C12,102 28,110 50,110 C72,110 88,102 88,78 C88,45 72,10 50,10" fill="none" stroke="#FF8C00" stroke-width="5" stroke-linecap="round"/>
                                <!-- REFINED DUCK SILHOUETTE -->
                                <path d="M48,32 C42,32 35,38 35,48 C35,58 42,62 52,68 C52,68 25,65 20,85 C20,102 38,108 58,104 C72,100 75,85 75,72 C75,65 72,58 68,55 C68,55 82,55 85,48 C85,45 75,45 70,50 C70,38 60,32 48,32 Z" fill="#FF8C00"/>
                                <!-- EYE DETAIL -->
                                <circle cx="48" cy="48" r="1.8" fill="white"/>
                            </svg>
                        </div>
                    </div>

                    <!-- TEXT AREA -->
                    <div class="text-area">
                        <div class="brand-titles">
                            <h1 class="brand-main">HERO FARM</h1>
                            <h1 class="brand-sub">FRESH EGGS</h1>
                        </div>
                        
                        <p class="product-description">Telur Bebek Super - Oranye & Higienis</p>
                        
                        <div class="instruction-wrap">
                            <span class="instruction-label">Simpan Lancip di Bawah</span>
                            <div class="mini-egg">
                                <svg viewBox="0 0 24 24" fill="none" stroke="#87A08B" stroke-width="2.5">
                                    <path d="M12 4C8 4 6 8 6 12C6 16 8 20 12 20C16 20 18 16 18 12C18 8 16 4 12 4Z" />
                                    <path d="M12 9V15M12 15L9 12M12 15L15 12" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- PRINT GUIDE -->
        <div class="no-print print-guide">
            <div class="guide-header">
                <i class="lucide-info"></i>
                <span>Printing Guide</span>
            </div>
            <ul>
                <li>Set <strong>Destination</strong> to "Save as PDF" or select your printer.</li>
                <li>Set <strong>Scale</strong> to "Default" or "100%".</li>
                <li>Set <strong>Margins</strong> to "None" if possible.</li>
                <li>This canvas is precisely <strong>20cm x 8cm</strong>.</li>
            </ul>
        </div>
    </div>
</template>

<style scoped>
.sticker-page {
    padding: 60px 20px;
    display: flex;
    flex-direction: column;
    align-items: center;
    min-height: 100vh;
    background-color: #ededed;
    font-family: 'Outfit', 'Inter', sans-serif;
}

.controls {
    text-align: center;
    margin-bottom: 30px;
}

.btn-print {
    background: #E67E00;
    color: white;
    padding: 14px 40px;
    border-radius: 6px;
    font-weight: 800;
    font-size: 1rem;
    display: inline-flex;
    align-items: center;
    gap: 12px;
    border: none;
    cursor: pointer;
    transition: all 0.2s ease;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.btn-print:hover {
    background: #D35400;
    transform: translateY(-1px);
}

.sticker-container {
    padding: 3px;
    background: white;
    box-shadow: 0 40px 80px rgba(0,0,0,0.15);
    margin-bottom: 50px;
}

.sticker-canvas {
    width: 20cm;
    height: 8cm;
    background-color: #F1EBD7; /* Warm natural beige from image */
    position: relative;
    overflow: hidden;
    color: #3E2723;
}

/* PAPER TEXTURE */
.paper-texture {
    position: absolute;
    inset: 0;
    background-image: url('https://www.transparenttextures.com/patterns/felt.png');
    opacity: 0.15;
    pointer-events: none;
    z-index: 1;
}

/* DECORATIVE SVG WAVES */
.decorative-waves {
    position: absolute;
    width: 320px;
    height: 220px;
    pointer-events: none;
    z-index: 2;
}

.wave-tr { top: -30px; right: -50px; transform: rotate(10deg); }
.wave-br { bottom: -60px; right: -40px; transform: rotate(-5deg); }
.wave-bl { bottom: -70px; left: -70px; transform: rotate(175deg); }
.wave-tl { top: -80px; left: -80px; transform: rotate(-175deg); }

.main-content {
    position: relative;
    z-index: 10;
    height: 100%;
    display: flex;
    align-items: center;
    padding-left: 95px;
    gap: 55px;
}

/* LOGO */
.logo-area {
    width: 175px;
    flex-shrink: 0;
}

.hero-logo {
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.05));
}

/* TEXT AREA */
.text-area {
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.brand-titles {
    margin-bottom: 5px;
}

.brand-main, .brand-sub {
    font-size: 72px;
    font-weight: 950;
    color: #E67E00; /* High saturation brand orange */
    line-height: 0.8;
    margin: 0;
    letter-spacing: -3.5px;
    font-family: 'Outfit', sans-serif;
}

.product-description {
    font-size: 22px;
    font-weight: 700;
    color: #4A332D;
    margin: 15px 0 30px 0;
    opacity: 0.9;
    letter-spacing: -0.2px;
}

.instruction-wrap {
    display: flex;
    align-items: center;
    gap: 12px;
}

.instruction-label {
    font-size: 23px;
    font-weight: 750;
    color: #87A08B; /* Exact muted sage from image */
}

.mini-egg {
    width: 32px;
    height: 32px;
    background: transparent;
}

/* PRINT GUIDE */
.print-guide {
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 24px;
    max-width: 450px;
    color: #555;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
}

.guide-header {
    display: flex;
    align-items: center;
    gap: 10px;
    color: #333;
    font-weight: 800;
    margin-bottom: 12px;
}

.print-guide ul {
    list-style: disc;
    padding-left: 20px;
    font-size: 0.95rem;
    line-height: 1.6;
}

/* PRINTING OVERRIDES */
@media print {
    body {
        margin: 0;
        padding: 0;
        background: white !important;
    }
    .sticker-page {
        padding: 0;
        background: white;
    }
    .controls, .no-print, .print-guide {
        display: none !important;
    }
    .sticker-container {
        position: fixed;
        left: 0;
        top: 0;
        box-shadow: none;
        padding: 0;
        margin: 0;
        background: transparent;
    }
    .sticker-canvas {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
    @page {
        size: 20cm 8cm;
        margin: 0;
    }
}
</style>
