-- Keep the public participant grant column-scoped: count the granted NOT NULL id column.
do $fix$
declare
  v_definition text;
  v_patched text;
begin
  select pg_get_functiondef('public.get_public_page(text, text)'::regprocedure)
  into v_definition;
  if v_definition is null then
    raise exception 'public.get_public_page(text, text) không tồn tại';
  end if;

  v_patched := replace(v_definition, 'count(*) from participants', 'count(id) from participants');
  if v_patched = v_definition then
    raise exception 'Không tìm thấy phép đếm participants cần sửa';
  end if;

  execute v_patched;
end
$fix$;
