/**
 * AZ Water Report Site
 * Visuals derived from Public/Proto
 */

async function fetchCSV(url) {
    const response = await fetch(url);
    const text = await response.text();
    const rows = text.split('\n').filter(row => row.trim().length > 0);
    const headers = rows[0].split(',');
    return rows.slice(1).map(row => {
        const values = row.split(',');
        return headers.reduce((acc, header, i) => {
            acc[header.trim()] = values[i].trim();
            return acc;
        }, {});
    });
}

const UI = {
    renderStats(reservoirs) {
        const totalStorage = reservoirs.reduce((sum, r) => sum + parseInt(r.current_storage_af), 0);
        const avgFull = Math.round(reservoirs.reduce((sum, r) => sum + parseInt(r.percent_full), 0) / reservoirs.length);
        
        const container = document.getElementById('stats-grid');
        if (!container) return;

        container.innerHTML = `
            <div class="stat"><div class="num">${totalStorage.toLocaleString()}</div><div class="label">Total Storage (AF)</div></div>
            <div class="stat"><div class="num">${avgFull}%</div><div class="label">System Fullness</div></div>
            <div class="stat"><div class="num">${reservoirs.length}</div><div class="label">Active Reservoirs</div></div>
            <div class="stat"><div class="num">SRP</div><div class="label">Authority</div></div>
        `;
    },

    renderReservoirTable(reservoirs) {
        const tbody = document.getElementById('reservoir-body');
        if (!tbody) return;

        tbody.innerHTML = reservoirs.map(r => `
            <tr>
                <td><strong>${r.name}</strong></td>
                <td>${r.system}</td>
                <td>${r.percent_full}%</td>
                <td>${parseFloat(r.current_elevation_ft).toFixed(2)}'</td>
                <td>${parseInt(r.current_storage_af).toLocaleString()}</td>
                <td><span class="tag" style="background: ${parseInt(r.change_24h_af) >= 0 ? 'var(--good)' : '#f87171'}; color: #062c20;">
                    ${parseInt(r.change_24h_af) >= 0 ? '+' : ''}${parseInt(r.change_24h_af).toLocaleString()}
                </span></td>
            </tr>
        `).join('');
    },

    renderRampGrid(ramps) {
        const container = document.getElementById('ramp-grid');
        if (!container) return;

        container.innerHTML = ramps.map(r => {
            const depth = parseInt(r.depth_ft);
            const isUsable = depth > 0;
            return `
                <article class="card">
                    <span class="badge" style="border-color: ${isUsable ? 'var(--good)' : '#f87171'}; color: ${isUsable ? 'var(--good)' : '#f87171'}">
                        ${isUsable ? 'Usable' : 'High & Dry'}
                    </span>
                    <h3>${r.ramp_name}</h3>
                    <p class="subtitle">${r.reservoir_name}</p>
                    <div style="margin-top: 0.5rem; font-size: 0.9rem; color: var(--accent-2)">
                        Depth: ${depth} ft
                    </div>
                </article>
            `;
        }).join('');
    }
};

window.initSite = async (page) => {
    const reservoirs = await fetchCSV('data/reservoirs.csv');
    const ramps = await fetchCSV('data/ramps.csv');

    if (page === 'index') {
        UI.renderStats(reservoirs);
    } else if (page === 'data') {
        UI.renderReservoirTable(reservoirs);
        UI.renderRampGrid(ramps);
    }
};
