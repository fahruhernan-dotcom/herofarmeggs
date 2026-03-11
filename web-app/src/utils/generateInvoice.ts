import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import { supabase } from "../lib/supabase";

interface InvoiceItem {
    product_name: string;
    quantity: number;
    unit: string;
    unit_price: number;
    subtotal: number;
}

interface InvoiceData {
    invoiceNumber: string;
    customerName: string;
    customerPhone?: string;
    customerAddress?: string;
    items: InvoiceItem[];
    total: number;
    date: string;
    notes?: string;
    taxRate?: number;
}

const DEFAULT_COLORS = {
    black: [33, 33, 33] as [number, number, number],
    darkGray: [55, 65, 81] as [number, number, number],
    medGray: [107, 114, 128] as [number, number, number],
    lightGray: [229, 231, 235] as [number, number, number],
    bgGray: [249, 250, 251] as [number, number, number],
    brand: [255, 140, 0] as [number, number, number], // Hero Farm Orange
};

function formatRp(val: number) {
    return `Rp ${new Intl.NumberFormat('id-ID').format(val || 0)}`;
}

export async function generateInvoicePDF(data: InvoiceData) {
    // 1. Fetch Company Settings for Header
    const { data: comp } = await supabase.from('company_settings').select('*').limit(1).single();
    const { data: tax } = await supabase.from('tax_settings').select('rate').eq('is_active', true).limit(1).single();

    const companyName = comp?.brand_name || "HERO FARM EGGS";
    const companyAddress = comp?.address || "Bligo, Sidoarjo, Jawa Timur";
    const companyPhone = comp?.phone || "+62 812-xxxx-xxxx";
    const bankInfo = comp?.bank_name ? `${comp.bank_name}: ${comp.bank_account} a/n ${comp.bank_holder}` : "";

    // A5 = 148 x 210 mm (Professional standard)
    const doc = new jsPDF({ unit: "mm", format: "a5" });
    const pageW = 148;
    const pageH = 210;
    const margin = 12;
    const contentW = pageW - (margin * 2);

    let y = 15;

    // ─── BRAND HEADER ───
    doc.setFont("helvetica", "bold");
    doc.setFontSize(16);
    doc.setTextColor(...DEFAULT_COLORS.brand);
    doc.text(companyName, margin, y);

    doc.setFontSize(14);
    doc.setTextColor(...DEFAULT_COLORS.black);
    doc.text("INVOICE", pageW - margin, y, { align: "right" });

    y += 6;
    doc.setFont("helvetica", "normal");
    doc.setFontSize(8);
    doc.setTextColor(...DEFAULT_COLORS.medGray);
    doc.text(companyAddress, margin, y);
    doc.text(data.invoiceNumber, pageW - margin, y, { align: "right" });

    y += 4;
    doc.text(`Phone: ${companyPhone}`, margin, y);
    doc.text(data.date, pageW - margin, y, { align: "right" });

    // Divider line
    y += 6;
    doc.setDrawColor(...DEFAULT_COLORS.lightGray);
    doc.setLineWidth(0.5);
    doc.line(margin, y, pageW - margin, y);

    // ─── CUSTOMER SECTION ───
    y += 10;
    doc.setFont("helvetica", "bold");
    doc.setFontSize(9);
    doc.setTextColor(...DEFAULT_COLORS.medGray);
    doc.text("BILL TO:", margin, y);

    y += 5;
    doc.setFontSize(10);
    doc.setTextColor(...DEFAULT_COLORS.black);
    doc.text(data.customerName, margin, y);

    if (data.customerPhone) {
        y += 4.5;
        doc.setFontSize(9);
        doc.setFont("helvetica", "normal");
        doc.text(data.customerPhone, margin, y);
    }

    if (data.customerAddress) {
        y += 4.5;
        const addrLines = doc.splitTextToSize(data.customerAddress, contentW * 0.6);
        doc.text(addrLines, margin, y);
        y += (addrLines.length - 1) * 4;
    }

    y += 10;

    // ─── ITEMS TABLE ───
    autoTable(doc, {
        startY: y,
        head: [["DESCRIPTION", "QTY", "PRICE", "SUBTOTAL"]],
        body: data.items.map(i => [
            i.product_name,
            `${i.quantity} ${i.unit}`,
            formatRp(i.unit_price),
            formatRp(i.subtotal)
        ]),
        theme: 'grid',
        headStyles: {
            fillColor: DEFAULT_COLORS.brand,
            textColor: [255, 255, 255],
            fontStyle: 'bold',
            fontSize: 8,
            halign: 'center'
        },
        bodyStyles: {
            fontSize: 8,
            textColor: DEFAULT_COLORS.darkGray,
        },
        columnStyles: {
            0: { cellWidth: 'auto' },
            1: { cellWidth: 20, halign: 'center' },
            2: { cellWidth: 30, halign: 'right' },
            3: { cellWidth: 30, halign: 'right' }
        },
        margin: { left: margin, right: margin }
    });

    // ─── SUMMARY SECTION ───
    let finalY = (doc as any).lastAutoTable.finalY + 10;

    // Notes area
    if (data.notes) {
        doc.setFont("helvetica", "bold");
        doc.setFontSize(8);
        doc.setTextColor(DEFAULT_COLORS.medGray);
        doc.text("NOTES:", margin, finalY);
        finalY += 4;
        doc.setFont("helvetica", "normal");
        const noteLines = doc.splitTextToSize(data.notes, contentW * 0.5);
        doc.text(noteLines, margin, finalY);
    }

    // Totals column
    const totalX = pageW - margin - 50;
    let totalY = (doc as any).lastAutoTable.finalY + 10;

    doc.setFontSize(9);
    doc.setTextColor(DEFAULT_COLORS.darkGray);
    doc.text("Subtotal:", totalX, totalY);
    doc.text(formatRp(data.total), pageW - margin, totalY, { align: "right" });

    if (data.taxRate) {
        totalY += 6;
        const taxAmount = (data.total * data.taxRate) / 100;
        doc.text(`Tax (${data.taxRate}%):`, totalX, totalY);
        doc.text(formatRp(taxAmount), pageW - margin, totalY, { align: "right" });

        totalY += 2;
        doc.line(totalX, totalY + 2, pageW - margin, totalY + 2);
        totalY += 6;
        doc.setFont("helvetica", "bold");
        doc.setFontSize(11);
        doc.setTextColor(DEFAULT_COLORS.black);
        doc.text("GRAND TOTAL:", totalX, totalY);
        doc.text(formatRp(data.total + taxAmount), pageW - margin, totalY, { align: "right" });
    } else {
        totalY += 2;
        doc.line(totalX, totalY + 2, pageW - margin, totalY + 2);
        totalY += 8;
        doc.setFont("helvetica", "bold");
        doc.setFontSize(11);
        doc.setTextColor(DEFAULT_COLORS.black);
        doc.text("GRAND TOTAL:", totalX, totalY);
        doc.text(formatRp(data.total), pageW - margin, totalY, { align: "right" });
    }

    // ─── FOOTER & PAYMENT ───
    y = pageH - 30;
    doc.setFontSize(8);
    doc.setTextColor(DEFAULT_COLORS.medGray);
    doc.text("PAYMENT INFORMATION:", margin, y);

    y += 5;
    doc.setFont("helvetica", "bold");
    doc.setTextColor(DEFAULT_COLORS.black);
    doc.text(bankInfo, margin, y);

    y = pageH - 12;
    doc.setFont("helvetica", "italic");
    doc.setFontSize(7);
    doc.setTextColor(DEFAULT_COLORS.medGray);
    doc.text("Thank you for your business! - Hero Farm Tactical Operations", pageW / 2, y, { align: "center" });

    doc.save(`${data.invoiceNumber}.pdf`);
}
