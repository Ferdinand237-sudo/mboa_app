"use client";

export function FilterPills<T extends string>({
  options,
  value,
  onChange,
}: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (v: T) => void;
}) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-1">
      {options.map((o) => {
        const isSelected = value === o.value;
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            className={`shrink-0 rounded-full border-[1.5px] px-3.5 py-1.5 text-xs font-semibold ${
              isSelected
                ? "border-mboa-primary bg-mboa-primary text-white"
                : "border-mboa-border bg-white text-mboa-text"
            }`}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
