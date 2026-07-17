import AppKit
import CoreImage
import SwiftUI

struct LaunchpadView: View {
    @EnvironmentObject private var library: AppLibrary
    @EnvironmentObject private var settings: LaunchpadSettings
    let extendsIntoSafeArea: Bool
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var page = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showsSettings = false
    @State private var applicationFrames: [String: CGRect] = [:]
    @State private var draggedApplicationID: String?
    @State private var draggedApplicationLocation: CGPoint?
    @State private var dragSourcePage: Int?
    @State private var dropTargetApplicationID: String?
    @State private var pendingEdgePageDirection: Int?
    @State private var edgePageGeneration = 0
    @FocusState private var searchIsFocused: Bool

    init(extendsIntoSafeArea: Bool = true, onDismiss: @escaping () -> Void) {
        self.extendsIntoSafeArea = extendsIntoSafeArea
        self.onDismiss = onDismiss
    }

    private var filteredApplications: [InstalledApplication] {
        library.applications.filter { $0.matches(query) }
    }

    var body: some View {
        Group {
            if extendsIntoSafeArea {
                launchpadContent.ignoresSafeArea()
            } else {
                launchpadContent
            }
        }
        .frame(minWidth: 760, minHeight: 520)
        .sheet(isPresented: $showsSettings) {
            LaunchpadSettingsView()
                .environmentObject(settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showLaunchpadSettings)) { _ in
            showsSettings = true
        }
    }

