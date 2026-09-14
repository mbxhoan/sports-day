"use client";

import { useActionState, useState, type ReactNode } from "react";
import { Archive, Check, ClipboardList, Pencil, Plus, Search, Trash2, UserPlus, Users } from "lucide-react";
import { initialAdminActionState, type AdminActionState } from "@/lib/admin-action";
import { SearchableSelect } from "./searchable-select";

type Row = Record<string, unknown> & { id: string; archived_at: string | null };
type FormAction = (formData: FormData) => Promise<void>;
type RosterAction = (previousState: AdminActionState, formData: FormData) => Promise<AdminActionState>;

function RosterActionForm({ action, sportSlug, children, className, submitLabel, pendingLabel }: { action: RosterAction; sportSlug: string; children: ReactNode; className?: string; submitLabel: string; pendingLabel: string }) {
  const [state, formAction, pending] = useActionState(action, initialAdminActionState);
  return <form action={formAction} className={className}><input type="hidden" name="sport_slug" value={sportSlug}/>{children}{state.message && <p className={state.ok ? "form-success" : "form-error"} role={state.ok ? "status" : "alert"}>{state.message}</p>}<button className="gold-button" disabled={pending}>{pending ? pendingLabel : submitLabel}</button></form>;
}

function text(row: Row, key: string) {
  return String(row[key] ?? "").trim();
}

function name(row: Row) {
  return text(row, "name_vi") || text(row, "full_name") || text(row, "code") || "Chưa đặt tên";
}

function organizationName(row: Row, organizations: Row[]) {
  const organization = organizations.find((item) => item.id === text(row, "organization_id"));
  return organization ? name(organization) : "Chưa chọn đơn vị";
}

function kindLabel(row: Row) {
  return text(row, "kind") === "pair" ? "Cặp" : text(row, "kind") === "team" ? "Đội" : "Cá nhân";
}

