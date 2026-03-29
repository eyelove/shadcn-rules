import { useState, useEffect, Suspense, lazy } from "react"
import type { ComponentType } from "react"

// Glob import all snapshot page files
const snapshotModules = import.meta.glob(
  "../../tests/snapshots/*/samples/src/pages/*.tsx"
) as Record<string, () => Promise<{ default: ComponentType }>>

// Glob import all meta.json files
const metaModules = import.meta.glob(
  "../../tests/snapshots/*/meta.json",
  { eager: true }
) as Record<string, { default: Record<string, unknown> }>

interface ArmScore {
  pass: number
  fail: number
  score: number
}

interface PageScore {
  with_rules: ArmScore
  without_rules: ArmScore
  delta: number
}

interface SnapshotMeta {
  id: string
  mode: string
  scores: Record<string, PageScore>
  buildPass: boolean
}

interface SnapshotInfo {
  id: string
  meta: SnapshotMeta | null
  pages: Record<string, () => Promise<{ default: ComponentType }>>
}

function parseSnapshots(): Map<string, SnapshotInfo> {
  const map = new Map<string, SnapshotInfo>()

  for (const [path, loader] of Object.entries(snapshotModules)) {
    const match = path.match(/snapshots\/([^/]+)\/samples\/src\/pages\/(.+)\.tsx$/)
    if (!match) continue
    const [, snapId, pageName] = match

    if (!map.has(snapId)) {
      map.set(snapId, { id: snapId, meta: null, pages: {} })
    }
    map.get(snapId)!.pages[pageName] = loader
  }

  for (const [path, mod] of Object.entries(metaModules)) {
    const match = path.match(/snapshots\/([^/]+)\/meta\.json$/)
    if (!match) continue
    const snapId = match[1]
    const info = map.get(snapId)
    if (info) {
      info.meta = (mod.default ?? mod) as unknown as SnapshotMeta
    }
  }

  return map
}

function getPageGroups(snap: SnapshotInfo): string[] {
  const groups = new Set<string>()
  for (const p of Object.keys(snap.pages)) {
    groups.add(p.replace(/\.(with_rules|without_rules)$/, ""))
  }
  return Array.from(groups).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
}

type CompareMode = "ab" | "run-vs-run"
type Arm = "with_rules" | "without_rules"

function getVerdict(delta: number): string {
  if (delta >= 20) return "EFFECTIVE"
  if (delta >= 5) return "MARGINAL"
  if (delta >= 0) return "NO DIFF"
  return "NEGATIVE"
}

function getVerdictColor(delta: number): string {
  if (delta >= 20) return "text-green-600"
  if (delta >= 5) return "text-yellow-600"
  if (delta >= 0) return "text-muted-foreground"
  return "text-red-600"
}

function ScoreBar({ meta, pageName, arm }: { meta: SnapshotMeta | null; pageName: string; arm?: Arm }) {
  if (!meta) return <span>Score: —</span>

  const pageScore = meta.scores?.[pageName]
  if (!pageScore) return <span>Score: —</span>

  if (arm) {
    const s = pageScore[arm]
    if (!s) return <span>Score: —</span>
    return (
      <>
        <span>Score: {s.score}% ({s.pass}/{s.pass + s.fail})</span>
        <span>Build: {meta.buildPass ? "PASS" : "FAIL"}</span>
      </>
    )
  }

  // A/B summary
  const delta = pageScore.delta
  const verdict = getVerdict(delta)
  return (
    <>
      <span>A: {pageScore.with_rules.score}%</span>
      <span>B: {pageScore.without_rules.score}%</span>
      <span className={getVerdictColor(delta)}>
        delta: {delta >= 0 ? "+" : ""}{delta}% ({verdict})
      </span>
      <span>Build: {meta.buildPass ? "PASS" : "FAIL"}</span>
    </>
  )
}

