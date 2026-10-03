# Liquid Glass: API and behavior differences between 26.x and 27

Researched 2026-10-03 for issue #84. Deployment targets at the time of writing: macOS 27.0, iOS 26.0 (temporary; moving to 27.0).

Sources are Apple primary sources only. Availability figures come from the Apple Developer Documentation JSON for each symbol (`developer.apple.com/tutorials/data/documentation/swiftui/<symbol>.json`, the same data that renders the "Availability" box on each doc page), fetched on the research date. The source key for each claim is in [Sources](#sources).

## Bottom line

- **The core Liquid Glass API surface is unchanged in 27.** `glassEffect(_:in:)`, `Glass` (`regular`, `clear`, `identity`, `tint(_:)`, `interactive(_:)`), `GlassEffectContainer`, `glassEffectID`, `glassEffectUnion`, `glassEffectTransition`/`GlassEffectTransition`, `.glass`/`.glassProminent`, `ToolbarSpacer`, `sharedBackgroundVisibility`, `scrollEdgeEffectStyle`/`scrollEdgeEffectHidden`, `backgroundExtensionEffect()`, `safeAreaBar`, `searchToolbarBehavior`, `tabBarMinimizeBehavior`, `tabViewBottomAccessory`, `buttonSizing` are all iOS 26.0 / macOS 26.0. `Glass` gained no new members in 27 [D-Glass]. None of these are deprecated [D-avail].
- **27 changes the look and feel, not the glass API.** Apps get the refined glass (stronger diffusion, darkened edge, brighter specular highlights), the user's new "ultra clear ↔ fully tinted" Liquid Glass slider, full-bleed sidebars on Mac/iPad, and a uniform toolbar backing under floating bars, with no code change and no recompile [SOTU26] [WN-SUI26].
- **27-only APIs are all toolbar/tab/picker additions around the glass, not glass itself:** `toolbarMinimizationBehavior(_:for:)`, `toolbarMinimizationSafeAreaAdjustment(_:for:)`, `ToolbarOverflowMenu`, `.topBarPinnedTrailing`, `visibilityPriority(_:)` (iOS 27; macOS 26.1), `TabRole.prominent`, `.tabs` picker style, `ToolbarPlacement.statusBar`, `NavigationTransition.crossFade`, plus non-glass 27 APIs. 27.1 adds vertical-bar APIs (`toolbarVerticalEdge`, `toolbarVerticalBehavior`, `axisBehavior`) [D-avail] [UPD-SUI].
- **One 26.x point-release API matters for an iOS 26.0 target:** `tabViewBottomAccessory(isEnabled:content:)` is iOS 26.1 and needs `#available(iOS 26.1, *)` while the target is 26.0 [D-avail].
- **The compatibility escape hatch goes away at 27.** `UIDesignRequiresCompatibility` is ignored when building for iOS/iPadOS/macOS/tvOS/Mac Catalyst 27 or later [D-UIDRC]. Not relevant to this app (it never opted out), but it means there is no "old look" fallback once the target is 27.

## Decision table

Legend for **Ship status** (for this app: iOS target 26.0, macOS target 27.0):

- **Ships now (26)**: available at iOS 26.0 and macOS 26.0 or earlier; no `#available` needed.
- **Ships now, gate 26.1**: needs `if #available(iOS 26.1, *)` until the iOS target moves.
- **Needs iOS 27**: iOS 27.0+; on iOS it must sit behind `#available(iOS 27, *)` until the target moves. Usually fine unguarded on macOS (target 27.0).
- **Behavior-only**: no API; appears automatically when running on 27.

| Surface / API | iOS availability | macOS availability | 27 change | Ship status |
|---|---|---|---|---|
| `glassEffect(_:in:)` | 26.0 | 26.0 | Automatic refreshed rendering; responds to the new Liquid Glass slider [WN-SUI26] | Ships now (26) |
| `Glass.regular` / `.clear` / `.identity` | 26.0 | 26.0 | No new variants; appearance can change with the user's preferred-look setting and with Reduce Transparency / Increase Contrast [HIG-Mat] | Ships now (26) |
| `Glass.tint(_:)` | 26.0 | 26.0 | None documented | Ships now (26) |
| `Glass.interactive(_:)` | 26.0 | 26.0 | macOS 27 adds a click "bounce" for interactive glass, tuned for the pointer [AppKit26] [WN-SUI26]. Inference: on macOS 26 the modifier compiles but the bounce is not shown; that is not stated outright | Ships now (26); richer on macOS 27 |
| `GlassEffectContainer(spacing:)` | 26.0 | 26.0 | None documented | Ships now (26) |
| `glassEffectID(_:in:)`, `glassEffectUnion(id:namespace:)` | 26.0 | 26.0 | None documented | Ships now (26) |
| `glassEffectTransition(_:)` (`.matchedGeometry`, `.materialize`, `.identity`) | 26.0 | 26.0 | None documented | Ships now (26) |
| `.buttonStyle(.glass)` / `.glassProminent` | 26.0 | 26.0 | macOS 27 SDK fix: hover state now shows outside toolbars [RN-macOS27] | Ships now (26) |
| `buttonSizing(_:)` | 26.0 | 26.0 | None | Ships now (26) |
| `ToolbarSpacer(.fixed/.flexible)` | 26.0 | 26.0 | None | Ships now (26) |
| `ToolbarContent.sharedBackgroundVisibility(_:)` | 26.0 | 26.0 | None | Ships now (26) |
| `ToolbarContent.visibilityPriority(_:)` / `ToolbarItemVisibilityPriority` | **27.0** | 26.1 | New in WWDC26 [WN-SUI26] | **Needs iOS 27** (fine on macOS) |
| `ToolbarOverflowMenu` | **27.0** | not listed (iOS, iPadOS, Catalyst, visionOS only) | New | **Needs iOS 27**; not on native macOS |
| `ToolbarItemPlacement.topBarPinnedTrailing` | **27.0** | not listed | New | **Needs iOS 27**; iOS/iPadOS only |
| `toolbarMinimizationBehavior(_:for:)` (`.onScrollDown`; `.onScrollUp` is iOS-only) | **27.0** | 27.0 | New. Replaces the beta-1 name `toolbarMinimizeBehavior` [RN-iOS27]. Only supported placement is `.navigationBar`; an integrated top tab bar minimizes with it [D-TMB] | **Needs iOS 27** |
| `toolbarMinimizationSafeAreaAdjustment(_:for:)` | **27.0** | 27.0 | New | **Needs iOS 27** |
| `toolbarVerticalEdge`, `toolbarVerticalBehavior(_:)`, `axisBehavior(_:)`, `toolbarVerticalCompressionBehavior(_:)` | **27.1** | 27.1 | New in Sept 2026 (iPhone Duo vertical bars) [UPD-SUI] | Needs iOS 27.1 / macOS 27.1 |
| Toolbar / navigation bar glass (automatic) | 26.0 | 26.0 | 27: uniform toolbar backing under floating bars when content scrolls beneath, customizable via the existing scroll edge effect APIs [SOTU26]. Toolbar items move to overflow as space shrinks (see `visibilityPriority`) | Behavior-only |
| `scrollEdgeEffectStyle(_:for:)` (`.automatic/.soft/.hard`), `scrollEdgeEffectHidden(_:for:)` | 26.0 | 26.0 | macOS 27: `.automatic` resolves to **hard** when free-floating text such as the window title sits in the title bar [AppKit26] | Ships now (26); different default on macOS 27 |
| `safeAreaBar(edge:alignment:spacing:content:)` | 26.0 | 26.0 | None | Ships now (26) |
| `backgroundExtensionEffect()` | 26.0 | 26.0 | None documented; pairs with the full-bleed sidebar on macOS/iPadOS 27 | Ships now (26) |
| Sidebar glass (`NavigationSplitView`) | 26.0 | 26.0 | 27 on Mac and iPad: sidebars extend to window edges, still refract content; sidebar icons use the app accent color; macOS selection uses semibold text; bordered toolbar items over the sidebar adopt glass [SOTU26] [AppKit26] | Behavior-only |
| Inspector glass (`inspector(isPresented:)`) | 17.0 API; glass in 26 | 14.0 API; glass in 26 | 27 SDK: `TabView` in an inspector looks like it does in a sidebar and uses the `.tabs` picker style [RN-macOS27] | Behavior-only |
| Sheet glass (partial-detent sheets inset with glass) | 26.0 behavior | n/a | 27 adds `NavigationTransition.crossFade` (iOS 27, not macOS) for a sheet that fades in [UPD-SUI] [D-avail]. Guidance from 26: remove custom `presentationBackground` to keep the glass [BSA25] | Glass ships now; `crossFade` needs iOS 27 |
| Search: `searchable` placement in toolbar (bottom on iPhone, top trailing on iPad/Mac) | 26.0 behavior | 26.0 behavior | 27 guidance only: bottom toolbar is preferred on iOS; search can be a standard or prominent tab [SRCH26] | Ships now (26) |
| `searchToolbarBehavior(_:)` (`.minimized`) | 26.0 | 26.0 | None | Ships now (26) |
| `Tab(role: .search)` + `tabViewSearchActivation(_:)` | 18.0 / 26.0 | 15.0 / 26.0 | A `.search` tab may get the prominent treatment when no tab is `.prominent` [D-prominent] | Ships now (26) |
| `TabRole.prominent` | **27.0** | 27.0 | New: separate trailing tab-bar position | **Needs iOS 27** |
| `tabBarMinimizeBehavior(_:)` (`.onScrollDown` etc.) | 26.0 | 26.0 (API present) | Minimizing works only for iPhone tab bars [D-TBMB]. Not deprecated in 27 | Ships now (26) |
| `tabViewBottomAccessory(content:)` | 26.0 | not listed (iOS/iPadOS/Catalyst) | None | Ships now (26) |
| `tabViewBottomAccessory(isEnabled:content:)` | **26.1** | not listed | None | **Ships now, gate 26.1** |
| `tabViewBottomAccessoryPlacement` env | 26.0 | 26.0 | None | Ships now (26) |
| `PickerStyle.tabs` / `TabsPickerStyle` | **27.0** | 27.0 | New: segmented-like, VoiceOver reads as "tabs", distinct look on macOS [RN-macOS27] | **Needs iOS 27** |
| `ToolbarPlacement.statusBar` (`toolbarColorScheme`/`toolbarVisibility` for status bar) | **27.0** | n/a | New [RN-iOS27] | **Needs iOS 27** |
| `appearsActive` env | 18.0 | 10.15 | 27: iPad windows dim when inactive, like Mac; use it to dim custom glass/sidebar content [WN-SUI26] | Ships now (26) |
| Liquid Glass slider (user setting, ultra clear ↔ fully tinted) | 27 system setting | 27 system setting | No public API found; glass "automatically responds" [WN-SUI26] [SOTU26] | Behavior-only |
| Menu item icons | 26 behavior | 26 behavior | 27: menu bar (iPadOS, macOS) and macOS context menus hide most symbol images; `.labelStyle(.titleAndIcon)` forces one [RN-iOS27] [RN-macOS27] | Behavior-only (affects existing menus) |
| `UIDesignRequiresCompatibility` Info.plist key | 26.0 | 26.0 | Ignored when building for 27 or later [D-UIDRC] | n/a for this app |

## Accessibility and appearance

Applies to every glass surface above, system or custom, because the adaptations are built into the material.

| Setting | How Liquid Glass responds | Source | Changed in 27? |
|---|---|---|---|
| Reduce Transparency | "makes Liquid Glass frostier and obscures more of the content behind it" | [MLG25] | No change documented; WWDC26 restates glass "seamlessly adapts" to it [SOTU26] |
| Increase Contrast | "makes elements predominantly black or white and highlights them with a contrasting border" | [MLG25] | No change documented. Xcode 27 previews add a Color Scheme Contrast override for testing [RN-Xcode27] |
| Reduce Motion | "decreases the intensity of some effects and disables any elastic properties for the material" | [MLG25] | No change documented. Inference: this also tames `interactive()` bounce and glass morphs, since they are elastic effects |
| Show Borders | `accessibilityShowBorders` environment value | [D-avail] [SOTU26] | macOS 27 now honors Show Borders like iOS ("macOS 27 also supports the 'show borders' environment value"). Docs list the property back to macOS 11, so it compiles earlier but only means something on macOS 27 [SOTU26]. `accessibilityShowButtonShapes` is marked deprecated with a future version (1000.0) on all platforms [D-avail]. Xcode 27 previews add a Control Borders override [RN-Xcode27]. 27 SDK fixes grouped-form section borders under Show Borders [RN-macOS27] |
| Dark mode | Small elements, symbols and glyphs flip light/dark so the material stays discernible; large elements (menus, sidebars) adapt to context but do not flip | [MLG25] | No change documented |
| User "preferred look" / Liquid Glass slider | `regular` and `clear` "can differ in response to certain system settings, like if people choose a preferred look for Liquid Glass" | [HIG-Mat] | 27 adds the ultra-clear-to-tinted slider; glass follows it automatically [SOTU26] |
| Window inactive | Mac and (in 27) iPad dim icons/text in inactive windows; use `appearsActive` for custom views | [WN-SUI26] | Yes, iPad gains it in 27 |

All of these apply automatically "whenever you use the new material" [MLG25]: no code is needed for `glassEffect`, glass button styles or system bars. Custom tints and dimming layers under `.clear` glass are the app's responsibility: the HIG suggests a 35% dark dimming layer over bright content [HIG-Mat], and the `clear` docs show `.background(.black.opacity(0.3))` [D-clear].

## macOS vs iOS differences

- iOS-only (not on native macOS): `ToolbarOverflowMenu`, `.topBarPinnedTrailing`, `toolbarMinimizationBehavior` `.onScrollUp`, `tabViewBottomAccessory` (both overloads), `NavigationTransition.crossFade`, `ToolbarPlacement.statusBar`, `ToolbarItemPlacement.largeSubtitle`. Tab bar minimizing works only on iPhone [D-avail] [D-TBMB].
- `visibilityPriority(_:)` reached macOS first (26.1) and iOS at 27.0 [D-avail].
- macOS 27 changes on relaunch, no rebuild: automatic scroll edge effect resolves to hard under title-bar text; sidebars go full-bleed with semibold selection; bordered toolbar items over the sidebar become glass; interactive glass bounces on click [AppKit26].
- macOS 27 SDK fixes: `.glass`/`.glassProminent` hover outside toolbars; Show Borders honored in grouped forms [RN-macOS27].
- Search: bottom toolbar on iPhone; top trailing toolbar on iPad and Mac. A selected search tab on iPad/Mac centers the field above suggestions [BSA25] [SRCH26].
- Bordered buttons default to capsules, but mini/small/medium macOS controls keep rounded rectangles [BSA25].

## Implications for this app

- Everything glass-specific in the current code base and backlog ships now on iOS 26 except: `ToolbarOverflowMenu`, `.topBarPinnedTrailing`, iOS `visibilityPriority`, `toolbarMinimizationBehavior`, `TabRole.prominent`, `.tabs` picker style, `crossFade` sheets, `statusBar` placement. Wrap these in `if #available(iOS 27, *)` (or a small `View` extension) until the iOS target returns to 27.0, then remove the guards.
- `tabViewBottomAccessory(isEnabled:)` needs `#available(iOS 26.1, *)` while the target is 26.0.
- On macOS (target 27.0) all of the above are usable unguarded, except the iOS-only items listed in the previous section.
- Under the project's "stock controls, no custom styling" rule, little custom `glassEffect` is needed. The visual changes in 27 arrive automatically.
- The `swiftui-pro` skill references contain no Liquid Glass guidance beyond attaching `confirmationDialog` to its trigger so the glass animation starts from the right source. This file is the reference instead.

## Sources

- [WN-SUI26] WWDC26 "What's new in SwiftUI" (session 269): https://developer.apple.com/videos/play/wwdc2026/269/
- [SOTU26] WWDC26 "Platforms State of the Union" (session 102): https://developer.apple.com/videos/play/wwdc2026/102/
- [AppKit26] WWDC26 "Modernize your AppKit app" (session 289): https://developer.apple.com/videos/play/wwdc2026/289/
- [SRCH26] WWDC26 "Design intuitive search experiences" (session 292): https://developer.apple.com/videos/play/wwdc2026/292/
- [MLG25] WWDC25 "Meet Liquid Glass" (session 219), Next steps chapter (accessibility) and Principles chapter (dark mode, variants): https://developer.apple.com/videos/play/wwdc2025/219/
- [BSA25] WWDC25 "Build a SwiftUI app with the new design" (session 323): https://developer.apple.com/videos/play/wwdc2025/323/
- [UPD-SUI] SwiftUI updates (June 2025, June 2026, September 2026 sections): https://developer.apple.com/documentation/updates/swiftui
- [RN-iOS27] iOS & iPadOS 27 Release Notes, SwiftUI and UIKit sections: https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes
- [RN-macOS27] macOS 27 Golden Gate Release Notes, SwiftUI and AppKit sections: https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes
- [RN-Xcode27] Xcode 27 Release Notes, Previews section: https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes
- [HIG-Mat] Human Interface Guidelines, Materials → Liquid Glass (change log last updated September 9, 2025; no 27-specific update yet): https://developer.apple.com/design/human-interface-guidelines/materials
- [D-avail] Per-symbol availability from Apple Developer Documentation, for example https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:), .../swiftui/toolbaroverflowmenu, .../swiftui/toolbaritemplacement/topbarpinnedtrailing, .../swiftui/toolbarcontent/visibilitypriority(_:), .../swiftui/view/toolbarminimizationbehavior(_:for:), .../swiftui/tabrole/prominent, .../swiftui/view/tabviewbottomaccessory(isenabled:content:), .../swiftui/environmentvalues/accessibilityshowbuttonshapes
- [D-Glass] `Glass` topic listing: https://developer.apple.com/documentation/swiftui/glass
- [D-clear] `Glass.clear`: https://developer.apple.com/documentation/swiftui/glass/clear
- [D-TMB] `toolbarMinimizationBehavior(_:for:)`: https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)
- [D-TBMB] `TabBarMinimizeBehavior.onScrollDown` ("supported for tab bars on only iPhone"): https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior/onscrolldown
- [D-prominent] `TabRole.prominent`: https://developer.apple.com/documentation/swiftui/tabrole/prominent
- [D-UIDRC] `UIDesignRequiresCompatibility`: https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility
- Applying Liquid Glass to custom views (container, union, transition semantics, unchanged): https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views

## Open questions

- No public API was found for reading the user's 27 Liquid Glass slider position. The sources say only that glass follows it automatically.
- Whether `Glass.interactive()` showed any click feedback on macOS 26 is not stated. WWDC26 calls the click bounce "new in macOS 27".
- WWDC25 session 323 shows `.searchToolbarBehavior(.minimize)`, but the current docs example uses `.minimized`. Go by the docs.
