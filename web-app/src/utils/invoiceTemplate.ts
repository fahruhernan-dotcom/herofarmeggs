export const generateInvoiceHTML = (data: {
    invoiceNo: string;
    date: string;
    customerName: string;
    customerPhone?: string;
    items: Array<{
        description: string;
        quantity: number;
        unit: string;
        price: number;
        total: number;
    }>;
    grandTotal: number;
}) => {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice ${data.invoiceNo}</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&family=JetBrains+Mono:wght@700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #FF8C00;
            --text-main: #1a1a1a;
            --text-dim: #666666;
            --border: #e5e5e5;
            --bg-soft: #f9f9f9;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            -webkit-print-color-adjust: exact;
        }

        body {
            font-family: 'Inter', sans-serif;
            color: var(--text-main);
            background: white;
            line-height: 1.5;
            padding: 40px;
        }

        .invoice-wrapper {
            max-width: 800px;
            margin: 0 auto;
            border: 1px solid var(--border);
            padding: 50px;
            position: relative;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 60px;
        }

        .brand h1 {
            font-size: 24px;
            font-weight: 900;
            letter-spacing: -1px;
            color: var(--text-main);
        }

        .brand p {
            font-size: 12px;
            color: var(--primary);
            font-weight: 700;
            letter-spacing: 2px;
            text-transform: uppercase;
        }

        .meta {
            text-align: right;
        }

        .meta h2 {
            font-size: 32px;
            font-weight: 900;
            margin-bottom: 10px;
            color: var(--border);
        }

        .meta p {
            font-size: 14px;
            font-weight: 600;
        }

        .meta .inv-no {
            font-family: 'JetBrains Mono', monospace;
            color: var(--primary);
        }

        .billing {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 40px;
            margin-bottom: 60px;
        }

        .bill-to h3 {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-dim);
            margin-bottom: 8px;
        }

        .bill-to .cust-name {
            font-size: 18px;
            font-weight: 800;
        }

        .bill-to .cust-phone {
            font-size: 14px;
            color: var(--text-dim);
        }

        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 40px;
        }

        .items-table th {
            text-align: left;
            padding: 15px 10px;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-bottom: 2px solid var(--text-main);
            color: var(--text-dim);
        }

        .items-table td {
            padding: 20px 10px;
            border-bottom: 1px solid var(--border);
            font-size: 14px;
        }

        .desc-col { font-weight: 700; }
        .qty-col { font-family: 'JetBrains Mono', monospace; }
        .price-col, .total-col { text-align: right; font-weight: 600; }

        .footer {
            display: flex;
            justify-content: flex-end;
        }

        .total-box {
            width: 250px;
            background: var(--bg-soft);
            padding: 20px;
            border-radius: 8px;
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .total-row .label {
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            color: var(--text-dim);
        }

        .total-row .val {
            font-size: 20px;
            font-weight: 900;
            color: var(--primary);
        }

        .thanks {
            margin-top: 60px;
            text-align: center;
            font-size: 12px;
            color: var(--text-dim);
            font-style: italic;
        }

        .watermark {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%) rotate(-45deg);
            font-size: 120px;
            font-weight: 900;
            color: rgba(0,0,0,0.02);
            z-index: -1;
            white-space: nowrap;
            pointer-events: none;
        }

        @media print {
            body { padding: 0; }
            .invoice-wrapper { border: none; width: 100%; max-width: none; }
        }
    </style>
</head>
<body>
    <div class="invoice-wrapper">
        <div class="watermark">HERO FARM</div>
        
        <div class="header">
            <div class="brand">
                <h1>HERO FARM</h1>
                <p>Pure. Premium. Elite.</p>
            </div>
            <div class="meta">
                <h2>INVOICE</h2>
                <p>No: <span class="inv-no">${data.invoiceNo}</span></p>
                <p>Date: ${data.date}</p>
            </div>
        </div>

        <div class="billing">
            <div class="bill-to">
                <h3>Bill To</h3>
                <p class="cust-name">${data.customerName}</p>
                <p class="cust-phone">${data.customerPhone || '-'}</p>
            </div>
            <div class="bill-from">
                <h3>Issued By</h3>
                <p class="cust-name">HERO FARM Indonesia</p>
                <p class="cust-phone">Logistics & Supply Terminal</p>
            </div>
        </div>

        <table class="items-table">
            <thead>
                <tr>
                    <th style="width: 50%">Description</th>
                    <th style="text-align: center">Qty</th>
                    <th style="text-align: right">Price</th>
                    <th style="text-align: right">Amount</th>
                </tr>
            </thead>
            <tbody>
                ${data.items.map(item => `
                <tr>
                    <td class="desc-col">${item.description}</td>
                    <td class="qty-col" style="text-align: center">${item.quantity} ${item.unit}</td>
                    <td class="price-col">Rp ${item.price.toLocaleString('id-ID')}</td>
                    <td class="total-col">Rp ${item.total.toLocaleString('id-ID')}</td>
                </tr>
                `).join('')}
            </tbody>
        </table>

        <div class="footer">
            <div class="total-box">
                <div class="total-row">
                    <span class="label">Amount Due</span>
                    <span class="val">Rp ${data.grandTotal.toLocaleString('id-ID')}</span>
                </div>
            </div>
        </div>

        <div class="thanks">
            <p>Thank you for choosing Hero Farm eggs. Your support for premium local farm is appreciated.</p>
        </div>
    </div>
</body>
</html>
  `;
};