function App() {
  const [snapshots] = useState(() => parseSnapshots())
  const [mode, setMode] = useState<CompareMode>("ab")
  // A/B mode state
  const [selectedSnap, setSelectedSnap] = useState("")
  const [selectedPage, setSelectedPage] = useState("")
  // Run vs Run mode state
  const [leftSnap, setLeftSnap] = useState("")
  const [rightSnap, setRightSnap] = useState("")
  const [runPage, setRunPage] = useState("")
  const [runArm, setRunArm] = useState<Arm>("with_rules")
  // Loaded components
  const [LeftComp, setLeftComp] = useState<ComponentType | null>(null)
  const [RightComp, setRightComp] = useState<ComponentType | null>(null)

  const snapIds = Array.from(snapshots.keys()).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))

  // Initialize defaults
  useEffect(() => {
    if (snapIds.length > 0) {
      setSelectedSnap(snapIds[snapIds.length - 1])
      setLeftSnap(snapIds[snapIds.length - 1])
      setRightSnap(snapIds.length > 1 ? snapIds[snapIds.length - 2] : snapIds[0])
    }
  }, [])

  // Auto-select first page group
  useEffect(() => {
    if (!selectedSnap) return
    const snap = snapshots.get(selectedSnap)
    if (snap && !selectedPage) {
      const groups = getPageGroups(snap)
      if (groups.length > 0) setSelectedPage(groups[0])
    }
  }, [selectedSnap])

  // Auto-select first run page
  useEffect(() => {
    if (!runPage) {
      const allPages = Array.from(
        new Set(Array.from(snapshots.values()).flatMap((s) => Object.keys(s.pages)))
      ).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
      if (allPages.length > 0) setRunPage(allPages[0])
    }
  }, [snapshots])

  // Load components on selection change
  useEffect(() => {
    if (mode === "ab") {
      const snap = snapshots.get(selectedSnap)
      if (!snap || !selectedPage) { setLeftComp(null); setRightComp(null); return }

      const withKey = `${selectedPage}.with_rules`
      const withoutKey = `${selectedPage}.without_rules`

      setLeftComp(snap.pages[withKey] ? () => lazy(snap.pages[withKey]) : null)
      setRightComp(snap.pages[withoutKey] ? () => lazy(snap.pages[withoutKey]) : null)
    } else {
      const lSnap = snapshots.get(leftSnap)
      const rSnap = snapshots.get(rightSnap)
      const pageKey = `${runPage}.${runArm}`

      // For run-vs-run with raw page name (may already include arm suffix)
      const lKey = lSnap?.pages[pageKey] ? pageKey : runPage
      const rKey = rSnap?.pages[pageKey] ? pageKey : runPage

      setLeftComp(lSnap?.pages[lKey] ? () => lazy(lSnap.pages[lKey]) : null)
      setRightComp(rSnap?.pages[rKey] ? () => lazy(rSnap.pages[rKey]) : null)
    }
  }, [mode, selectedSnap, selectedPage, leftSnap, rightSnap, runPage, runArm])

  const currentSnap = snapshots.get(selectedSnap)
  const pageGroups = currentSnap ? getPageGroups(currentSnap) : []
  const allPageNames = Array.from(
    new Set(
      Array.from(snapshots.values())
        .flatMap((s) => Object.keys(s.pages))
        .map((p) => p.replace(/\.(with_rules|without_rules)$/, ""))
    )
  ).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))

  const Loading = (
    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
      Loading...
    </div>
  )

  const Empty = (
    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
      No page found
    </div>
  )

  if (snapIds.length === 0) {
    return (
      <div className="flex h-screen items-center justify-center text-sm text-muted-foreground">
        No snapshots found. Run eval first.
      </div>
    )
  }

  return (
    <div className="flex flex-col h-screen bg-background text-foreground">
      {/* Header */}
      <header className="border-b border-border px-4 py-3 flex items-center gap-4 shrink-0 flex-wrap">
        <h1 className="text-sm font-semibold">shadcn-rules Preview</h1>

        <select
          value={mode}
          onChange={(e) => setMode(e.target.value as CompareMode)}
          className="text-sm border border-border rounded px-2 py-1 bg-background"
        >
          <option value="ab">A/B (with rules vs without)</option>
          <option value="run-vs-run">Run vs Run</option>
        </select>

        {mode === "ab" ? (
          <>
            <select
              value={selectedSnap}
              onChange={(e) => setSelectedSnap(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {snapIds.map((id) => <option key={id} value={id}>{id}</option>)}
            </select>
            <select
              value={selectedPage}
              onChange={(e) => setSelectedPage(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {pageGroups.map((pg) => <option key={pg} value={pg}>{pg}</option>)}
            </select>
          </>
        ) : (
          <>
            <span className="text-xs text-muted-foreground">Left:</span>
            <select
              value={leftSnap}
              onChange={(e) => setLeftSnap(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {snapIds.map((id) => <option key={id} value={id}>{id}</option>)}
            </select>
            <span className="text-xs text-muted-foreground">Right:</span>
            <select
              value={rightSnap}
              onChange={(e) => setRightSnap(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {snapIds.map((id) => <option key={id} value={id}>{id}</option>)}
            </select>
            <select
              value={runPage}
              onChange={(e) => setRunPage(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {allPageNames.map((p) => <option key={p} value={p}>{p}</option>)}
            </select>
            <select
              value={runArm}
              onChange={(e) => setRunArm(e.target.value as Arm)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              <option value="with_rules">with_rules</option>
              <option value="without_rules">without_rules</option>
            </select>
          </>
        )}
      </header>

      {/* Compare panels */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left panel */}
        <div className="flex-1 flex flex-col border-r border-border overflow-hidden">
          <div className="px-3 py-2 border-b border-border bg-muted/30 text-xs text-muted-foreground font-medium">
            {mode === "ab" ? (
              <>{selectedPage} — <span className="text-foreground">A (with_rules)</span></>
            ) : (
              <>{leftSnap} / {runPage}.{runArm}</>
            )}
          </div>
          <div className="flex-1 overflow-y-auto">
            <Suspense fallback={Loading}>
              {LeftComp ? <LeftComp /> : Empty}
            </Suspense>
          </div>
          <div className="px-3 py-2 border-t border-border bg-muted/30 text-xs flex gap-4">
            {mode === "ab" ? (
              <ScoreBar meta={currentSnap?.meta ?? null} pageName={selectedPage} arm="with_rules" />
            ) : (
              <ScoreBar meta={snapshots.get(leftSnap)?.meta ?? null} pageName={runPage} arm={runArm} />
            )}
          </div>
        </div>

        {/* Right panel */}
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="px-3 py-2 border-b border-border bg-muted/30 text-xs text-muted-foreground font-medium">
            {mode === "ab" ? (
              <>{selectedPage} — <span className="text-foreground">B (without_rules)</span></>
            ) : (
              <>{rightSnap} / {runPage}.{runArm}</>
            )}
          </div>
          <div className="flex-1 overflow-y-auto">
            <Suspense fallback={Loading}>
              {RightComp ? <RightComp /> : Empty}
            </Suspense>
          </div>
          <div className="px-3 py-2 border-t border-border bg-muted/30 text-xs flex gap-4">
            {mode === "ab" ? (
              <ScoreBar meta={currentSnap?.meta ?? null} pageName={selectedPage} arm="without_rules" />
            ) : (
              <ScoreBar meta={snapshots.get(rightSnap)?.meta ?? null} pageName={runPage} arm={runArm} />
            )}
          </div>
        </div>
      </div>

      {/* A/B Summary Footer */}
      {mode === "ab" && currentSnap?.meta && (
        <footer className="border-t border-border px-4 py-2 bg-muted/20 text-xs flex gap-6">
          <ScoreBar meta={currentSnap.meta} pageName={selectedPage} />
        </footer>
      )}
    </div>
  )
}

export default App