export function AdminRosterWorkspace({
  entries,
  participants,
  organizations,
  tournaments,
  members,
  sportSlug,
  saveRosterRecord,
  setArchived,
}: {
  entries: Row[];
  participants: Row[];
  organizations: Row[];
  tournaments: Row[];
  members: Row[];
  sportSlug: string;
  saveRosterRecord: RosterAction;
  setArchived: FormAction;
}) {
  const activeEntries = entries.filter((row) => !row.archived_at);
  const activeParticipants = participants.filter((row) => !row.archived_at);
  const activeMembers = members.filter((row) => !row.archived_at);
  const activeOrganizations = organizations.filter((row) => !row.archived_at);
  const [mode, setMode] = useState<"entries" | "participants">("entries");
  const [query, setQuery] = useState("");
  const [selectedEntryId, setSelectedEntryId] = useState(activeEntries[0]?.id ?? "");
  const [selectedParticipantId, setSelectedParticipantId] = useState(activeParticipants[0]?.id ?? "");
  const [memberQuery, setMemberQuery] = useState("");

  const selectedEntry = activeEntries.find((row) => row.id === selectedEntryId) ?? activeEntries[0];
  const selectedParticipant = activeParticipants.find((row) => row.id === selectedParticipantId) ?? activeParticipants[0];
  const entryMembers = activeMembers.filter((row) => text(row, "entry_id") === selectedEntry?.id);
  const memberIds = new Set(entryMembers.map((row) => text(row, "participant_id")));
  const filteredEntries = activeEntries.filter((row) => `${name(row)} ${organizationName(row, organizations)}`.toLowerCase().includes(query.toLowerCase()));
  const filteredParticipants = activeParticipants.filter((row) => `${name(row)} ${organizationName(row, organizations)}`.toLowerCase().includes(query.toLowerCase()));
  const availableParticipants = activeParticipants.filter((row) => !memberIds.has(row.id) && `${name(row)} ${organizationName(row, organizations)}`.toLowerCase().includes(memberQuery.toLowerCase()));
  const visibleRows = mode === "entries" ? filteredEntries : filteredParticipants;

  return <div className="roster-workspace">
    <div className="roster-overview">
      <div>
        <span className="admin-kicker">QUẢN LÝ THAM GIA</span>
        <h2>Đội & vận động viên</h2>
        <p>Chọn một bản ghi bên trái để sửa. Gán VĐV nằm ngay trong hồ sơ đội/cặp.</p>
      </div>
      <div className="roster-stats" aria-label="Tổng số dữ liệu"><span><b>{activeEntries.length}</b>Đội / cặp</span><span><b>{activeParticipants.length}</b>VĐV</span><span><b>{activeMembers.length}</b>Lượt gán</span></div>
    </div>

    <div className="roster-mode-tabs" role="tablist" aria-label="Loại dữ liệu">
      <button type="button" role="tab" aria-selected={mode === "entries"} className={mode === "entries" ? "active" : ""} onClick={() => { setMode("entries"); setQuery(""); }}><Users size={16}/>Đội & cặp <em>{activeEntries.length}</em></button>
      <button type="button" role="tab" aria-selected={mode === "participants"} className={mode === "participants" ? "active" : ""} onClick={() => { setMode("participants"); setQuery(""); }}><ClipboardList size={16}/>Vận động viên <em>{activeParticipants.length}</em></button>
    </div>

    {mode === "entries" ? <details className="roster-create-card" open>
      <summary><Plus size={16}/><span><b>Tạo đội / cặp mới</b><small>Thêm đội thi vào hạng mục đang quản lý</small></span></summary>
      <RosterActionForm action={saveRosterRecord} sportSlug={sportSlug} submitLabel="Tạo đội / cặp" pendingLabel="Đang tạo..."><input type="hidden" name="entity" value="entries"/><div className="roster-form-grid"><label><span>Hạng mục</span><SearchableSelect name="tournament_id" options={tournaments.filter((row) => !row.archived_at).map((row) => ({ value: row.id, label: name(row) }))} placeholder="Chọn hạng mục" required/></label><label><span>Loại</span><SearchableSelect name="kind" value="team" options={[{ value: "individual", label: "Cá nhân" }, { value: "pair", label: "Cặp" }, { value: "team", label: "Đội" }]} placeholder="Chọn loại"/></label><label className="field-span-2"><span>Tên hiển thị</span><input name="name_vi" placeholder="Ví dụ: Đội 1" required/></label><label><span>Tên tiếng Anh</span><input name="name_en"/></label><label><span>Đơn vị</span><SearchableSelect name="organization_id" options={activeOrganizations.map((row) => ({ value: row.id, label: name(row) }))} placeholder="Chưa chọn đơn vị"/></label><label><span>Seed / Số áo</span><input name="seed_number" type="number" min="1"/></label></div></RosterActionForm>
    </details> : <details className="roster-create-card" open>
      <summary><UserPlus size={16}/><span><b>Thêm vận động viên</b><small>Tạo VĐV dùng chung cho các đội/cặp</small></span></summary>
      <RosterActionForm action={saveRosterRecord} sportSlug={sportSlug} submitLabel="Tạo VĐV" pendingLabel="Đang tạo VĐV..."><input type="hidden" name="entity" value="participants"/><div className="roster-form-grid"><label className="field-span-2"><span>Họ và tên</span><input name="full_name" placeholder="Nhập họ và tên" required/></label><label><span>Tên tiếng Anh</span><input name="full_name_en"/></label><label><span>Đơn vị</span><SearchableSelect name="organization_id" options={activeOrganizations.map((row) => ({ value: row.id, label: name(row) }))} placeholder="Chưa chọn đơn vị"/></label><label><span>Giới tính</span><SearchableSelect name="gender" options={[{ value: "male", label: "Nam" }, { value: "female", label: "Nữ" }, { value: "other", label: "Khác" }]} placeholder="Chưa cập nhật"/></label><label><span>Ngày sinh</span><input name="birth_date" type="date"/></label></div></RosterActionForm>
    </details>}

    <div className="roster-grid">
      <aside className="roster-list-panel">
        <div className="roster-list-head"><div><div className="roster-panel-title">{mode === "entries" ? "Danh sách đội / cặp" : "Danh sách VĐV"}</div><small>{visibleRows.length} kết quả</small></div><label className="roster-search"><Search size={16}/><span className="visually-hidden">Tìm kiếm</span><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder={mode === "entries" ? "Tìm đội hoặc đơn vị..." : "Tìm tên VĐV..."}/></label></div>
        <div className="roster-list">{mode === "entries" ? filteredEntries.map((row) => <button type="button" role="tab" aria-selected={row.id === selectedEntry?.id} className={`roster-list-item ${row.id === selectedEntry?.id ? "active" : ""}`} key={row.id} onClick={() => setSelectedEntryId(row.id)}><span><b>{name(row)}</b><small>{organizationName(row, organizations)} · {kindLabel(row)}</small></span><em>{activeMembers.filter((member) => text(member, "entry_id") === row.id).length} VĐV</em></button>) : filteredParticipants.map((row) => <button type="button" role="tab" aria-selected={row.id === selectedParticipant?.id} className={`roster-list-item ${row.id === selectedParticipant?.id ? "active" : ""}`} key={row.id} onClick={() => setSelectedParticipantId(row.id)}><span><b>{name(row)}</b><small>{organizationName(row, organizations)} · {text(row, "gender") || "Chưa cập nhật"}</small></span><em>{activeMembers.filter((member) => text(member, "participant_id") === row.id).length} đội</em></button>)}{!visibleRows.length && <p className="roster-empty">Không tìm thấy dữ liệu phù hợp.</p>}</div>
      </aside>

      <section className="roster-detail-panel">
        {mode === "entries" && selectedEntry ? <>
          <div className="roster-detail-head"><div><span className="admin-kicker">HỒ SƠ ĐỘI / CẶP</span><h3>{name(selectedEntry)}</h3><p>{organizationName(selectedEntry, organizations)} · {entryMembers.length} VĐV đã gán</p></div><span className="status-pill"><Check size={14}/>Đang hoạt động</span></div>
          <details className="roster-edit-card" key={selectedEntry.id} open><summary><Pencil size={15}/><span><b>Sửa thông tin đội / cặp</b><small>Cập nhật tên, hạng mục và đơn vị</small></span></summary><RosterActionForm action={saveRosterRecord} sportSlug={sportSlug} submitLabel="Lưu thay đổi" pendingLabel="Đang lưu..."><input type="hidden" name="entity" value="entries"/><input type="hidden" name="id" value={selectedEntry.id}/><div className="roster-form-grid"><label><span>Hạng mục</span><SearchableSelect name="tournament_id" value={text(selectedEntry, "tournament_id")} options={tournaments.filter((row) => !row.archived_at).map((row) => ({ value: row.id, label: name(row) }))} placeholder="Chọn hạng mục"/></label><label><span>Loại</span><SearchableSelect name="kind" value={text(selectedEntry, "kind")} options={[{ value: "individual", label: "Cá nhân" }, { value: "pair", label: "Cặp" }, { value: "team", label: "Đội" }]} placeholder="Chọn loại"/></label><label className="field-span-2"><span>Tên hiển thị</span><input name="name_vi" defaultValue={text(selectedEntry, "name_vi")} required/></label><label><span>Tên tiếng Anh</span><input name="name_en" defaultValue={text(selectedEntry, "name_en")}/></label><label><span>Đơn vị</span><SearchableSelect name="organization_id" value={text(selectedEntry, "organization_id")} options={activeOrganizations.map((row) => ({ value: row.id, label: name(row) }))} placeholder="Chưa chọn đơn vị"/></label><label><span>Seed / Số áo</span><input name="seed_number" type="number" min="1" defaultValue={text(selectedEntry, "seed_number")}/></label></div></RosterActionForm></details>
      <div className="roster-members-card"><div className="roster-card-head"><div><span className="roster-card-label">DANH SÁCH THÀNH VIÊN</span><h4>Gán VĐV vào đội / cặp</h4><p>Chỉ chọn VĐV có sẵn, không tạo bản ghi trùng.</p></div><strong>{entryMembers.length}</strong></div><RosterActionForm action={saveRosterRecord} sportSlug={sportSlug} className="assign-member-form" submitLabel="Gán vào đội" pendingLabel="Đang gán..."><input type="hidden" name="entity" value="entry_members"/><input type="hidden" name="entry_id" value={selectedEntry.id}/><label><span>Lọc danh sách VĐV</span><input value={memberQuery} onChange={(event) => setMemberQuery(event.target.value)} placeholder="Nhập tên hoặc đơn vị..."/></label><label><span>Chọn VĐV</span><SearchableSelect name="participant_id" options={availableParticipants.map((row) => ({ value: row.id, label: `${name(row)} · ${organizationName(row, organizations)}` }))} placeholder="Chọn VĐV" required/></label><label><span>Vai trò</span><SearchableSelect name="role_vi" value="Vận động viên" options={[{ value: "Vận động viên", label: "Vận động viên" }, { value: "Dự bị", label: "Dự bị" }]} placeholder="Chọn vai trò"/></label></RosterActionForm><div className="member-list">{entryMembers.map((member) => { const participant = activeParticipants.find((row) => row.id === text(member, "participant_id")); const reserve = /dự bị|reserve/i.test(`${text(member, "role_vi")} ${text(member, "role_en")}`); return <div className="member-row" key={member.id}><span><b>{participant ? name(participant) : "VĐV không còn hoạt động"}</b><small>{participant ? organizationName(participant, organizations) : ""} · {reserve ? <><span className="reserve-badge">Dự bị</span></> : "Vận động viên"}</small></span><form action={setArchived}><input type="hidden" name="entity" value="entry_members"/><input type="hidden" name="id" value={member.id}/><input type="hidden" name="archived" value="true"/><button className="icon-button danger" aria-label={`Bỏ ${participant ? name(participant) : "VĐV"} khỏi đội`} title="Bỏ khỏi đội"><Trash2 size={16}/></button></form></div>; })}{!entryMembers.length && <p className="roster-empty">Đội/cặp này chưa có VĐV. Dùng biểu mẫu phía trên để gán.</p>}</div></div>
          <form action={setArchived} className="roster-archive-form"><input type="hidden" name="entity" value="entries"/><input type="hidden" name="id" value={selectedEntry.id}/><input type="hidden" name="archived" value="true"/><button className="archive-button"><Archive size={15}/>Lưu trữ đội / cặp</button></form>
        </> : mode === "entries" ? <div className="roster-empty-state"><Users size={32}/><h3>Chưa có đội hoặc cặp</h3><p>Tạo bản ghi đầu tiên bằng biểu mẫu phía trên.</p></div> : <>
          <div className="roster-detail-head"><div><span className="admin-kicker">HỒ SƠ VẬN ĐỘNG VIÊN</span><h3>{selectedParticipant ? name(selectedParticipant) : "Chưa chọn VĐV"}</h3><p>{selectedParticipant ? organizationName(selectedParticipant, organizations) : "Chọn VĐV bên trái để xem hồ sơ."}</p></div>{selectedParticipant && <span className="status-pill"><Check size={14}/>Đang hoạt động</span>}</div>
          {selectedParticipant && <details className="roster-edit-card" key={selectedParticipant.id} open><summary><Pencil size={15}/><span><b>Sửa hồ sơ VĐV</b><small>Cập nhật thông tin dùng chung</small></span></summary><RosterActionForm action={saveRosterRecord} sportSlug={sportSlug} submitLabel="Lưu thay đổi" pendingLabel="Đang lưu..."><input type="hidden" name="entity" value="participants"/><input type="hidden" name="id" value={selectedParticipant.id}/><div className="roster-form-grid"><label className="field-span-2"><span>Họ và tên</span><input name="full_name" defaultValue={text(selectedParticipant, "full_name")} required/></label><label><span>Tên tiếng Anh</span><input name="full_name_en" defaultValue={text(selectedParticipant, "full_name_en")}/></label><label><span>Đơn vị</span><SearchableSelect name="organization_id" value={text(selectedParticipant, "organization_id")} options={activeOrganizations.map((row) => ({ value: row.id, label: name(row) }))} placeholder="Chưa chọn đơn vị"/></label><label><span>Giới tính</span><SearchableSelect name="gender" value={text(selectedParticipant, "gender")} options={[{ value: "male", label: "Nam" }, { value: "female", label: "Nữ" }, { value: "other", label: "Khác" }]} placeholder="Chưa cập nhật"/></label><label><span>Ngày sinh</span><input name="birth_date" type="date" defaultValue={text(selectedParticipant, "birth_date")}/></label></div></RosterActionForm></details>}
          {selectedParticipant && <form action={setArchived} className="roster-archive-form"><input type="hidden" name="entity" value="participants"/><input type="hidden" name="id" value={selectedParticipant.id}/><input type="hidden" name="archived" value="true"/><button className="archive-button"><Archive size={15}/>Lưu trữ VĐV</button></form>}
          {!selectedParticipant && <div className="roster-empty-state"><ClipboardList size={32}/><h3>Chưa có VĐV</h3><p>Tạo vận động viên đầu tiên bằng biểu mẫu phía trên.</p></div>}
        </>}
      </section>
    </div>
  </div>;
}
