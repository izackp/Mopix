# Tennis Rendering and Presentation Signature

```swift
// OWNED BY: TennisPresentation owns visual projection, HUD, transient cues, and reserved
// audio notifications. TennisMatchRuntime owns all source state and sends snapshots/events.
// DEPENDENCIES: GameEngine IDrawable, DisplayRenderClient, DrawCmd, AtlasLoader, VirtualDrive;
// tennis presentation snapshots/events. Assets are resolved only through vd:// URLs.

struct TennisViewport {
    let width: Int
    let height: Int
}

struct TennisPresentationAssets {
    let player: VDUrl
    let ball: VDUrl
    let scoreFont: VDUrl
    let surfaceVariants: [CourtSurface: VDUrl]
}

protocol TennisAssetProvider {
    func mountAndResolve(_ assets: TennisPresentationAssets, drive: VirtualDrive) throws
    func atlas(for url: VDUrl) -> ImageAtlas
}

protocol TennisCuePresenter {
    func present(_ event: TennisMatchEvent)
    func present(_ event: TennisSimulationEvent)
}

final class TennisPresentation: IDrawable, TennisMatchDelegate, TennisSimulationDelegate {
    let viewport: TennisViewport
    let assets: TennisPresentationAssets
    let assetProvider: TennisAssetProvider
    let snapshotSource: TennisPresentationSnapshotSource
    let cuePresenter: TennisCuePresenter

    init(viewport: TennisViewport, assets: TennisPresentationAssets, assetProvider: TennisAssetProvider, snapshotSource: TennisPresentationSnapshotSource, cuePresenter: TennisCuePresenter)
    func draw(_ delta: UInt64, _ renderer: DisplayRenderClient)
    func matchDidEmit(_ event: TennisMatchEvent)
    func simulationDidEmit(_ event: TennisSimulationEvent)
}

protocol TennisDrawCommandSink {
    func drawCourt(surface: CourtSurface, viewport: TennisViewport, renderer: DisplayRenderClient)
    func drawPlayers(_ state: TennisSimulationState, renderer: DisplayRenderClient)
    func drawBall(_ state: TennisBallState, renderer: DisplayRenderClient)
    func drawTrail(_ state: TennisBallState, renderer: DisplayRenderClient)
    func drawLandingMarker(_ state: TennisBallState, renderer: DisplayRenderClient)
    func drawHUD(_ snapshot: TennisPresentationSnapshot, renderer: DisplayRenderClient)
    func drawPointEndCue(_ event: TennisSimulationEvent, renderer: DisplayRenderClient)
    func drawMenu(_ snapshot: TennisPresentationSnapshot, renderer: DisplayRenderClient)
}

protocol TennisAudioHookSink {
    func serveHit()
    func shotHit(_ shot: ShotKind)
    func surfaceBounce(_ surface: CourtSurface)
    func netContact()
    func outOfBounds()
    func scoreStinger()
}
```

The presentation layer always draws at logical `160x144`, with renderer interpolation
limited to visual projection; it never feeds interpolated values back into simulation.
It must show court/net/boundaries, colored trails (red topspin, blue slice, purple smash),
landing marker, surface tell, distinct net/out cues, score digits, serving side, and the
active player's charge/cap cue. Audio hooks may be silent in MVP. No asset path bypasses
`VirtualDrive.shared.mountPath()` or a `vd://` URL.

// TEST: native-resolution score legibility and all required visual cue distinctions.
// TEST: presentation consumes snapshots without changing simulation state.