    private var launchpadContent: some View {
        GeometryReader { geometry in
            let metrics = GridMetrics(size: geometry.size)
            let pages = displayedApplicationPages(pageSize: metrics.pageSize)
            let pageCount = max(1, pages.count)
            let currentPage = min(page, pageCount - 1)

            ZStack {
                DesktopBackdrop()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDismiss)

                VStack(spacing: 0) {
                    topBar
                        .padding(.top, metrics.topPadding)

                    if library.isLoading && library.applications.isEmpty {
                        loadingView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredApplications.isEmpty {
                        emptyView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        appPageStrip(
                            page: currentPage,
                            pageCount: pageCount,
                            pages: pages,
                            metrics: metrics,
                            screenWidth: geometry.size.width
                        )
                    }

                    PageIndicator(page: currentPage, pageCount: pageCount) { selectedPage in
                        withAnimation(.easeInOut(duration: 0.30)) {
                            page = selectedPage
                            dragOffset = 0
                        }
                    }
                    .frame(height: 42)
                    .padding(.bottom, 14)
                }
                .frame(width: max(0, geometry.size.width - metrics.horizontalPadding * 2))
                .frame(maxHeight: .infinity)

                if let draggedApplicationID,
                   let draggedApplicationLocation,
                   let application = library.applications.first(where: { $0.id == draggedApplicationID }) {
                    ApplicationTile(application: application, action: {})
                        .frame(
                            width: applicationFrames[draggedApplicationID]?.width ?? 122,
                            height: metrics.tileHeight
                        )
                        .scaleEffect(1.08)
                        .opacity(0.94)
                        .shadow(color: .black.opacity(0.32), radius: 14, y: 7)
                        .position(draggedApplicationLocation)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .zIndex(10)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .contentShape(Rectangle())
            .coordinateSpace(name: "launchpad")
            .gesture(pageDragGesture(pageCount: pageCount))
            .onPreferenceChange(ApplicationFramePreferenceKey.self) { frames in
                applicationFrames = frames
            }
            .onChange(of: query) { page = 0 }
            .onChange(of: filteredApplications.count) {
                page = min(page, pageCount - 1)
            }
            .onMoveCommand { direction in
                switch direction {
                case .left: movePage(by: -1, pageCount: pageCount)
                case .right: movePage(by: 1, pageCount: pageCount)
                default: break
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .launchpadPageSwipe)) { notification in
                guard let swipe = notification.object as? HorizontalPageSwipe else { return }
                movePage(by: swipe.rawValue, pageCount: pageCount)
            }
            .onExitCommand(perform: onDismiss)
            .onAppear { page = currentPage }
        }
    }

    private var topBar: some View {
        ZStack {
            SearchField(text: $query, isFocused: $searchIsFocused)
                .frame(width: 270)

            settingsButton
                .offset(x: 160)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
    }

    private var settingsButton: some View {
        Button {
            showsSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(.black.opacity(0.24), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.9))
        .help("设置（⌘,）")
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("正在查找应用…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30, weight: .light))
            Text("没有找到应用")
                .font(.system(size: 17, weight: .medium))
            Text("试试其他名称")
                .font(.system(size: 13))
                .opacity(0.72)
        }
        .foregroundStyle(.white.opacity(0.9))
    }

    private func appGrid(
        _ applications: [InstalledApplication],
        metrics: GridMetrics,
        pageCount: Int,
        screenWidth: CGFloat
    ) -> some View {
        LazyVGrid(columns: metrics.columns, alignment: .center, spacing: metrics.rowSpacing) {
            ForEach(applications) { application in
                ApplicationTile(application: application) {
                    library.open(application)
                }
                .frame(height: metrics.tileHeight)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.75), lineWidth: 2)
                        .opacity(dropTargetApplicationID == application.id ? 1 : 0)
                        .padding(3)
                        .allowsHitTesting(false)
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ApplicationFramePreferenceKey.self,
                            value: [application.id: proxy.frame(in: .named("launchpad"))]
                        )
                    }
                }
                .opacity(draggedApplicationID == application.id ? 0.18 : 1)
                .highPriorityGesture(
                    applicationReorderGesture(
                        for: application.id,
                        pageCount: pageCount,
                        pageSize: metrics.pageSize,
                        screenWidth: screenWidth
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func appPageStrip(
        page: Int,
        pageCount: Int,
        pages: [[InstalledApplication]],
        metrics: GridMetrics,
        screenWidth: CGFloat
    ) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(0..<pageCount, id: \.self) { pageIndex in
                    Group {
                        if abs(pageIndex - page) <= 1 {
                            appGrid(
                                pageIndex < pages.count ? pages[pageIndex] : [],
                                metrics: metrics,
                                pageCount: pageCount,
                                screenWidth: screenWidth
                            )
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(
                        x: CGFloat(pageIndex - page) * geometry.size.width + dragOffset
                    )
                }
            }
            .animation(.easeInOut(duration: 0.30), value: page)
        }
        .clipped()
    }

    private func displayedApplicationPages(pageSize: Int) -> [[InstalledApplication]] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return library.applicationPages(pageSize: pageSize)
        }

        return stride(from: 0, to: filteredApplications.count, by: pageSize).map { start in
            Array(filteredApplications[start..<min(start + pageSize, filteredApplications.count)])
        }
    }

