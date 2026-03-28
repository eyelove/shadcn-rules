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

interface SnapshotMeta {
  id: string
  scores: Record<string, { pass: number; fail: number; score: number }>
  buildPass: boolean
  detectionRate: number
}

interface SnapshotInfo {
  id: string
  meta: SnapshotMeta | null
  pages: Record<string, () => Promise<{ default: ComponentType }>>
}

function parseSnapshots(): Map<string, SnapshotInfo> {
  const map = new Map<string, SnapshotInfo>()

  // Parse page modules
  for (const [path, loader] of Object.entries(snapshotModules)) {
    const match = path.match(/snapshots\/([^/]+)\/samples\/src\/pages\/(.+)\.tsx$/)
    if (!match) continue
    const [, snapId, pageName] = match

    if (!map.has(snapId)) {
      map.set(snapId, { id: snapId, meta: null, pages: {} })
    }
    map.get(snapId)!.pages[pageName] = loader
  }

  // Parse meta modules (eager loaded)
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
    groups.add(p.replace(/\.(normal|adversarial)$/, ""))
  }
  return Array.from(groups).sort()
}

type CompareMode = "normal-vs-adversarial" | "run-vs-run"

function ScoreBar({ meta, pageName }: { meta: SnapshotMeta | null; pageName: string }) {
  if (!meta) return <span>Score: —</span>
  const s = meta.scores?.[pageName]
  return (
    <>
      <span>Score: {s ? `${s.score}% (${s.pass}/${s.pass + s.fail})` : "—"}</span>
      <span>Build: {meta.buildPass ? "PASS" : "FAIL"}</span>
    </>
  )
}

function App() {
  const [snapshots] = useState(() => parseSnapshots())
  const [mode, setMode] = useState<CompareMode>("normal-vs-adversarial")
  const [selectedSnap, setSelectedSnap] = useState("")
  const [selectedPage, setSelectedPage] = useState("")
  const [leftSnap, setLeftSnap] = useState("")
  const [rightSnap, setRightSnap] = useState("")
  const [runPage, setRunPage] = useState("")
  const [LeftComp, setLeftComp] = useState<ComponentType | null>(null)
  const [RightComp, setRightComp] = useState<ComponentType | null>(null)

  const snapIds = Array.from(snapshots.keys()).sort()

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
      ).sort()
      if (allPages.length > 0) setRunPage(allPages[0])
    }
  }, [snapshots])

  // Load components on selection change
  useEffect(() => {
    if (mode === "normal-vs-adversarial") {
      const snap = snapshots.get(selectedSnap)
      if (!snap || !selectedPage) { setLeftComp(null); setRightComp(null); return }

      const normalKey = `${selectedPage}.normal`
      const advKey = `${selectedPage}.adversarial`

      setLeftComp(snap.pages[normalKey] ? () => lazy(snap.pages[normalKey]) : null)
      setRightComp(snap.pages[advKey] ? () => lazy(snap.pages[advKey]) : null)
    } else {
      const lSnap = snapshots.get(leftSnap)
      const rSnap = snapshots.get(rightSnap)

      setLeftComp(lSnap?.pages[runPage] ? () => lazy(lSnap.pages[runPage]) : null)
      setRightComp(rSnap?.pages[runPage] ? () => lazy(rSnap.pages[runPage]) : null)
    }
  }, [mode, selectedSnap, selectedPage, leftSnap, rightSnap, runPage])

  const currentSnap = snapshots.get(selectedSnap)
  const pageGroups = currentSnap ? getPageGroups(currentSnap) : []
  const allPageNames = Array.from(
    new Set(Array.from(snapshots.values()).flatMap((s) => Object.keys(s.pages)))
  ).sort()

  const leftMeta = mode === "normal-vs-adversarial"
    ? snapshots.get(selectedSnap)?.meta ?? null
    : snapshots.get(leftSnap)?.meta ?? null
  const rightMeta = mode === "normal-vs-adversarial"
    ? snapshots.get(selectedSnap)?.meta ?? null
    : snapshots.get(rightSnap)?.meta ?? null

  const leftPageName = mode === "normal-vs-adversarial" ? `${selectedPage}.normal` : runPage
  const rightPageName = mode === "normal-vs-adversarial" ? `${selectedPage}.adversarial` : runPage

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
          <option value="normal-vs-adversarial">Normal vs Adversarial</option>
          <option value="run-vs-run">Run vs Run</option>
        </select>

        {mode === "normal-vs-adversarial" ? (
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
          </>
        )}
      </header>

      {/* Compare panels */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left panel */}
        <div className="flex-1 flex flex-col border-r border-border overflow-hidden">
          <div className="px-3 py-2 border-b border-border bg-muted/30 text-xs text-muted-foreground">
            {mode === "normal-vs-adversarial" ? leftPageName : `${leftSnap} / ${runPage}`}
          </div>
          <div className="flex-1 overflow-y-auto">
            <Suspense fallback={Loading}>
              {LeftComp ? <LeftComp /> : Empty}
            </Suspense>
          </div>
          <div className="px-3 py-2 border-t border-border bg-muted/30 text-xs flex gap-4">
            <ScoreBar meta={leftMeta} pageName={leftPageName} />
          </div>
        </div>

        {/* Right panel */}
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="px-3 py-2 border-b border-border bg-muted/30 text-xs text-muted-foreground">
            {mode === "normal-vs-adversarial" ? rightPageName : `${rightSnap} / ${runPage}`}
          </div>
          <div className="flex-1 overflow-y-auto">
            <Suspense fallback={Loading}>
              {RightComp ? <RightComp /> : Empty}
            </Suspense>
          </div>
          <div className="px-3 py-2 border-t border-border bg-muted/30 text-xs flex gap-4">
            <ScoreBar meta={rightMeta} pageName={rightPageName} />
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
