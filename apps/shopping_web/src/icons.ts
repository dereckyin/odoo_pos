const ICONS: Record<string, string> = {
  bowl: '<path d="M3 11h18a9 9 0 0 1-9 8 9 9 0 0 1-9-8z"/><path d="M13 3l7 4M11 4.5l7 4"/>',
  dumpling:
    '<path d="M3.5 14a8.5 4.5 0 0 1 17 0z"/><path d="M6 13c1-.9 2-.9 3 0s2 .9 3 0 2-.9 3 0 2 .9 3 0"/>',
  rice: '<path d="M4 12h16a8 8 0 0 1-16 0z"/><path d="M8 12a4 4 0 0 1 8 0"/>',
  veg: '<path d="M5 19c0-7.7 6.3-14 14-14 0 7.7-6.3 14-14 14z"/><path d="M12 12l-5 5"/>',
  soup: '<path d="M4 12h16a8 8 0 0 1-16 0z"/><path d="M9 8.5c0-1.5 1.5-1.5 1.5-3M14 8.5c0-1.5 1.5-1.5 1.5-3"/>',
  dessert: '<path d="M8 10.5l1.4 9.5h5.2L16 10.5z"/><path d="M7.5 10.5a4.5 4.5 0 0 1 9 0z"/>',
  cup: '<path d="M6.5 4h11l-1.1 15a2 2 0 0 1-2 1.9H9.6a2 2 0 0 1-2-1.9z"/><path d="M7 9.5h10"/><path d="M12 1.8v2.2"/>',
  cash: '<rect x="2.5" y="6" width="19" height="12" rx="2"/><circle cx="12" cy="12" r="2.4"/><path d="M6 9.5v5M18 9.5v5"/>',
  phone: '<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M10.5 18.6h3"/>',
  card: '<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M2.5 9.5h19"/><path d="M6 15h4"/>',
  store:
    '<path d="M4 9.8V20h16V9.8"/><path d="M3 4h18l1 4.5a2.6 2.6 0 0 1-5 0 2.6 2.6 0 0 1-5 0 2.6 2.6 0 0 1-5 0 2.6 2.6 0 0 1-5 0z"/><path d="M9.5 20v-5h5v5"/>',
  pin: '<path d="M12 21c4-4.5 7-7.8 7-11a7 7 0 0 0-14 0c0 3.2 3 6.5 7 11z"/><circle cx="12" cy="10" r="2.4"/>',
  pencil: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M14 6l4 4"/>',
  dine: '<path d="M7 2.5v6M9 2.5v6M8 8.5v13"/><path d="M14.5 2.5C13 3.6 12.4 5.5 12.4 7.2c0 1.7.8 2.9 2.1 3.4V21.5"/>',
  bag: '<path d="M6 8h12l-1 12.3a2 2 0 0 1-2 1.7H9a2 2 0 0 1-2-1.7z"/><path d="M9 8V6.5a3 3 0 0 1 6 0V8"/>',
  moped:
    '<circle cx="6" cy="16.5" r="2.4"/><circle cx="18" cy="16.5" r="2.4"/><path d="M8.4 16.5h7.2l-2-7H8.4"/><path d="M13.6 9.5h3.4l1 7"/><path d="M4.4 12.5h3.6"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  chevron: '<path d="M9 6l6 6-6 6"/>',
  back: '<path d="M15 6l-6 6 6 6"/>',
}

export function ic(name: string, size = 34): string {
  const body = ICONS[name] || ICONS.bowl
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">${body}</svg>`
}

export function ii(name: string, size = 15): string {
  const body = ICONS[name] || ''
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;flex-shrink:0">${body}</svg>`
}
