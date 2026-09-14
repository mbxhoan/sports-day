"use client";

import { Search, X } from "lucide-react";
import { useEffect, useId, useMemo, useRef, useState } from "react";
import { matchesSearch } from "@/lib/search";

export type SearchableSelectOption = { value: string; label: string };

type Props = {
  name?: string;
  id?: string;
  value?: string;
  options: readonly SearchableSelectOption[];
  placeholder: string;
  required?: boolean;
  disabled?: boolean;
  onChange?: (value: string) => void;
  "aria-label"?: string;
};

export function SearchableSelect({ name, id, value, options, placeholder, required = false, disabled = false, onChange, "aria-label": ariaLabel }: Props) {
  const listId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const lastValueRef = useRef(value);
  const [selectedValue, setSelectedValue] = useState(value ?? "");
  const [query, setQuery] = useState(() => options.find((option) => option.value === value)?.label ?? "");
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);

  const selected = options.find((option) => option.value === selectedValue);
  const visibleOptions = useMemo(() => {
    const filtered = options.filter((option) => matchesSearch(`${option.label} ${option.value}`, query));
    if (selected && !filtered.some((option) => option.value === selected.value)) return [selected, ...filtered].slice(0, 12);
    return filtered.slice(0, 12);
  }, [options, query, selected]);

  useEffect(() => {
    if (value === undefined || value === lastValueRef.current) return;
    lastValueRef.current = value;
    setSelectedValue(value);
    setQuery(options.find((option) => option.value === value)?.label ?? "");
  }, [options, value]);

  useEffect(() => {
    const close = (event: MouseEvent) => { if (!rootRef.current?.contains(event.target as Node)) setOpen(false); };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, []);

  const choose = (option?: SearchableSelectOption) => {
    const nextValue = option?.value ?? "";
    setSelectedValue(nextValue);
    setQuery(option?.label ?? "");
    setOpen(false);
    setActiveIndex(-1);
    onChange?.(nextValue);
    inputRef.current?.focus();
  };

  return <div className="searchable-select" ref={rootRef}>
    <div className="search-input-wrap"><Search size={16}/><input ref={inputRef} id={id ?? listId} role="combobox" value={query} placeholder={placeholder} autoComplete="off" aria-label={ariaLabel ?? placeholder} aria-autocomplete="list" aria-controls={`${listId}-options`} aria-expanded={open && visibleOptions.length > 0} aria-activedescendant={activeIndex >= 0 && activeIndex < visibleOptions.length ? `${listId}-option-${activeIndex}` : ""} disabled={disabled} onFocus={() => setOpen(true)} onChange={(event) => { setSelectedValue(""); setQuery(event.target.value); setOpen(true); setActiveIndex(-1); }} onKeyDown={(event) => {
      if (event.key === "ArrowDown") { event.preventDefault(); setOpen(true); setActiveIndex((index) => Math.min(index + 1, visibleOptions.length - 1)); }
      if (event.key === "ArrowUp") { event.preventDefault(); setActiveIndex((index) => Math.max(index - 1, 0)); }
      if (event.key === "Enter" && activeIndex >= 0) { event.preventDefault(); choose(visibleOptions[activeIndex]); }
      if (event.key === "Escape") { setOpen(false); setActiveIndex(-1); }
    }}/>{(query || selectedValue) && <button type="button" className="searchable-select-clear" aria-label="Xóa lựa chọn" disabled={disabled} onMouseDown={(event) => event.preventDefault()} onClick={() => choose()}><X size={14}/></button>}</div>
    {open && visibleOptions.length > 0 && <ul id={`${listId}-options`} className="search-suggestions searchable-select-options" role="listbox">{visibleOptions.map((option, index) => <li id={`${listId}-option-${index}`} role="option" aria-selected={option.value === selectedValue} key={option.value} onMouseDown={(event) => event.preventDefault()} onClick={() => choose(option)}>{option.label}</li>)}</ul>}
    {name && <select className="searchable-select-native" name={name} value={selectedValue} required={required} disabled={disabled} tabIndex={-1} aria-hidden="true" onChange={(event) => choose(options.find((option) => option.value === event.target.value))}><option value="">{placeholder}</option>{options.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select>}
  </div>;
}
