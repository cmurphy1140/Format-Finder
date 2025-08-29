import SwiftUI

struct StickyHeaderView: View {
    let title: String
    let height: CGFloat
    @Binding var isSticky: Bool
    
    @State private var shadowOpacity: Double = 0
    @State private var blurRadius: Double = 0
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, height: CGFloat = 50, isSticky: Binding<Bool>) {
        self.title = title
        self.height = height
        self._isSticky = isSticky
    }
    
    var body: some View {
        ZStack {
            // Background with blur effect
            if isSticky {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Color(uiColor: .systemBackground)
                            .opacity(0.85)
                    )
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(uiColor: .systemBackground).opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            
            // Content
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .frame(height: height)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: StickyHeaderPreferenceKey.self,
                        value: geometry.frame(in: .global)
                    )
            }
        )
        .shadow(
            color: Color.black.opacity(shadowOpacity),
            radius: blurRadius,
            x: 0,
            y: 2
        )
        .zIndex(isSticky ? 1000 : 0)
        .onChange(of: isSticky) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                shadowOpacity = newValue ? 0.1 : 0
                blurRadius = newValue ? 5 : 0
            }
        }
    }
}

struct StickyHeaderPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Sticky Header Modifier
struct StickyHeaderModifier: ViewModifier {
    let title: String
    @State private var headerFrame: CGRect = .zero
    @State private var isSticky: Bool = false
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if isSticky {
                StickyHeaderView(title: title, isSticky: .constant(true))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ScrollViewReader { proxy in
                content
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    headerFrame = geometry.frame(in: .global)
                                }
                                .onChange(of: geometry.frame(in: .global)) { oldFrame, newFrame in
                                    updateStickyState(frame: newFrame)
                                }
                        }
                    )
            }
        }
    }
    
    private func updateStickyState(frame: CGRect) {
        let threshold: CGFloat = 100 // Distance from top to trigger sticky
        let shouldStick = frame.minY < threshold
        
        if shouldStick != isSticky {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSticky = shouldStick
            }
        }
    }
}

extension View {
    func stickyHeader(_ title: String) -> some View {
        modifier(StickyHeaderModifier(title: title))
    }
}