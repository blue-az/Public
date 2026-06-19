/**
 * Periodic Table Agent Prototype JS
 */

async function fetchCSV(url) {
    const response = await fetch(url);
    const text = await response.text();
    const rows = text.split('\n').filter(row => row.trim().length > 0);
    const headers = rows[0].split(',');
    return rows.slice(1).map(row => {
        const values = row.split(',');
        return headers.reduce((acc, header, i) => {
            acc[header.trim()] = values[i] ? values[i].trim() : '';
            return acc;
        }, {});
    });
}

const UI = {
    renderStats(elements) {
        const categories = [...new Set(elements.map(e => e.category))];
        const periods = [...new Set(elements.map(e => e.period))];
        
        const container = document.getElementById('stats-grid');
        if (!container) return;

        container.innerHTML = `
            <div class="stat"><div class="num">${elements.length}</div><div class="label">Total Elements</div></div>
            <div class="stat"><div class="num">${categories.length}</div><div class="label">Categories</div></div>
            <div class="stat"><div class="num">${periods.length}</div><div class="label">Periods</div></div>
            <div class="stat"><div class="num">IUPAC</div><div class="label">Standard</div></div>
        `;
    },

    renderElementTable(elements) {
        const tbody = document.getElementById('element-body');
        if (!tbody) return;

        // Render all elements for the full table
        tbody.innerHTML = elements.map(e => `
            <tr>
                <td><strong>${e.atomic_number}</strong></td>
                <td>${e.symbol}</td>
                <td>${e.name}</td>
                <td>${e.atomic_mass}</td>
                <td>${e.category}</td>
                <td><span class="tag" style="background: var(--line); color: var(--accent);">${e.phase_at_stp}</span></td>
            </tr>
        `).join('');
    }
};

window.initSite = async (page) => {
    const elements = await fetchCSV('data/elements.csv');

    if (page === 'index') {
        UI.renderStats(elements);
    } else if (page === 'data') {
        UI.renderElementTable(elements);
    }
};
