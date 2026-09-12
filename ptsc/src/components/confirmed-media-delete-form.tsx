"use client";

import { useState } from "react";
import type { FormEvent } from "react";
import { Trash2 } from "lucide-react";
import { setMediaSelection } from "@/lib/admin-media";

type DeleteAction = (formData: FormData) => void | Promise<void>;

export function ConfirmedMediaDeleteForm({ action }: { action: DeleteAction }) {
  const [allSelected, setAllSelected] = useState(false);

  function confirmDelete(event: FormEvent<HTMLFormElement>) {
    const form = event.currentTarget;
    const submitter = (event.nativeEvent as SubmitEvent).submitter;
    const single = submitter instanceof HTMLButtonElement && submitter.name === "single_id";
    const selected = new FormData(form).getAll("id").filter((value) => String(value).trim());
    if (!single && !selected.length) {
      event.preventDefault();
      window.alert("Hãy chọn ít nhất một ảnh.");
      return;
    }
    const message = single ? "Xoá vĩnh viễn ảnh này? Thao tác không thể hoàn tác." : `Xoá vĩnh viễn ${selected.length} ảnh đã chọn? Thao tác không thể hoàn tác.`;
    if (!window.confirm(message)) event.preventDefault();
  }

  function toggleAll(checked: boolean) {
    setMediaSelection(document.querySelectorAll<HTMLInputElement>(".media-select[form='media-delete']"), checked);
    setAllSelected(checked);
  }

  return <form id="media-delete" action={action} className="media-delete-toolbar" onSubmit={confirmDelete}>
    <label className="media-select-all"><input type="checkbox" checked={allSelected} onChange={(event) => toggleAll(event.target.checked)}/>{allSelected ? "Bỏ chọn tất cả" : "Chọn tất cả"}</label>
    <button className="delete-button" type="submit"><Trash2 size={15}/>Xoá ảnh đã chọn</button>
  </form>;
}
