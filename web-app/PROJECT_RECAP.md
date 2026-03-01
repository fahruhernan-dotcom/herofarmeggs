# Hero Farm Terminal: Project Analysis & Logic Recap

## 1. Objectives & UI Strategy
The project aimed to deliver a **Premium ERP Terminal** for egg logistics. We moved away from generic UI into a **Glassmorphism-focused** design system using rich dark tones, vibrant accents, and cinematic micro-animations (Glow, Scale, and Pulse).

## 2. Core Functional Logic

### 📦 Inventory & Logistics Logic
- **Atomic Stock Control**: Stock is managed in individual units (Butir), but sold in Packs (10 units).
- **HPP Automation**:
    - Record arrivals with "Purchase Price".
    - Logic: `Total HPP = (Purchase Price * 10) + Packaging + Sticker + Card`.
    - Automated global sync: Updating the cost of a packaging item automatically recalculates the HPP for every egg product using it.
- **RESTOCK Calculator**: For packaging, we use the formula `(Price + Shipping) / (Order - Damaged)` to ensure the true cost is captured even if some items are broken on arrival.

### 💰 Revenue & Sales Terminal Logic
- **POS Intelligence**: Real-time stock presence indicators for Hero, Standard, and Salted eggs.
- **Dynamic Override**: Clerks can click on local cart prices to override them manually for specific batches.
- **Supply Chain Depletion**: Confirming a sale automatically depletes:
    - 10 butir of eggs per pack.
    - 1 unit of packaging, 1 sticker, and 1 card per pack.
- **Customer Auto-Register**: If a customer isn't in the database, the system creates their profile automatically during checkout.

### 🚛 Supplier & Procurement Logic
- **Procurement Mapping**: Each supplier has a "Catalog".
- **Arrival Suggestions**: Selecting a supplier during a stock arrival automatically pulls their catalog prices as suggestions to minimize human error.
- **Visual Segregation**: Cards change accent colors based on procurement focus (Telur Hero = Gold, Packaging = Blue).

## 3. Latest Cinematic UI/UX Fixes
- **Robust Headers**: Supplier cards now use a flex-space layout. Vendor names and Action icons (Edit/Delete) will **never overlap**, ensuring a clean interface even with long farm names.
- **Interaction feedback**: Added scale transformations and shadow glows to cards on hover for a high-end feel.
- **Route Key Persistence**: Implemented a `:key="$route.fullPath"` on the main view to solve the "Hard Refresh" requirement—data now stays fresh every time you click a menu.

---
*Technical Audit complete. Code pushed to GitHub.*
