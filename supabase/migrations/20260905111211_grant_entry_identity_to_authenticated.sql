-- Duplicate checks run in invoker context from admin inserts/updates.
grant execute on function private.entry_identity(text, text) to authenticated;