    private func applicationReorderGesture(
        for applicationID: String,
        pageCount: Int,
        pageSize: Int,
        screenWidth: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("launchpad"))
            .onChanged { value in
                guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                if draggedApplicationID == nil {
                    draggedApplicationID = applicationID
                    draggedApplicationLocation = value.startLocation
                    dragSourcePage = page
                }
                guard draggedApplicationID == applicationID else { return }

                draggedApplicationLocation = value.location
                dropTargetApplicationID = closestApplication(
                    to: value.location,
                    excluding: applicationID
                )
                updateEdgePaging(
                    at: value.location,
                    screenWidth: screenWidth,
                    pageCount: pageCount,
                    pageSize: pageSize
                )
            }
            .onEnded { value in
                guard draggedApplicationID == applicationID else { return }
                cancelEdgePaging()
                let targetID = closestApplication(to: value.location, excluding: applicationID)
                    ?? crossPageFallbackTarget(pageSize: pageSize)

                withAnimation(.easeInOut(duration: 0.18)) {
                    if let targetID {
                        library.moveApplication(
                            id: applicationID,
                            to: targetID,
                            destinationPage: page,
                            pageSize: pageSize
                        )
                    }
                    draggedApplicationID = nil
                    draggedApplicationLocation = nil
                    dragSourcePage = nil
                    dropTargetApplicationID = nil
                }
            }
    }

    private func updateEdgePaging(
        at location: CGPoint,
        screenWidth: CGFloat,
        pageCount: Int,
        pageSize: Int
    ) {
        let edgeWidth = max(82, screenWidth * 0.07)
        let direction: Int?
        if location.x <= edgeWidth, page > 0 {
            direction = -1
        } else if location.x >= screenWidth - edgeWidth, page < pageCount - 1 {
            direction = 1
        } else {
            direction = nil
        }

        guard direction != pendingEdgePageDirection else { return }
        edgePageGeneration += 1
        let generation = edgePageGeneration
        pendingEdgePageDirection = direction
        guard let direction else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(520))
            guard edgePageGeneration == generation,
                  pendingEdgePageDirection == direction,
                  let draggedApplicationID else { return }

            let destinationPage = page + direction
            let pages = displayedApplicationPages(pageSize: pageSize)
            let destinationApplications = destinationPage < pages.count ? pages[destinationPage] : []
            let destinationTarget = direction > 0
                ? destinationApplications.last
                : destinationApplications.first
            if let destinationTarget {
                library.moveApplication(
                    id: draggedApplicationID,
                    to: destinationTarget.id,
                    destinationPage: destinationPage,
                    pageSize: pageSize
                )
            }
            movePage(by: direction, pageCount: pageCount)
            dropTargetApplicationID = nil
            pendingEdgePageDirection = nil
        }
    }

    private func cancelEdgePaging() {
        edgePageGeneration += 1
        pendingEdgePageDirection = nil
    }

    private func crossPageFallbackTarget(pageSize: Int) -> String? {
        guard let dragSourcePage, dragSourcePage != page else { return nil }
        let pages = displayedApplicationPages(pageSize: pageSize)
        guard page < pages.count else { return nil }
        return pages[page].last?.id
    }

    private func closestApplication(to location: CGPoint, excluding applicationID: String) -> String? {
        applicationFrames
            .filter { $0.key != applicationID && $0.value.intersects(CGRect(origin: location, size: .zero).insetBy(dx: -18, dy: -18)) }
            .min { lhs, rhs in
                lhs.value.center.distanceSquared(to: location) < rhs.value.center.distanceSquared(to: location)
            }?
            .key
    }

    private func pageDragGesture(pageCount: Int) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let isPullingPastFirstPage = page == 0 && value.translation.width > 0
                let isPullingPastLastPage = page == pageCount - 1 && value.translation.width < 0
                let resistance: CGFloat = (isPullingPastFirstPage || isPullingPastLastPage) ? 0.22 : 1
                dragOffset = value.translation.width * resistance
            }
            .onEnded { value in
                let horizontal = value.predictedEndTranslation.width
                if abs(horizontal) > 90 {
                    movePage(by: horizontal < 0 ? 1 : -1, pageCount: pageCount)
                }
                withAnimation(.easeInOut(duration: 0.30)) {
                    dragOffset = 0
                }
            }
    }

    private func movePage(by amount: Int, pageCount: Int) {
        withAnimation(.easeInOut(duration: 0.30)) {
            page = min(max(page + amount, 0), pageCount - 1)
            dragOffset = 0
        }
    }
}

struct GridMetrics {
    let columnCount: Int
    let rowCount: Int
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let tileHeight: CGFloat
    let rowSpacing: CGFloat

