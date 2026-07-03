export function newUuid(): string {
  return crypto.randomUUID()
}

export function orderRefShort(id: string): string {
  return id.length >= 4 ? id.slice(-4) : id
}

export function optionsLabel(options: { group_name: string; choice_name: string }[]): string {
  if (!options.length) return ''
  return options.map((o) => o.choice_name).join(' · ')
}
