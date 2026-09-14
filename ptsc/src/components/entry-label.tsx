export function EntryLabel({ name, organization }: { name: string; organization?: string }) {
  return <span className="entry-display"><span className="entry-name">{name}</span>{organization && <small className="entry-organization">({organization})</small>}</span>;
}
