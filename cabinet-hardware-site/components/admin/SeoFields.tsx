"use client";

// "How this appears on Google" editor, shared by the product and blog forms.
// The fields are filled in automatically from what the admin has typed. If the
// admin edits one, it is locked to their wording until they press "Reset to auto".

type Props = {
  urlPreview: string;
  title: string;
  description: string;
  titleIsAuto: boolean;
  descriptionIsAuto: boolean;
  onTitleChange: (v: string) => void;
  onDescriptionChange: (v: string) => void;
  onResetTitle: () => void;
  onResetDescription: () => void;
};

export default function SeoFields({
  urlPreview,
  title,
  description,
  titleIsAuto,
  descriptionIsAuto,
  onTitleChange,
  onDescriptionChange,
  onResetTitle,
  onResetDescription,
}: Props) {
  const titleLen = title.length;
  const descLen = description.length;

  return (
    <div className="space-y-4 border border-nickel/30 p-4">
      <div>
        <p className="font-body text-sm font-medium text-ink">Google search listing (SEO)</p>
        <p className="mt-1 font-body text-xs text-graphite">
          Filled in automatically from your details above. You can change either line — your wording is
          then kept until you press &quot;Reset to auto&quot;.
        </p>
      </div>

      {/* Live preview of the Google result */}
      <div className="border border-nickel/20 bg-white/60 p-4">
        <p className="truncate font-body text-xs text-olive">{urlPreview}</p>
        <p className="mt-1 font-body text-lg leading-snug text-[#1a0dab]">{title || "Page title appears here"}</p>
        <p className="mt-1 font-body text-sm text-graphite">{description || "Page description appears here."}</p>
      </div>

      <label className="block">
        <span className="flex items-center justify-between font-body text-sm text-graphite">
          <span>
            SEO title{" "}
            <span className={`text-xs ${titleIsAuto ? "text-olive" : "text-brass"}`}>
              {titleIsAuto ? "(auto)" : "(edited by you)"}
            </span>
          </span>
          <span className={`text-xs ${titleLen > 60 ? "text-rust" : "text-graphite"}`}>{titleLen}/60</span>
        </span>
        <input
          value={title}
          onChange={(e) => onTitleChange(e.target.value)}
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
        />
        {!titleIsAuto && (
          <button type="button" onClick={onResetTitle} className="mt-1 font-body text-xs text-graphite underline hover:text-ink">
            Reset to auto
          </button>
        )}
      </label>

      <label className="block">
        <span className="flex items-center justify-between font-body text-sm text-graphite">
          <span>
            SEO description{" "}
            <span className={`text-xs ${descriptionIsAuto ? "text-olive" : "text-brass"}`}>
              {descriptionIsAuto ? "(auto)" : "(edited by you)"}
            </span>
          </span>
          <span className={`text-xs ${descLen > 160 ? "text-rust" : "text-graphite"}`}>{descLen}/155</span>
        </span>
        <textarea
          value={description}
          onChange={(e) => onDescriptionChange(e.target.value)}
          rows={3}
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
        />
        {!descriptionIsAuto && (
          <button
            type="button"
            onClick={onResetDescription}
            className="mt-1 font-body text-xs text-graphite underline hover:text-ink"
          >
            Reset to auto
          </button>
        )}
      </label>
    </div>
  );
}
