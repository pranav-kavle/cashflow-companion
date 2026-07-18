export default function Home() {
  return (
    <main style={{ maxWidth: 640, margin: "80px auto", padding: "0 24px" }}>
      <p className="sec-title">Design system check</p>
      <div className="card pad">
        <h1 className="serif" style={{ fontSize: 32 }}>
          Safe-to-Pay Number
        </h1>
        <p style={{ color: "var(--ink-2)", marginTop: 8 }}>
          Tokens, typography, and primitives ported from the prototype are
          wired into this Next.js app.
        </p>
        <p className="mono" style={{ fontSize: 40, marginTop: 20 }}>
          $3,650
        </p>
        <div style={{ display: "flex", gap: 10, marginTop: 20, alignItems: "center" }}>
          <span className="pill ok">
            <span className="pdot" /> Taxes funded
          </span>
          <span className="pill warn">
            <span className="pdot" /> Runway at risk
          </span>
          <span className="pill neutral">
            <span className="pdot" /> Draft
          </span>
        </div>
        <div style={{ display: "flex", gap: 12, marginTop: 24 }}>
          <button className="btn primary">Confirm</button>
          <button className="btn ghost">Dismiss</button>
        </div>
        <p className="disclaimer" style={{ marginTop: 26 }}>
          Estimates — confirm with your accountant.
        </p>
      </div>
    </main>
  );
}
