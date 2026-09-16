"use client";

import { useState } from "react";

/**
 * A <select> of preset options that reveals a free-text box when "Custom…"
 * is chosen. Keeps data entry fast for the common cases while never
 * actually restricting what can be typed.
 */
export default function PresetSelect({
  options,
  value,
  onChange,
  placeholder,
}: {
  options: string[];
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  const isKnownPreset = options.includes(value) && value !== "Custom…";
  const [isCustom, setIsCustom] = useState(value !== "" && !isKnownPreset);

  return (
    <div className="space-y-1">
      <select
        value={isCustom ? "Custom…" : value}
        onChange={(e) => {
          if (e.target.value === "Custom…") {
            setIsCustom(true);
            onChange("");
          } else {
            setIsCustom(false);
            onChange(e.target.value);
          }
        }}
        className="w-full border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
      >
        <option value="">{placeholder ?? "Select…"}</option>
        {options.map((opt) => (
          <option key={opt} value={opt}>{opt}</option>
        ))}
      </select>
      {isCustom && (
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Type custom value"
          className="w-full border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
        />
      )}
    </div>
  );
}
