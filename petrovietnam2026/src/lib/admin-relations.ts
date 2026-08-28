const relations = {
  sport_id: "sports", tournament_id: "tournaments", organization_id: "organizations",
  participant_id: "participants", entry_id: "entries", venue_id: "venues", court_id: "courts",
  group_id: "groups", fixture_id: "fixtures", next_fixture_id: "fixtures", winner_entry_id: "entries",
} as const;

export function relationEntity(field: string) {
  return relations[field as keyof typeof relations] ?? null;
}
