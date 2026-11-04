// Sandcastle world map: a dependency-free interactive world map with one sandcastle per beach.
// Needs world.js (window.WORLD_LAND) loaded first; hawaii.js (window.HAWAII_LAND) adds a detailed coastline for deep zoom. Themed through --bm-* CSS custom properties.
//   const map = BeachMap.mount(el, beaches, {describe: b => ({place, title, text, meta: [a, b], href, cta})});
//   Options: onSelect: b => {} to handle castle clicks yourself instead of the built-in card; padding: () => ({top, right, bottom, left}) px kept clear for overlays; wheel: 'always' to zoom on plain scroll.
//   map.filter(b => ...);
(function () {
  const W = 1000, TOP = 14, H = 404; // visible frame: about 85°N to 60°S
  const MAX_K = 1500; // deep enough to tell neighbouring beaches apart, shallow enough for the coastline data
  let uid = 0;
  const project = (lat, lon) => [(lon + 180) / 360 * W, (90 - lat) / 180 * 500];
  const esc = s => String(s).replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
  const reduced = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

  const SHAPE = 'M-20 0C-20-6-17-9-17-12V-26h3.4v3h3.2v-3h3.4v14h1V-34h2.4v2.6h2.4v-2.6h2.4v2.6h2.4v-2.6h2.4v22h1V-26h3.4v3h3.2v-3h3.4v14C17-9 20-6 20 0Z';
  const CASTLE = `<svg class="bm-castle" viewBox="-26 -50 52 56" aria-hidden="true">
    <ellipse class="bm-shadow" cx="0" cy="1.5" rx="23" ry="4"/>
    <path class="bm-pole" d="M0-33V-46"/><path class="bm-flag" d="M0-46l10 3.2-10 3.2Z"/>
    <path class="bm-outline" d="${SHAPE}"/><path class="bm-sand" d="${SHAPE}"/>
    <path class="bm-detail" d="M-16.5-12H16.5M-15-5h4M10-3.5h4"/>
    <path class="bm-door" d="M-3.6 0V-5.5a3.6 3.6 0 0 1 7.2 0V0Z"/>
    <circle class="bm-door" cx="-12" cy="-18" r="1.4"/><circle class="bm-door" cx="12" cy="-18" r="1.4"/><circle class="bm-door" cx="0" cy="-24" r="1.6"/>
  </svg>`;
  // Little cartoon swells scattered across the open ocean.
  const WAVES = [[12, -140], [-28, -118], [38, -42], [-32, -18], [-22, 76], [-45, 108], [32, 168], [-52, 30], [52, -158], [8, -28]]
    .map(([lat, lon]) => { const [x, y] = project(lat, lon); return `<path d="M${x - 12} ${y}q3-4 6 0t6 0t6 0t6 0M${x - 6} ${y + 6}q3-4 6 0t6 0"/>`; }).join('');
  // High-detail coastlines drawn over the coarse world, each with a few tiny swells sized for close zoom.
  const DETAIL = (window.HAWAII_LAND ? [window.HAWAII_LAND] : []).map(d =>
    `<g transform="translate(${d.x} ${d.y}) scale(${d.scale})"><path class="bm-shore" d="${d.d}"/><path class="bm-land" d="${d.d}"/></g>` +
    (d.waves || []).map(([lat, lon]) => { const [x, y] = project(lat, lon); return `<g class="bm-waves" transform="translate(${x} ${y}) scale(.0025)"><path d="M-12 0q3-4 6 0t6 0t6 0t6 0M-6 6q3-4 6 0t6 0"/></g>`; }).join('')).join('');
  const GRID = [0, 23.44, -23.44].map(lat => `<path class="bm-grid" d="M0 ${project(lat, 0)[1]}H${W}"/>`).join('');

  const CSS = `
.beach-map{position:relative;overflow:hidden;width:100%;box-sizing:border-box;aspect-ratio:${W}/${H};min-height:360px;background:var(--bm-sea);border:var(--bm-border,0);border-radius:var(--bm-radius,18px);touch-action:none;user-select:none;-webkit-user-select:none;cursor:grab;color:var(--bm-ink)}
.beach-map.dragging{cursor:grabbing}
.bm-svg{position:absolute;inset:0;width:100%;height:100%;display:block}
.bm-waves path{fill:none;stroke:var(--bm-sea-line);stroke-width:1.6;stroke-linecap:round;vector-effect:non-scaling-stroke}
.bm-grid{fill:none;stroke:var(--bm-sea-line);stroke-width:1;stroke-dasharray:2 7;vector-effect:non-scaling-stroke}
.bm-shore{fill:var(--bm-shore);stroke:var(--bm-shore);stroke-width:7;stroke-linejoin:round;vector-effect:non-scaling-stroke}
.bm-land{fill:var(--bm-land);stroke:var(--bm-ink);stroke-width:1.5;stroke-linejoin:round;vector-effect:non-scaling-stroke}
.bm-markers{position:absolute;inset:0;pointer-events:none}
.bm-marker{position:absolute;left:0;top:0;display:flex;flex-direction:column;align-items:center;margin:0;padding:0;border:0;background:none;color:inherit;font:inherit;cursor:pointer;pointer-events:auto;transition:opacity .3s}
.bm-marker.hidden,.bm-marker.grouped{opacity:0;pointer-events:none}
.bm-marker.gone{display:none}
.bm-marker:hover,.bm-marker:focus-visible{z-index:2}
.bm-label{transition:opacity .2s}
.bm-marker.crowded .bm-label{opacity:0}
.bm-marker.crowded:hover .bm-label,.bm-marker.crowded:focus-visible .bm-label{opacity:1}
.bm-count{position:absolute;top:-4px;left:calc(50% + 9px);min-width:22px;height:22px;padding:0 5px;display:grid;place-items:center;border:1.5px solid var(--bm-ink);border-radius:11px;background:var(--bm-flag);color:var(--bm-ink);font-size:12px;font-weight:800;line-height:1}
.bm-castle{width:46px;height:50px;overflow:visible;transform-origin:50% 88%;transition:transform .3s cubic-bezier(.3,1.7,.5,1);animation:bm-pop .55s cubic-bezier(.3,1.7,.5,1) backwards;animation-delay:inherit}
.bm-marker:hover .bm-castle,.bm-marker:focus-visible .bm-castle{transform:translateY(-3px) scale(1.12)}
.bm-marker.active .bm-castle{transform:scale(1.25)}
.bm-marker:focus-visible{outline:none}
.bm-marker:focus-visible .bm-label{outline:2px solid var(--bm-flag);outline-offset:2px}
.bm-shadow{fill:var(--bm-ink);opacity:.2}
.bm-outline{fill:var(--bm-ink);stroke:var(--bm-ink);stroke-width:3.4;stroke-linejoin:round}
.bm-sand{fill:var(--bm-sand)}
.bm-detail{fill:none;stroke:var(--bm-sand-dark);stroke-width:1.4;stroke-linecap:round}
.bm-door{fill:var(--bm-ink)}
.bm-pole{stroke:var(--bm-ink);stroke-width:1.8;stroke-linecap:round}
.bm-flag{fill:var(--bm-flag);stroke:var(--bm-ink);stroke-width:1.3;stroke-linejoin:round;transform-box:fill-box;transform-origin:0 50%}
.bm-marker.active .bm-flag,.bm-marker:hover .bm-flag{animation:bm-wave .7s ease-in-out infinite alternate}
.bm-label{margin-top:2px;padding:1px 9px;border:1.5px solid var(--bm-ink);border-radius:20px;background:var(--bm-card);box-shadow:0 2px 0 var(--bm-ink);font-size:11px;font-weight:700;line-height:1.5;white-space:nowrap}
.bm-controls{position:absolute;z-index:3;top:14px;right:14px;display:flex;flex-direction:column;gap:7px}
.bm-controls button{width:36px;height:36px;display:grid;place-items:center;padding:0;border:1.5px solid var(--bm-ink);border-radius:50%;background:var(--bm-card);box-shadow:0 2px 0 var(--bm-ink);color:var(--bm-ink);font:700 18px/1 Arial,sans-serif;cursor:pointer}
.bm-controls button:active{transform:translateY(2px);box-shadow:none}
.beach-map.touched .bm-hint{opacity:0}
.bm-hint{position:absolute;z-index:2;transition:opacity .4s;left:14px;bottom:12px;max-width:calc(100% - 28px);padding:4px 11px;border-radius:20px;background:var(--bm-card);font-size:11px;letter-spacing:.03em;opacity:.85;pointer-events:none}
.bm-pop{position:absolute;z-index:4;left:0;top:0;width:248px;padding:15px 17px;border:1.5px solid var(--bm-ink);border-radius:var(--bm-pop-radius,14px);background:var(--bm-card);box-shadow:0 4px 0 var(--bm-ink);cursor:auto;animation:bm-rise .25s ease-out}
.bm-pop::after{content:"";position:absolute;left:var(--ax,50%);bottom:-7.5px;width:12px;height:12px;background:var(--bm-card);border:1.5px solid var(--bm-ink);border-top:0;border-left:0;transform:translateX(-50%) rotate(45deg)}
.bm-pop.side::after{display:none}
.bm-pop.below::after{top:-7.5px;bottom:auto;transform:translateX(-50%) rotate(225deg)}
.bm-pop small{display:block;padding-right:18px;font-size:10px;letter-spacing:.14em;text-transform:uppercase;opacity:.75}
.bm-pop h3{margin:4px 0 6px;font:var(--bm-title-font,700 21px/1.15 Georgia,serif)}
.bm-pop p{margin:0 0 10px;font-size:12.5px;line-height:1.45}
.bm-meta{display:flex;justify-content:space-between;gap:8px;margin-bottom:11px;padding-top:9px;border-top:1px dashed currentColor;font-size:12px;font-weight:700}
.bm-pop a{display:block;padding:8px 12px;border-radius:30px;background:var(--bm-ink);color:var(--bm-card);font-size:12px;font-weight:700;text-align:center;text-decoration:none}
.bm-close{position:absolute;top:5px;right:7px;width:26px;height:26px;padding:0;border:0;background:none;color:inherit;font-size:19px;line-height:1;cursor:pointer}
@keyframes bm-pop{from{transform:translateY(10px) scale(.2);opacity:0}}
@keyframes bm-rise{from{opacity:0;margin-top:6px}}
@keyframes bm-wave{to{transform:scaleX(.72) skewY(9deg)}}
@media(prefers-reduced-motion:reduce){.bm-castle,.bm-pop,.bm-marker.active .bm-flag,.bm-marker:hover .bm-flag{animation:none}.bm-castle{transition:none}}`;

  function mount(el, beaches, opts = {}) {
    if (!document.getElementById('bm-style')) {
      const style = document.createElement('style');
      style.id = 'bm-style';
      style.textContent = CSS;
      document.head.append(style);
    }
    const coarse = matchMedia('(pointer: coarse)').matches;
    el.classList.add('beach-map');
    el.setAttribute('role', 'region');
    el.setAttribute('aria-label', 'Interactive world map of beaches');
    const gid = 'bm-world-' + (++uid), wheelAlways = opts.wheel === 'always';
    // One world plus a copy either side, so panning east or west never reaches an edge.
    el.innerHTML = `<svg class="bm-svg" aria-hidden="true"><g id="${gid}"><g class="bm-waves">${GRID}${WAVES}</g><path class="bm-shore" d="${window.WORLD_LAND}"/><path class="bm-land" d="${window.WORLD_LAND}"/>${DETAIL}</g><use href="#${gid}" x="${-W}"/><use href="#${gid}" x="${W}"/></svg><div class="bm-markers"></div><div class="bm-controls"><button type="button" data-zoom="in" aria-label="Zoom in">+</button><button type="button" data-zoom="out" aria-label="Zoom out">−</button><button type="button" data-zoom="reset" aria-label="Back to all beaches">⟲</button></div><div class="bm-hint">${coarse ? 'Drag to explore · pinch to zoom · tap a castle' : `Drag to explore · ${wheelAlways ? '' : '⌘/Ctrl + '}scroll to zoom · click a castle`}</div>`;
    const svg = el.querySelector('svg'), layer = el.querySelector('.bm-markers');
    const items = beaches.map((b, i) => {
      const [x, y] = project(b.lat, b.lon);
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'bm-marker';
      btn.setAttribute('aria-label', `${b.name} — open details`);
      btn.style.animationDelay = (250 + i * 140) + 'ms';
      btn.innerHTML = CASTLE + `<span class="bm-label">${esc(b.name)}</span>`;
      layer.append(btn);
      return {b, x, y, btn, label: btn.querySelector('.bm-label'), hidden: false};
    });

    const ac = new AbortController(), on = {signal: ac.signal};
    let view, home, selected = null, pop = null, anim = 0, dragged = false;
    const size = () => [el.clientWidth || 1, el.clientHeight || 1];
    const box = (v = view) => { const [cw, ch] = size(), w = W / v.k; return {x: v.x - w / 2, y: v.y - w * ch / cw / 2, w, h: w * ch / cw, cw, ch}; };
    // East–west wraps around (x stays within one world width); north–south stops a little past the poles.
    function clamp(v) {
      const [cw, ch] = size(), k = Math.min(MAX_K, Math.max(1, v.k)), h = W / k * ch / cw;
      const slack = h * Math.min(.5, .3 + (k - 1) * .15);
      return {
        k,
        x: ((v.x % W) + W) % W,
        y: Math.min(TOP + H - h / 2 + slack, Math.max(TOP + h / 2 - slack, v.y)),
      };
    }
    // Space covered by overlays (in px from each edge) that castles and cards should stay clear of.
    function pad() {
      const p = opts.padding ? opts.padding() : {}, [cw, ch] = size();
      const out = {top: p.top || 0, right: p.right || 0, bottom: p.bottom || 0, left: p.left || 0};
      // Never let overlays squeeze the free area below a usable size.
      if (cw - out.left - out.right < 200) out.left = out.right = 0;
      if (ch - out.top - out.bottom < 160) out.top = out.bottom = 0;
      return out;
    }
    // The view that puts map point (mx, my) at the centre of the free area, nudged down by dy px.
    function centerOn(mx, my, k, dy = 0) {
      const [cw, ch] = size(), p = pad(), w = W / k, h = w * ch / cw;
      const ux = p.left + (cw - p.left - p.right) / 2, uy = p.top + (ch - p.top - p.bottom) / 2 + dy;
      return {x: mx - (ux - cw / 2) / cw * w, y: my - (uy - ch / 2) / ch * h, k};
    }
    // Zoom to fit a set of castles inside the free area, leaving room in px for castles and name tags.
    function fit(list) {
      if (!list.length) list = items;
      const [cw, ch] = size(), p = pad();
      const fw = Math.max(80, cw - p.left - p.right - 160), fh = Math.max(80, ch - p.top - p.bottom - 130);
      const xs = list.map(i => i.x), ys = list.map(i => i.y);
      const x0 = Math.min(...xs), x1 = Math.max(...xs), y0 = Math.min(...ys), y1 = Math.max(...ys);
      const kx = W * fw / cw / Math.max(x1 - x0, 1e-9), ky = W * fh / cw / Math.max(y1 - y0, 1e-9);
      // A single castle gets a neighbourhood view rather than the deepest zoom.
      const k = Math.max(1, Math.min(list.length > 1 ? MAX_K : 900, kx, ky));
      return clamp(centerOn((x0 + x1) / 2, (y0 + y1) / 2, k, 12));
    }

    function render() {
      const v = box(), mid = v.x + v.w / 2;
      svg.setAttribute('viewBox', `${v.x} ${v.y} ${v.w} ${v.h}`);
      // Castles that would overlap on screen merge into one cluster castle with a count.
      const groups = [];
      for (const it of items) {
        // Use whichever copy of the castle sits closest to the middle of the view.
        it.sx = (it.x + Math.round((mid - it.x) / W) * W - v.x) / v.w * v.cw;
        it.sy = (it.y - v.y) / v.h * v.ch;
        place(it.btn, it.label, it.sx, it.sy, v.cw);
        if (it.hidden) continue;
        const g = groups.find(g => Math.abs(g.sx - it.sx) < 44 && Math.abs(g.sy - it.sy) < 40);
        if (g) g.members.push(it); else groups.push({sx: it.sx, sy: it.sy, members: [it]});
      }
      let n = 0;
      for (const g of groups) {
        const many = g.members.length > 1;
        for (const it of g.members) it.btn.classList.toggle('grouped', many);
        if (!many) continue;
        const c = clusters[n++] || makeCluster();
        c.members = g.members;
        c.btn.classList.remove('gone');
        c.count.textContent = g.members.length;
        c.label.textContent = `${g.members.length} beaches`;
        c.btn.setAttribute('aria-label', `${g.members.length} beaches: ${g.members.map(m => m.b.name).join(', ')} — zoom in`);
        const sx = g.members.reduce((a, m) => a + m.sx, 0) / g.members.length, sy = g.members.reduce((a, m) => a + m.sy, 0) / g.members.length;
        c.sx = sx; c.sy = sy;
        place(c.btn, c.label, sx, sy, v.cw);
      }
      for (; n < clusters.length; n++) clusters[n].btn.classList.add('gone');
      declutter(groups.map(g => g.members.length > 1 ? clusters.find(c => c.members === g.members) : g.members[0]));
      placePop();
    }
    // Hide a name tag (until hover/focus) when it would sit on top of another castle or tag.
    function declutter(marks) {
      const boxes = marks.map(m => ({m, x0: m.sx - 23, x1: m.sx + 23, y0: m.sy - 44, y1: m.sy}));
      const hit = (a, b) => a.x0 < b.x1 && b.x0 < a.x1 && a.y0 < b.y1 && b.y0 < a.y1;
      const placed = [];
      for (const {m} of boxes) {
        const half = m.label.offsetWidth / 2 + 3;
        const tag = {x0: m.sx - half, x1: m.sx + half, y0: m.sy + 2, y1: m.sy + 26};
        const clash = boxes.some(b => b.m !== m && hit(tag, b)) || placed.some(t => hit(tag, t));
        m.btn.classList.toggle('crowded', clash);
        if (!clash) placed.push(tag);
      }
    }
    function place(btn, label, sx, sy, cw) {
      btn.style.transform = `translate(${sx}px,${sy}px) translate(-50%,-44px)`;
      // Keep name tags inside the frame when a castle sits near the edge.
      const half = label.offsetWidth / 2, over = sx + half - (cw - 6), under = 6 - (sx - half);
      const onScreen = sx > 0 && sx < cw;
      label.style.transform = onScreen && over > 0 ? `translateX(${-over}px)` : onScreen && under > 0 ? `translateX(${under}px)` : '';
    }
    const clusters = [];
    function makeCluster() {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'bm-marker bm-cluster';
      btn.innerHTML = CASTLE + '<span class="bm-count"></span><span class="bm-label"></span>';
      layer.append(btn);
      const c = {btn, count: btn.querySelector('.bm-count'), label: btn.querySelector('.bm-label'), members: []};
      // Zoom in just far enough for the grouped castles to stand apart.
      btn.addEventListener('click', () => {
        if (dragged) return;
        el.classList.add('touched');
        const m = c.members, sep = Math.max(...m.flatMap(a => m.map(b => Math.hypot(a.sx - b.sx, a.sy - b.sy))));
        const x = m.reduce((s, i) => s + i.x, 0) / m.length, y = m.reduce((s, i) => s + i.y, 0) / m.length;
        flyTo(centerOn(x, y, view.k * Math.min(8, Math.max(1.6, 150 / Math.max(sep, 1))), 12), 800);
      }, on);
      clusters.push(c);
      return c;
    }
    function placePop() {
      if (!pop || !selected) return;
      const v = box(), pw = pop.offsetWidth, ph = pop.offsetHeight, {sx, sy} = selected;
      const p = pad(), t = p.top + 8, b = v.ch - p.bottom - 8, l = p.left + 8, r = v.cw - p.right - 8;
      const above = sy - 62 - ph >= t, below = !above && sy + 34 + ph <= b;
      let left = Math.min(r - pw, Math.max(l, sx - pw / 2)), top = above ? sy - 62 - ph : sy + 34;
      const right = sx + 34 + pw <= r, leftSide = sx - 34 - pw >= l;
      const side = !above && !below && (right || leftSide);
      if (side) {
        // Not enough room vertically: sit beside the castle instead.
        left = right ? sx + 34 : sx - 34 - pw;
        top = Math.min(b - ph, Math.max(t, sy - 20 - ph / 2));
      } else if (!above && !below) top = Math.max(t, sy - 62 - ph);
      pop.classList.toggle('below', below);
      pop.classList.toggle('side', side);
      pop.style.transform = `translate(${left}px,${top}px)`;
      pop.style.setProperty('--ax', Math.min(pw - 16, Math.max(16, selected.sx - left)) + 'px');
    }

    function flyTo(target, ms = 650) {
      const from = {...view}, to = clamp(target);
      to.x += Math.round((from.x - to.x) / W) * W; // take the short way round
      cancelAnimationFrame(anim);
      if (reduced()) { view = to; return render(); }
      const t0 = performance.now();
      const step = now => {
        const t = Math.min(1, (now - t0) / ms), e = t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
        view = {x: from.x + (to.x - from.x) * e, y: from.y + (to.y - from.y) * e, k: from.k * Math.pow(to.k / from.k, e)};
        render();
        if (t < 1) anim = requestAnimationFrame(step);
      };
      anim = requestAnimationFrame(step);
    }
    function zoomAt(factor, px, py) {
      const v = box(), mx = v.x + px / v.cw * v.w, my = v.y + py / v.ch * v.h;
      const k = Math.min(MAX_K, Math.max(1, view.k * factor)), w = W / k, h = w * v.ch / v.cw;
      view = clamp({x: mx - (px / v.cw - .5) * w, y: my - (py / v.ch - .5) * h, k});
      render();
    }

    function close() {
      if (pop) pop.remove();
      pop = null;
      if (selected) selected.btn.classList.remove('active');
      selected = null;
    }
    function select(it) {
      // With onSelect, a castle hands off to the page (e.g. to open the beach) instead of showing a card.
      if (opts.onSelect) { close(); it.btn.classList.add('active'); return opts.onSelect(it.b); }
      if (selected === it) return close();
      close();
      selected = it;
      el.classList.add('touched');
      it.btn.classList.add('active');
      const d = (opts.describe || (b => ({title: b.name})))(it.b);
      pop = document.createElement('div');
      pop.className = 'bm-pop';
      pop.setAttribute('role', 'dialog');
      pop.setAttribute('aria-label', d.title);
      pop.innerHTML = `<button type="button" class="bm-close" aria-label="Close">×</button>${d.place ? `<small>${esc(d.place)}</small>` : ''}<h3>${esc(d.title)}</h3>${d.text ? `<p>${esc(d.text)}</p>` : ''}${d.meta ? `<div class="bm-meta">${d.meta.map(m => `<span>${esc(m)}</span>`).join('')}</div>` : ''}${d.href ? `<a href="${esc(d.href)}">${esc(d.cta || 'Open beach guide ↗')}</a>` : ''}`;
      pop.querySelector('.bm-close').onclick = () => { close(); it.btn.focus(); };
      el.append(pop);
      // Centre the castle and its card together in the frame.
      const k = Math.max(view.k, 2.6);
      flyTo(centerOn(it.x, it.y, k, Math.max(0, (pop.offsetHeight + 62) / 2 - 25)));
      render();
    }

    for (const it of items) it.btn.addEventListener('click', () => { if (!dragged) select(it); }, on);
    el.addEventListener('click', e => { if (!dragged && !e.target.closest('.bm-marker,.bm-pop,.bm-controls')) close(); }, on);
    el.querySelector('.bm-controls').addEventListener('click', e => {
      const z = e.target.closest('button')?.dataset.zoom;
      if (z === 'in') flyTo({...view, k: view.k * 2}, 350);
      if (z === 'out') flyTo({...view, k: view.k / 2}, 350);
      if (z === 'reset') { close(); flyTo(fit(items)); }
    }, on);
    el.addEventListener('keydown', e => { if (e.key === 'Escape' && selected) { const b = selected.btn; close(); b.focus(); } }, on);

    // Drag to pan, two fingers to pinch, ⌘/Ctrl + wheel (or trackpad pinch) to zoom.
    const pts = new Map();
    let active = false;
    el.addEventListener('pointerdown', e => {
      if (e.target.closest('.bm-controls,.bm-pop') || e.button > 0) return;
      cancelAnimationFrame(anim);
      dragged = false;
      active = true;
      el.classList.add('touched');
      pts.set(e.pointerId, {x: e.clientX, y: e.clientY, sx: e.clientX, sy: e.clientY});
    }, on);
    el.addEventListener('pointerleave', () => { active = false; }, on);
    window.addEventListener('pointermove', e => {
      const p = pts.get(e.pointerId);
      if (!p) return;
      if (!el.isConnected) return teardown();
      const v = box(), r = el.getBoundingClientRect();
      if (pts.size === 1) {
        if (!dragged && Math.hypot(e.clientX - p.sx, e.clientY - p.sy) < 5) return;
        dragged = true;
        el.classList.add('dragging');
        view = clamp({...view, x: view.x - (e.clientX - p.x) / v.cw * v.w, y: view.y - (e.clientY - p.y) / v.ch * v.h});
        p.x = e.clientX; p.y = e.clientY;
        render();
      } else if (pts.size === 2) {
        dragged = true;
        const [a, b] = [...pts.values()];
        const before = Math.hypot(a.x - b.x, a.y - b.y);
        p.x = e.clientX; p.y = e.clientY;
        const after = Math.hypot(a.x - b.x, a.y - b.y);
        if (before > 0) zoomAt(after / before, (a.x + b.x) / 2 - r.left, (a.y + b.y) / 2 - r.top);
      }
    }, on);
    const up = e => {
      if (!pts.delete(e.pointerId)) return;
      el.classList.remove('dragging');
      // Let the click that follows this pointerup see `dragged`, then reset it.
      if (dragged) setTimeout(() => { dragged = false; }, 0);
    };
    window.addEventListener('pointerup', up, on);
    window.addEventListener('pointercancel', up, on);
    el.addEventListener('wheel', e => {
      if (!(wheelAlways || e.ctrlKey || e.metaKey || active)) return;
      e.preventDefault();
      const r = el.getBoundingClientRect();
      cancelAnimationFrame(anim);
      zoomAt(Math.exp(-e.deltaY * (e.ctrlKey ? .01 : .0025)), e.clientX - r.left, e.clientY - r.top);
    }, {passive: false, signal: ac.signal});

    const ro = new ResizeObserver(() => {
      if (!el.isConnected) return teardown();
      home = fit(items);
      view = view ? clamp(view) : home;
      render();
    });
    function teardown() { ac.abort(); ro.disconnect(); cancelAnimationFrame(anim); }
    home = fit(items);
    view = home;
    render();
    ro.observe(el);

    return {
      filter(pred) {
        const shown = [];
        for (const it of items) {
          it.hidden = !pred(it.b);
          it.btn.classList.toggle('hidden', it.hidden);
          it.btn.tabIndex = it.hidden ? -1 : 0;
          if (!it.hidden) shown.push(it);
        }
        if (selected && selected.hidden) close();
        flyTo(shown.length === items.length ? home : fit(shown));
      },
      select(name) { const it = items.find(i => i.b.name === name); if (it) select(it); },
    };
  }

  window.BeachMap = {mount};
})();
