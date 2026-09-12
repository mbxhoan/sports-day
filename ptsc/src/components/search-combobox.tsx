"use client";

import { Search, X } from "lucide-react";
import { useEffect, useId, useMemo, useRef, useState } from "react";
import { matchesSearch, type SearchSuggestion } from "@/lib/search";

type Props = {
  label: string;
  hideLabel?: boolean;
  placeholder: string;
  suggestions: SearchSuggestion[];
  value: string;
  onChange: (value: string) => void;
  onSelect: (suggestion: SearchSuggestion) => void;
};

export function SearchCombobox({ label, hideLabel = false, placeholder, suggestions, value, onChange, onSelect }: Props) {
  const listId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const options = useMemo(() => suggestions.filter((item) => matchesSearch(item.searchText, value)).slice(0, 8), [suggestions, value]);

  useEffect(() => {
    const close = (event: MouseEvent) => { if (!rootRef.current?.contains(event.target as Node)) setOpen(false); };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, []);

  const choose = (suggestion: SearchSuggestion) => {
    onSelect(suggestion);
    setOpen(false);
    setActiveIndex(-1);
    inputRef.current?.focus();
  };

  return <div className={`search-combobox${hideLabel ? " search-combobox-compact" : ""}`} ref={rootRef}>
    <label className={hideLabel ? "visually-hidden" : undefined} htmlFor={listId}>{label}</label>
    <div className="search-input-wrap"><Search size={16}/><input ref={inputRef} id={listId} role="combobox" value={value} placeholder={placeholder} autoComplete="off" aria-autocomplete="list" aria-controls={`${listId}-options`} aria-expanded={open && options.length > 0} aria-activedescendant={activeIndex >= 0 && activeIndex < options.length ? `${listId}-option-${activeIndex}` : ""} onFocus={() => setOpen(true)} onChange={(event) => { onChange(event.target.value); setOpen(true); setActiveIndex(-1); }} onKeyDown={(event) => {
      if (event.key === "ArrowDown") { event.preventDefault(); setOpen(true); setActiveIndex((index) => options.length ? (index + 1) % options.length : -1); }
      if (event.key === "ArrowUp") { event.preventDefault(); setActiveIndex((index) => options.length ? (index <= 0 ? options.length - 1 : index - 1) : -1); }
      if (event.key === "Enter" && options[activeIndex]) { event.preventDefault(); choose(options[activeIndex]); }
      if (event.key === "Escape") { setOpen(false); setActiveIndex(-1); }
    }}/>{value && <button type="button" className="search-clear" aria-label="Xoá tìm kiếm" onClick={() => { onChange(""); inputRef.current?.focus(); }}><X size={15}/></button>}</div>
    {open && options.length > 0 && <ul id={`${listId}-options`} className="search-suggestions" role="listbox">{options.map((suggestion, index) => <li key={`${suggestion.kind}-${suggestion.id}`} id={`${listId}-option-${index}`} role="option" aria-selected={activeIndex === index} onMouseDown={(event) => { event.preventDefault(); choose(suggestion); }}><b>{suggestion.label}</b><small>{suggestion.detail}</small></li>)}</ul>}
  </div>;
}