    init(size: CGSize) {
        horizontalPadding = max(42, size.width * 0.055)
        topPadding = max(22, size.height * 0.035)

        let columnSpacing: CGFloat = 8
        let preferredTileWidth: CGFloat = 122
        let availableWidth = max(0, size.width - horizontalPadding * 2)
        columnCount = min(
            9,
            max(4, Int((availableWidth + columnSpacing) / (preferredTileWidth + columnSpacing)))
        )

        let minimumTileHeight: CGFloat = 106
        let minimumRowSpacing: CGFloat = 4
        let reservedHeight = topPadding + 46 + 42 + 14
        let availableHeight = max(0, size.height - reservedHeight)
        rowCount = min(
            5,
            max(3, Int((availableHeight + minimumRowSpacing) / (minimumTileHeight + minimumRowSpacing)))
        )

        tileHeight = min(126, max(106, (size.height - 180) / CGFloat(rowCount)))
        rowSpacing = max(4, min(18, (size.height - 190 - tileHeight * CGFloat(rowCount)) / CGFloat(max(1, rowCount - 1))))
    }

    var pageSize: Int { columnCount * rowCount }

    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 92, maximum: 150), spacing: 8), count: columnCount)
    }
}

private struct ApplicationFramePreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

private extension CGPoint {
    func distanceSquared(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return dx * dx + dy * dy
    }
}

private struct ApplicationTile: View {
    let application: InstalledApplication
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: ApplicationIconStore.shared.icon(for: application))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 78, height: 78)
                .scaleEffect(isHovered ? 1.06 : 1)

            Text(application.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 122)
                .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .help(application.name)
        .accessibilityLabel("打开 \(application.name)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("打开"), action)
    }
}

private struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            TextField("搜索", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .focused(isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.62))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 0.7)
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusLaunchpadSearch)) { _ in
            isFocused.wrappedValue = true
        }
    }
}

private struct PageIndicator: View {
    let page: Int
    let pageCount: Int
    let select: (Int) -> Void

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<pageCount, id: \.self) { index in
                Button {
                    select(index)
                } label: {
                    Circle()
                        .fill(.white.opacity(index == page ? 0.92 : 0.38))
                        .frame(width: 7, height: 7)
                        .contentShape(Rectangle().inset(by: -6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("第 \(index + 1) 页")
            }
        }
        .opacity(pageCount > 1 ? 1 : 0)
    }
}

private struct DesktopBackdrop: View {
    private static let desktopImage = DesktopWallpaperRenderer.render()

    var body: some View {
        ZStack {
            if let desktopImage = Self.desktopImage {
                Image(nsImage: desktopImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.14, blue: 0.24), Color(red: 0.22, green: 0.12, blue: 0.27)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Color.black.opacity(0.28)

            LinearGradient(
                colors: [.white.opacity(0.08), .clear, .black.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
        .ignoresSafeArea()
    }
}

private enum DesktopWallpaperRenderer {
    static func render() -> NSImage? {
        guard let screen = NSScreen.main,
              let url = NSWorkspace.shared.desktopImageURL(for: screen),
              let source = CIImage(contentsOf: url) else { return nil }

        // Rendering a small blurred bitmap once is dramatically cheaper than
        // running a full-screen Gaussian blur on every animation frame.
        let targetHeight: CGFloat = 360
        let targetWidth = max(640, targetHeight * screen.frame.width / screen.frame.height)
        let targetRect = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        let scale = max(targetWidth / source.extent.width, targetHeight / source.extent.height)
        let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let cropRect = CGRect(
            x: scaled.extent.midX - targetWidth / 2,
            y: scaled.extent.midY - targetHeight / 2,
            width: targetWidth,
            height: targetHeight
        )
        let cropped = scaled
            .cropped(to: cropRect)
            .transformed(by: CGAffineTransform(translationX: -cropRect.minX, y: -cropRect.minY))
        let blurred = cropped
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 9])
            .cropped(to: targetRect)

        let context = CIContext(options: [.cacheIntermediates: false])
        guard let cgImage = context.createCGImage(blurred, from: targetRect) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: targetWidth, height: targetHeight))
    }
}

extension Notification.Name {
    static let focusLaunchpadSearch = Notification.Name("ClassicLaunchpad.focusSearch")
}
