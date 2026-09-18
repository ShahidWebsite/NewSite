"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { BankAccount } from "@/lib/types";

const emptyForm = { bank_name: "", account_title: "", account_number: "", ifsc_or_routing: "" };

export default function AdminBankAccountsPage() {
  const [accounts, setAccounts] = useState<BankAccount[]>([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(emptyForm);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [instructions, setInstructions] = useState("");
  const [instructionsSaved, setInstructionsSaved] = useState(false);

  async function load() {
    setLoading(true);
    const [{ data: accountsData }, { data: settingsData }] = await Promise.all([
      supabase.from("bank_accounts").select("*").order("sort_order"),
      supabase.from("bank_settings").select("instructions").single(),
    ]);
    setAccounts(accountsData ?? []);
    setInstructions(settingsData?.instructions ?? "");
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  function startEdit(acc: BankAccount) {
    setEditingId(acc.id);
    setForm({
      bank_name: acc.bank_name,
      account_title: acc.account_title,
      account_number: acc.account_number,
      ifsc_or_routing: acc.ifsc_or_routing,
    });
    setError(null);
  }

  function cancelEdit() {
    setEditingId(null);
    setForm(emptyForm);
    setError(null);
  }

  async function handleSave() {
    if (!form.bank_name.trim() || !form.account_title.trim() || !form.account_number.trim()) {
      setError("Bank name, account title, and account number are all required.");
      return;
    }
    setError(null);

    if (editingId) {
      const { error } = await supabase
        .from("bank_accounts")
        .update({
          bank_name: form.bank_name.trim(),
          account_title: form.account_title.trim(),
          account_number: form.account_number.trim(),
          ifsc_or_routing: form.ifsc_or_routing.trim(),
        })
        .eq("id", editingId);
      if (error) {
        setError(error.message);
        return;
      }
    } else {
      const { error } = await supabase.from("bank_accounts").insert({
        bank_name: form.bank_name.trim(),
        account_title: form.account_title.trim(),
        account_number: form.account_number.trim(),
        ifsc_or_routing: form.ifsc_or_routing.trim(),
        sort_order: accounts.length,
      });
      if (error) {
        setError(error.message);
        return;
      }
    }

    cancelEdit();
    load();
  }

  async function toggleActive(acc: BankAccount) {
    await supabase.from("bank_accounts").update({ active: !acc.active }).eq("id", acc.id);
    load();
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this bank account? This can't be undone.")) return;
    await supabase.from("bank_accounts").delete().eq("id", id);
    load();
  }

  async function move(index: number, direction: -1 | 1) {
    const target = index + direction;
    if (target < 0 || target >= accounts.length) return;
    const a = accounts[index];
    const b = accounts[target];
    await Promise.all([
      supabase.from("bank_accounts").update({ sort_order: b.sort_order }).eq("id", a.id),
      supabase.from("bank_accounts").update({ sort_order: a.sort_order }).eq("id", b.id),
    ]);
    load();
  }

  async function saveInstructions() {
    await supabase.from("bank_settings").update({ instructions }).eq("id", 1);
    setInstructionsSaved(true);
    setTimeout(() => setInstructionsSaved(false), 2000);
  }

  return (
    <div className="max-w-2xl">
      <h1 className="font-display text-3xl text-ink">Bank accounts</h1>
      <p className="mt-2 font-body text-sm text-graphite">
        Shown to customers after they place an order and choose bank transfer. Add as many
        accounts as you like — customers can pay into whichever is easiest for them.
      </p>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : (
        <>
          <div className="mt-8 divide-y divide-nickel/20 border-y border-nickel/20">
            {accounts.length === 0 && (
              <p className="py-4 font-body text-sm text-graphite">No bank accounts added yet.</p>
            )}
            {accounts.map((acc, i) => (
              <div key={acc.id} className="flex items-center justify-between gap-4 py-4 font-body text-sm">
                <div>
                  <p className={acc.active ? "text-ink" : "text-graphite line-through"}>
                    {acc.bank_name} — {acc.account_number}
                  </p>
                  <p className="text-xs text-graphite">{acc.account_title}</p>
                </div>
                <div className="flex items-center gap-3 text-xs">
                  <button onClick={() => move(i, -1)} disabled={i === 0} className="text-graphite hover:text-ink disabled:opacity-30">
                    ↑
                  </button>
                  <button
                    onClick={() => move(i, 1)}
                    disabled={i === accounts.length - 1}
                    className="text-graphite hover:text-ink disabled:opacity-30"
                  >
                    ↓
                  </button>
                  <button onClick={() => toggleActive(acc)} className="text-graphite hover:text-ink">
                    {acc.active ? "Hide" : "Show"}
                  </button>
                  <button onClick={() => startEdit(acc)} className="text-graphite hover:text-ink">
                    Edit
                  </button>
                  <button onClick={() => handleDelete(acc.id)} className="text-graphite hover:text-rust">
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 border border-nickel/25 p-5">
            <p className="font-body text-sm text-ink">{editingId ? "Edit account" : "Add a bank account"}</p>
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              <TextField label="Bank name" value={form.bank_name} onChange={(v) => setForm({ ...form, bank_name: v })} />
              <TextField label="Account title" value={form.account_title} onChange={(v) => setForm({ ...form, account_title: v })} />
              <TextField
                label="Account number"
                value={form.account_number}
                onChange={(v) => setForm({ ...form, account_number: v })}
              />
              <TextField
                label="IBAN / Routing (optional)"
                value={form.ifsc_or_routing}
                onChange={(v) => setForm({ ...form, ifsc_or_routing: v })}
              />
            </div>
            {error && <p className="mt-3 font-body text-sm text-rust">{error}</p>}
            <div className="mt-4 flex gap-3">
              <button onClick={handleSave} className="bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass">
                {editingId ? "Save changes" : "Add account"}
              </button>
              {editingId && (
                <button onClick={cancelEdit} className="font-body text-sm text-graphite hover:text-ink">
                  Cancel
                </button>
              )}
            </div>
          </div>

          <div className="mt-8 border border-nickel/25 p-5">
            <p className="font-body text-sm text-ink">Payment instructions</p>
            <p className="mt-1 font-body text-xs text-graphite">
              Shown once, below all the accounts (e.g. asking customers to use their order number as reference).
            </p>
            <textarea
              value={instructions}
              onChange={(e) => setInstructions(e.target.value)}
              rows={3}
              className="mt-3 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
            />
            <button
              onClick={saveInstructions}
              className="mt-3 border border-ink px-4 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
            >
              {instructionsSaved ? "Saved ✓" : "Save instructions"}
            </button>
          </div>
        </>
      )}
    </div>
  );
}

function TextField({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <label className="block">
      <span className="font-body text-xs text-graphite">{label}</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
      />
    </label>
  );
}
